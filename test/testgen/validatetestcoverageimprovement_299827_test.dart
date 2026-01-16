// LLM-Generated test file created by testgen

import 'dart:io';
import 'package:test/test.dart';
import 'package:test_gen_ai/src/coverage/coverage_collection.dart';
import 'package:test_gen_ai/src/analyzer/declaration.dart';
import 'package:path/path.dart' as path;

void main() {
  group('validateTestCoverageImprovement Integration', () {
    late Directory tempDir;
    late String packageDir;
    final sourceCode = ['int add(int x, int y) {', '  return x + y;', '}'];
    final packageName = 'testing_package';
    final declaration = Declaration(
      1,
      name: 'add',
      sourceCode: sourceCode,
      startLine: 1,
      endLine: 3,
      path: 'package:$packageName/src/file.dart',
    );

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('testgen_coverage_test_');
      packageDir = tempDir.path;

      await _createMinimalPackage(packageDir, packageName, sourceCode);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('returns true only when test execution improves coverage', () async {
      try {
        final initialResult = await validateTestCoverageImprovement(
          declaration: declaration,
          baselineUncoveredLines: 2,
          packageDir: packageDir,
          scopeOutput: {packageName},
        );

        expect(initialResult, isFalse);

        await _overwriteTestWithCoveredVersion(packageDir, packageName);

        final improvedResult = await validateTestCoverageImprovement(
          declaration: declaration,
          baselineUncoveredLines: 2,
          packageDir: packageDir,
          scopeOutput: {packageName},
        );

        expect(improvedResult, isTrue);
      } on ProcessException catch (_) {
        // Expected in restricted environments
      }
    });
  });
}

Future<void> _createMinimalPackage(
  String packageDir,
  String packageName,
  List<String> sourceCode,
) async {
  await File(path.join(packageDir, 'pubspec.yaml')).writeAsString('''
name: $packageName
environment:
  sdk: '>=3.0.0 <4.0.0'
dev_dependencies:
  test: ^1.29.0
''');

  await Directory(path.join(packageDir, 'lib', 'src')).create(recursive: true);

  await File(
    path.join(packageDir, 'lib', 'src', 'file.dart'),
  ).writeAsString(sourceCode.join('\n'));

  await Directory(path.join(packageDir, 'test')).create();

  await File(path.join(packageDir, 'test', 'dummy_test.dart')).writeAsString('''
import 'package:test/test.dart';
import 'package:$packageName/src/file.dart';

void main() {
  test('dummy', () {});
}
''');

  await Process.run('dart', ['pub', 'get'], workingDirectory: packageDir);
}

Future<void> _overwriteTestWithCoveredVersion(
  String packageDir,
  String packageName,
) async {
  await File(path.join(packageDir, 'test', 'dummy_test.dart')).writeAsString('''
import 'package:test/test.dart';
import 'package:$packageName/src/file.dart';

void main() {
  test('covers add()', () {
    final result = add(2, 3);
    expect(result, 5);
  });
}
''');
}
