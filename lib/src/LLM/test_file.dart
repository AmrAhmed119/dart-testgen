import 'dart:io';

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

  TestFile(this.packagePath, String fileName)
    : testFilePath = path.join(packagePath, 'test', 'testgen', fileName);

  Future<void> writeTest(String content) async {
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
    final testFile = File(testFilePath);
    if (await testFile.exists()) {
      await testFile.delete();
    }
  }

  Future<String?> runAnalyzer() async {
    final content = await File(testFilePath).readAsString();
    final result = parseString(content: content);

    final errors =
        result.errors
            .where((error) => error.severity == Severity.error)
            .map((error) => '${error.errorCode}: ${error.message}')
            .toList();

    return errors.isEmpty ? null : errors.join('\n');
  }

  Future<String?> runTest() async {
    final result = await Process.run('dart', [
      'test',
      testFilePath,
    ], workingDirectory: packagePath);

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
