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

class TestGenBenchmark extends AsyncBenchmarkBase {
  final String packagePath;
  final GenerativeModel model;
  final int contextDepth;
  final bool effectiveTestsOnly;
  final Map<String, List<Declaration>> declarationsByFile;
  final List<(Declaration declaration, List<int> lines)> declarationsToProcess;

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
}
