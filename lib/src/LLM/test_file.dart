import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:path/path.dart' as path;

/// Manages the lifecycle of generated test files handling all operations
/// related to test files including writing, validation, execution, formatting,
/// and cleanup.
///
/// The test files are created in the `test/testgen/` directory within the
/// package path provided.
class TestFile {
  final String testFilePath;
  final String packagePath;
  int analyzerErrors = 0;
  int testErrors = 0;

  TestFile(this.packagePath, String fileName)
    : testFilePath = path.join(
        packagePath,
        'test',
        'testgen',
        fileName.toLowerCase(),
      );

  Future<void> writeTest(String content) async {
    print('[TestFile] Writing test file to $testFilePath');
    final testFile = File(testFilePath);
    final directory = testFile.parent;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    await testFile.writeAsString(
      '// LLM-Generated test file created by testgen\n\n'
      '$content\n',
    );
  }

  Future<void> deleteTest() async {
    print('[TestFile] Deleting test file at $testFilePath');
    final testFile = File(testFilePath);
    if (await testFile.exists()) {
      await testFile.delete();
    }
  }

  /// Runs a lightweight syntax check on the generated test file.
  ///
  /// This method **only performs syntactic validation** by parsing the file
  /// using the Dart analyzer parser. It does **not** perform semantic analysis.
  ///
  /// Its purpose is to quickly reject invalid Dart syntax before executing
  /// `dart test`, which will catch semantic and runtime errors.
  Future<String?> runAnalyzer() async {
    final result = parseFile(
      path: testFilePath,
      featureSet: FeatureSet.latestLanguageVersion(),
      throwIfDiagnostics: false,
    );

    final errors = result.errors
        .where((error) => error.severity == Severity.error)
        .map((error) => '${error.diagnosticCode}: ${error.message}')
        .toList();

    analyzerErrors += errors.isNotEmpty ? 1 : 0;

    return errors.isEmpty ? null : errors.join('\n');
  }

  Future<String?> runTest() async {
    final result = await Process.run('dart', [
      'test',
      testFilePath,
    ], workingDirectory: packagePath);

    testErrors += result.exitCode != 0 ? 1 : 0;

    return result.exitCode != 0 ? result.stdout.toString() : null;
  }

  Future<String?> runFormat() async {
    final result = await Process.run('dart', [
      'format',
      testFilePath,
    ], workingDirectory: packagePath);

    return result.exitCode != 0 ? result.stdout.toString() : null;
  }
}
