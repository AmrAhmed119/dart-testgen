import 'dart:io';

import 'package:path/path.dart' as path;

/// Writes [content] to a file at the given [filePath] which is an absolute path.
/// Creates the file and necessary directories if they don't exist.
void writeToFile(String filePath, String content) {
  try {
    final file = File(filePath);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
  } catch (e) {
    throw Exception("Error writing to file: $e");
  }
}

/// Reads and returns the content of a file at the given [filePath].
String readFromFile(String filePath) {
  try {
    return File(filePath).readAsStringSync();
  } catch (e) {
    throw Exception("Error reading from file: $e");
  }
}

/// Lists all Dart files paths in the `lib` folder given the project root directory.
List<String> exploreDartFiles(String rootPath) {
  try {
    final libDirectory = Directory('$rootPath/lib');
    if (!libDirectory.existsSync()) {
      throw Exception("lib directory does not exist in: $rootPath");
    }
    return libDirectory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.path)
        .toList();
  } catch (e) {
    throw Exception("Error exploring Dart files: $e");
  }
}

/// Deletes a file at the given [filePath].
void deleteFile(String filePath) {
  try {
    final file = File(filePath);
    if (file.existsSync()) {
      file.deleteSync();
    } else {
      throw Exception("File does not exist: $filePath");
    }
  } catch (e) {
    throw Exception("Error deleting file: $e");
  }
}

/// Gets the absolute path of the root directory of the project from  [filePath].
String getRootDirectoryAbsolutePath(String filePath) {
  final parts = path.split(filePath);
  final index = parts.indexWhere((part) => part == 'lib' || part == 'test');
  return path.joinAll(parts.sublist(0, index));
}

/// Gets the relative path of the root directory of the project from  [filePath].
String getRootDirectoryRelativePath(String filePath) {
  final parts = path.split(filePath);
  final index = parts.indexWhere((part) => part == 'lib');
  return path.joinAll(parts.sublist(index - 1, parts.length));
}

/// Extracts the filename without extension from the given [filePath].
String getFileName(String filePath) {
  return path.basenameWithoutExtension(filePath);
}

/// Generates the absolute path of the test file corresponding to [filePath].
String generateTestFilePath(String filePath) {
  final rootDirectory = getRootDirectoryAbsolutePath(filePath);
  final fileName = getFileName(filePath);
  return path.join(rootDirectory, 'test', '${fileName}_test.dart');
}

/// Generates the absolute path of the hint test file based on [filePath].
String getHintFilePath(String filePath) {
  final rootDirectory = getRootDirectoryAbsolutePath(filePath);
  return path.join(rootDirectory, 'test', 'hint_test.txt');
}
