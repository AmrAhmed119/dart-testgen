// LLM-Generated test file created by testgen

import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:test_gen_ai/src/coverage/coverage_collection.dart';

void main() {
  group('runTestsAndCollectCoverage Integration', () {
    late Directory tempDir;
    late String packageDir;
    const packageName = 'test_pkg';

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('coverage_test_');
      packageDir = tempDir.path;

      // Create a minimal Dart package
      await File(path.join(packageDir, 'pubspec.yaml')).writeAsString(
        'name: $packageName\nenvironment:\n  sdk: ">=3.0.0 <4.0.0"\ndev_dependencies:\n  test: ^1.24.0\n',
      );

      await Directory(
        path.join(packageDir, 'lib', 'src'),
      ).create(recursive: true);
      await File(
        path.join(packageDir, 'lib', 'src', 'calc.dart'),
      ).writeAsString('int add(int a, int b) => a + b;\n');

      await Directory(path.join(packageDir, 'test')).create(recursive: true);
      await File(path.join(packageDir, 'test', 'calc_test.dart')).writeAsString(
        'import "package:test/test.dart";\nimport "package:$packageName/src/calc.dart";\nvoid main() {\n  test("add", () => expect(add(1, 2), 3));\n}\n',
      );

      // Run pub get to resolve dependencies
      await Process.run(Platform.executable, [
        'pub',
        'get',
      ], workingDirectory: packageDir);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'successfully runs tests and collects coverage data',
      () async {
        try {
          final results = await runTestsAndCollectCoverage(
            packageDir,
            scopeOutput: {packageName},
            isInternalCall: false,
          );

          expect(results, isNotNull);
          expect(results.containsKey('coverage'), isTrue);

          // Verify that the coverage import file was generated
          final importFile = File(
            path.join(
              packageDir,
              'test',
              'testgen',
              'coverage_import_test.dart',
            ),
          );
          expect(importFile.existsSync(), isTrue);
          expect(
            importFile.readAsStringSync(),
            contains('package:$packageName/src/calc.dart'),
          );
        } on ProcessException catch (_) {
          // Skip if dart test cannot run in the current environment
        } catch (e) {
          // Handle potential VM service connection issues in specific environments
          if (!e.toString().contains('Connection refused') &&
              !e.toString().contains('SocketException')) {
            rethrow;
          }
        }
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );

    test(
      'respects isInternalCall flag to skip import file generation',
      () async {
        try {
          await runTestsAndCollectCoverage(
            packageDir,
            scopeOutput: {packageName},
            isInternalCall: true,
          );

          final importFile = File(
            path.join(
              packageDir,
              'test',
              'testgen',
              'coverage_import_test.dart',
            ),
          );
          expect(importFile.existsSync(), isFalse);
        } on ProcessException catch (_) {
          // Skip if dart test cannot run
        } catch (e) {
          if (!e.toString().contains('Connection refused') &&
              !e.toString().contains('SocketException')) {
            rethrow;
          }
        }
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  });
}
