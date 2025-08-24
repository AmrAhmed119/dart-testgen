import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:testgen/src/LLM/context_generator.dart';
import 'package:testgen/src/LLM/llm.dart';
import 'package:testgen/src/LLM/test_file.dart';
import 'package:testgen/src/analyzer/declaration.dart';
import 'package:testgen/src/analyzer/extractor.dart';
import 'package:testgen/src/coverage/coverage_collection.dart';
import 'package:path/path.dart' as path;

final benchmarkResults = BenchmarkResultsCollector();

class BenchmarkResult {
  final String testName;
  final double executionTime;
  final int successfulTests;
  final int failedTests;
  final int skippedTests;
  final double averageTokenCount;
  final int minTokenCount;
  final int maxTokenCount;
  final int p90TokenCount;

  BenchmarkResult({
    required this.testName,
    required this.executionTime,
    required this.successfulTests,
    required this.failedTests,
    required this.skippedTests,
    required this.averageTokenCount,
    required this.minTokenCount,
    required this.maxTokenCount,
    required this.p90TokenCount,
  });

  int get totalTests => successfulTests + failedTests + skippedTests;
  double get successRate => totalTests > 0 ? successfulTests / totalTests : 0.0;

  Map<String, dynamic> toJson() => {
    'testName': testName,
    'totalDeclarationsInTest': totalTests,
    'executionTimeInSecs': executionTime / 1_000_000, // Convert to seconds
    'successRate': successRate,
    'successfulTests': successfulTests,
    'failedTests': failedTests,
    'skippedTests': skippedTests,
    'averageTokenCount': averageTokenCount,
    'minTokenCount': minTokenCount,
    'maxTokenCount': maxTokenCount,
    'p90TokenCount': p90TokenCount,
  };
}

class BenchmarkResultsCollector {
  final List<BenchmarkResult> _results = [];

  void addResult(BenchmarkResult result) {
    _results.add(result);
  }

  List<BenchmarkResult> get results => List.unmodifiable(_results);

  // Save all results to JSON file
  Future<void> saveToFile(String filename) async {
    final resultsData = {
      'metadata': {
        'generatedAt': DateTime.now().toIso8601String(),
        'totalRuns': _results.length,
      },
      'results': _results.map((r) => r.toJson()).toList(),
    };

    final file = File(
      path.join(Directory.current.path, 'benchmark', 'results', filename),
    );
    await file.parent.create(recursive: true);
    await file.writeAsString(JsonEncoder.withIndent('  ').convert(resultsData));
  }
}

class TestGenBenchmark extends AsyncBenchmarkBase {
  final String packagePath;
  final GenerativeModel model;
  final int contextDepth;
  final Map<String, List<Declaration>> declarationsByFile;
  final List<(Declaration declaration, List<int> lines)> declarationsToProcess;
  final Map<
    int,
    (TestStatus status, ChatSession chat, TestFile testFileManager)
  >
  _results = {};

  TestGenBenchmark(
    super.name, {
    required this.packagePath,
    required this.model,
    required this.contextDepth,
    required this.declarationsByFile,
    required this.declarationsToProcess,
  });

  @override
  Future<void> run() async {
    for (final (declaration, lines) in declarationsToProcess) {
      final toBeTestedCode = formatUntestedCode(declaration, lines);
      final contextMap = generateContextForDeclaration(
        declaration,
        maxDepth: contextDepth,
      );
      final contextCode = formatContext(contextMap);

      _results[declaration.id] = await generateTestFile(
        model,
        toBeTestedCode,
        contextCode,
        packagePath,
        '${declaration.name}_${declaration.id}_test.dart',
      );
    }
  }

  @override
  Future<void> teardown() async {
    final testDir = Directory(path.join(packagePath, 'test', 'testgen'));
    if (!await testDir.exists()) return;

    final testFiles = testDir.listSync().whereType<File>().where(
      (file) => file.path.contains('_test.dart'),
    );
    for (final file in testFiles) {
      await file.delete();
    }
  }

  @override
  Future<void> report() async {
    double time = await measure();
    emitter.emit(name, time);

    int successfulTests = 0;
    int failedTests = 0;
    int skippedTests = 0;
    final List<int> tokenCounts = [];

    for (final entry in _results.entries) {
      final (status, chat, _) = entry.value;

      switch (status) {
        case TestStatus.created:
          successfulTests++;
          break;
        case TestStatus.skipped:
          skippedTests++;
          break;
        default:
          failedTests++;
      }

      tokenCounts.add(await getTokenCount(model, chat));
    }

    tokenCounts.sort();
    final total = tokenCounts.reduce((a, b) => a + b).toDouble();
    final average = total / tokenCounts.length;
    final p90Index = (tokenCounts.length * 0.9).ceil() - 1;
    final p90 = tokenCounts[p90Index.clamp(0, tokenCounts.length - 1)];

    benchmarkResults.addResult(
      BenchmarkResult(
        testName: name,
        executionTime: time,
        successfulTests: successfulTests,
        failedTests: failedTests,
        skippedTests: skippedTests,
        averageTokenCount: average,
        minTokenCount: tokenCounts.first,
        maxTokenCount: tokenCounts.last,
        p90TokenCount: p90,
      ),
    );
  }
}

void main() async {
  final apiKey = Platform.environment['GEMINI_API_KEY'] ?? '';
  final maxDeclarationsToProcess = 10;
  final models = [
    'gemini-2.5-pro',
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
  ];
  final contextDepths = [0, 1, 2, 4, 8, 16];

  // Assume this script is run from the root of the project
  final benchmarkDataDir = Directory(
    path.join(Directory.current.path, 'benchmark', 'data'),
  );
  final availablePackagePaths =
      benchmarkDataDir
          .listSync()
          .whereType<Directory>()
          .map((dir) => dir.absolute.path)
          .toList();

  for (final packagePath in availablePackagePaths) {
    final packageName = path.basename(packagePath);
    final coverage = await runTestsAndCollectCoverage(
      packagePath,
      scopeOutput: {packageName},
    );
    final coverageByFile = await formatCoverage(coverage, packagePath);

    final declarations = await extractDeclarations(packagePath);
    final declarationsByFile = <String, List<Declaration>>{};
    for (final declaration in declarations) {
      declarationsByFile
          .putIfAbsent(declaration.path, () => [])
          .add(declaration);
    }

    final untestedDeclarations = extractUntestedDeclarations(
      declarationsByFile,
      coverageByFile,
    );
    final declarationsToProcess =
        (untestedDeclarations..shuffle(Random()))
            .take(maxDeclarationsToProcess)
            .toList();

    await Process.run('dart', [
      'pub',
      'add',
      'test',
    ], workingDirectory: packagePath);

    for (final model in models) {
      for (final contextDepth in contextDepths) {
        await TestGenBenchmark(
          'pkg:$packageName|model:$model|ctx:$contextDepth',
          packagePath: packagePath,
          model: createModel(model: model, apiKey: apiKey),
          contextDepth: contextDepth,
          declarationsByFile: declarationsByFile,
          declarationsToProcess: declarationsToProcess,
        ).report();

        await Future.delayed(const Duration(seconds: 60));
      }
    }
  }

  await benchmarkResults.saveToFile('results.json');

  exit(0);
}
