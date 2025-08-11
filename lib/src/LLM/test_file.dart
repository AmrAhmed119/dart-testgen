import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:path/path.dart' as path;

class TestFile {
  final String testFilePath;
  final String packagePath;

  TestFile(this.packagePath, String fileName)
    : testFilePath = path.join(packagePath, 'test', 'testgen', fileName);

  Future<void> writeTest(String content, String? comment) async {
    final testFile = File(testFilePath);
    final directory = testFile.parent;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    await testFile.writeAsString(
      '// Auto-Generated Test File\n'
      '$content\n',
    );
  }

  Future<void> deleteTest() async {
    final testFile = File(testFilePath);
    if (await testFile.exists()) {
      testFile.deleteSync();
    }
  }

  Future<String?> runAnalyzer(String code) async {
    final result = parseString(content: code);

    // TODO: Add a command line option to specify the error severity level
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

  Future<void> formatTest() async {
    await Process.run('dart', [
      'format',
      testFilePath,
    ], workingDirectory: packagePath);
  }
}
