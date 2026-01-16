// LLM-Generated test file created by testgen

import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:test_gen_ai/src/analyzer/extractor.dart';

void main() {
  group('extractDeclarations validation', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('extractor_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('throws ArgumentError when package config is not found', () async {
      final p = tempDir.path;
      expect(
        extractDeclarations(p),
        throwsA(
          isA<ArgumentError>().having(
            (ArgumentError e) => e.message,
            'message',
            'Path "$p" is not a dart package root directory',
          ),
        ),
      );
    });

    test('throws ArgumentError when lib directory is missing', () async {
      final p = tempDir.path;
      // Create .dart_tool/package_config.json to satisfy findPackageConfig check
      final dt = Directory(path.join(p, '.dart_tool'));
      dt.createSync(recursive: true);
      File(
        path.join(dt.path, 'package_config.json'),
      ).writeAsStringSync('{"configVersion": 2, "packages": []}');

      expect(
        extractDeclarations(p),
        throwsA(
          isA<ArgumentError>().having(
            (ArgumentError e) => e.message,
            'message',
            'Directory "$p" does not contain a lib folder',
          ),
        ),
      );
    });
  });
}
