import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:testgen/src/LLM/context_generator.dart';
import 'package:testgen/src/LLM/llm.dart';
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

  BenchmarkResult({
    required this.testName,
    required this.executionTime,
    required this.successfulTests,
    required this.failedTests,
    required this.skippedTests,
  });

  int get totalTests => successfulTests + failedTests + skippedTests;
  double get successRate => totalTests > 0 ? successfulTests / totalTests : 0.0;

  Map<String, dynamic> toJson() => {
    'testName': testName,
    'executionTime': executionTime,
    'successfulTests': successfulTests,
    'failedTests': failedTests,
    'skippedTests': skippedTests,
    'totalTests': totalTests,
    'successRate': successRate,
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

  void printSummary() {
    if (_results.isEmpty) {
      print('No benchmark results to summarize.');
      return;
    }

    final totalTime = _results
        .map((r) => r.executionTime)
        .reduce((a, b) => a + b);
    final avgTime = totalTime / _results.length;
    final totalSuccessful = _results
        .map((r) => r.successfulTests)
        .reduce((a, b) => a + b);
    final totalFailed = _results
        .map((r) => r.failedTests)
        .reduce((a, b) => a + b);
    final totalSkipped = _results
        .map((r) => r.skippedTests)
        .reduce((a, b) => a + b);
    final overallSuccessRate =
        (totalSuccessful + totalFailed + totalSkipped) > 0
            ? totalSuccessful / (totalSuccessful + totalFailed + totalSkipped)
            : 0.0;

    print('\n${'=' * 60}');
    print('BENCHMARK SUMMARY');
    print('=' * 60);
    print('Total benchmark runs: ${_results.length}');
    print('Average execution time: ${avgTime.toStringAsFixed(2)}ms');
    print(
      'Total tests generated: ${totalSuccessful + totalFailed}',
    );
    print('Successful tests: $totalSuccessful');
    print('Failed tests: $totalFailed');
    print('Skipped tests: $totalSkipped');
    print(
      'Overall success rate: ${(overallSuccessRate * 100).toStringAsFixed(1)}%',
    );
    print('=' * 60);
  }
}

class TestGenBenchmark extends AsyncBenchmarkBase {
  final String packagePath;
  final GenerativeModel model;
  final int contextDepth;
  final bool effectiveTestsOnly;
  final Map<String, List<Declaration>> declarationsByFile;
  final List<(Declaration declaration, List<int> lines)> declarationsToProcess;

  int failedTests = 0;
  int successfulTests = 0;
  int skippedTests = 0;

  TestGenBenchmark(
    super.name, {
    required this.packagePath,
    required this.model,
    required this.contextDepth,
    required this.effectiveTestsOnly,
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

      final (status, chat, testFileManager) = await generateTestFile(
        model,
        toBeTestedCode,
        contextCode,
        packagePath,
        '${declaration.name}_${declaration.id}_test.dart',
      );

      if (status == TestStatus.created) {
        successfulTests++;
        if (effectiveTestsOnly) {
          final isImproved = await validateTestCoverageImprovement(
            packagePath,
            declaration,
            lines.length,
            scopeOutput: {path.basename(packagePath)},
            declarationsByFile: declarationsByFile,
          );
          if (isImproved) {
            print('✅ Test improved coverage for ${declaration.name}.');
          } else {
            print(
              '❌ Test did not improve coverage for ${declaration.name}. '
              'Deleting test file.',
            );
            testFileManager.deleteTest();
          }
        } else {
          print('✅ Test generated for ${declaration.name}.');
        }
      }
      status == TestStatus.skipped ? skippedTests++ : failedTests++;
    }
  }

  @override
  Future<void> teardown() async {
    final testDir = Directory('$packagePath/test/testgen');
    if (await testDir.exists()) {
      await for (final entity in testDir.list()) {
        if (entity is File && entity.path.contains('_test.dart')) {
          await entity.delete();
        }
      }
    }
  }

  @override
  Future<void> report() async {
    double time = await measure();
    final result = BenchmarkResult(
      testName: name,
      executionTime: time,
      successfulTests: successfulTests,
      failedTests: failedTests,
      skippedTests: skippedTests,
    );
    benchmarkResults.addResult(result);
  }
}

void main() async {
  final apiKey = Platform.environment['GEMINI_API_KEY'] ?? '';
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

  for (final model in models) {
    for (final contextDepth in contextDepths) {
      for (final packagePath in availablePackagePaths) {
        final packageName = path.basename(packagePath);
        final coverage = await runTestsAndCollectCoverage(
          packagePath,
          scopeOutput: {packageName},
        );
        final coverageByFile = formatCoverage(coverage);

        final declarations = await extractDeclarations(
          packagePath,
          packageName,
        );
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
            (untestedDeclarations..shuffle(Random(42))).take(1).toList();

        await Process.run('dart', [
          'pub',
          'add',
          'test',
        ], workingDirectory: packagePath);

        await TestGenBenchmark(
          'TestGen-$packageName - $model - ctx$contextDepth',
          packagePath: packagePath,
          model: createModel(model: model, apiKey: apiKey),
          effectiveTestsOnly: false,
          contextDepth: contextDepth,
          declarationsByFile: declarationsByFile,
          declarationsToProcess: declarationsToProcess,
        ).report();

        await Future.delayed(const Duration(seconds: 60));
      }
    }
  }
  await benchmarkResults.saveToFile('results.json');
  benchmarkResults.printSummary();

  exit(0);
}
