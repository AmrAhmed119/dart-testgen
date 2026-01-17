import 'dart:io';

import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:test_gen_ai/src/LLM/test_file.dart';

void main() {
  final testPackagePath = path.absolute('test', 'fixtures', 'test_package');

  tearDown(() async {
    // Clean up generated test files in `fixtures test` directory
    final fixturesTestDirectory = Directory(path.join(testPackagePath, 'test'));

    if (fixturesTestDirectory.existsSync()) {
      fixturesTestDirectory.deleteSync(recursive: true);
    }
  });

  group('TestFile object creation', () {
    test('creates correct file path', () {
      final testFile = TestFile(testPackagePath, 'my_test.dart');

      expect(testFile.packagePath, equals(testPackagePath));
      expect(
        testFile.testFilePath,
        equals(path.join(testPackagePath, 'test', 'testgen', 'my_test.dart')),
      );
      expect(testFile.analyzerErrors, equals(0));
      expect(testFile.testErrors, equals(0));
    });

    test('converts filename to lowercase', () {
      final testFile = TestFile(testPackagePath, 'MyTest.DART');

      expect(testFile.testFilePath, contains('mytest.dart'));
    });
  });

  group('writeTest', () {
    test('creates file with content and header comment', () async {
      final testFile = TestFile(testPackagePath, 'sample_test.dart');
      const content = 'void main() { test("sample", () {}); }';

      await testFile.writeTest(content);

      final file = File(testFile.testFilePath);
      final fileContent = file.readAsStringSync();

      expect(file.existsSync(), isTrue);
      expect(
        fileContent,
        contains('// LLM-Generated test file created by testgen'),
      );
      expect(fileContent, contains(content));
    });
  });

  group('deleteTest', () {
    test('deletes existing test file', () async {
      final testFile = TestFile(testPackagePath, 'delete_test.dart');

      await testFile.writeTest('content');
      expect(File(testFile.testFilePath).existsSync(), isTrue);

      await testFile.deleteTest();
      expect(File(testFile.testFilePath).existsSync(), isFalse);
    });

    test('does not throw when file does not exist', () async {
      final testFile = TestFile(testPackagePath, 'nonexistent_test.dart');

      expect(() => testFile.deleteTest(), returnsNormally);
    });
  });

  group('runAnalyzer', () {
    test('returns null for valid code', () async {
      final testFile = TestFile(testPackagePath, 'valid_test.dart');
      await testFile.writeTest('void main() { int x = 1; }');
      final result = await testFile.runAnalyzer();

      expect(result, isNull);
      expect(testFile.analyzerErrors, equals(0));
    });

    test(
      'returns errors for invalid code and increments analyzer errors count',
      () async {
        final testFile = TestFile(testPackagePath, 'invalid_test.dart');
        await testFile.writeTest('void main() { final x }');

        final result = await testFile.runAnalyzer();

        expect(result, isNotNull);
        expect(
          result,
          equals("ParserErrorCode.EXPECTED_TOKEN: Expected to find ';'."),
        );
        expect(testFile.analyzerErrors, equals(1));

        await testFile.runAnalyzer();
        expect(testFile.analyzerErrors, equals(2));
      },
    );
  });

  group('runTest', () {
    test('returns null when tests pass', () async {
      final testFile = TestFile(testPackagePath, 'passing_test.dart');
      await testFile.writeTest('''
    import 'package:test/test.dart';

    void main() {
      test('passing test', () {
        expect(true, isTrue);
      });
    }
    ''');
      final result = await testFile.runTest();

      expect(result, isNull);
      expect(testFile.testErrors, equals(0));
    });

    test(
      'returns error output when tests fail and increments test errors count',
      () async {
        final testFile = TestFile(testPackagePath, 'failing_test.dart');
        await testFile.writeTest('''
    import 'package:test/test.dart';

    void main() {
      test('failing test', () {
        expect(true, isFalse);
      });
    }
    ''');
        final result = await testFile.runTest();

        expect(result, isNotNull);
        expect(result, contains('Expected: false'));
        expect(result, contains('Actual: <true>'));
        expect(
          result,
          contains(
            RegExp(r'test[/\\]testgen[/\\]failing_test\.dart 7:9\s+main\.<fn>'),
          ),
        );
        expect(testFile.testErrors, equals(1));

        await testFile.runTest();
        expect(testFile.testErrors, equals(2));
      },
    );
  });

  group('semantic errors', () {
    test('semantic errors are catched by runTest not by runAnalyzer', () async {
      final testFile = TestFile(testPackagePath, 'passing_test.dart');
      await testFile.writeTest('''
    void main() {
      int x = "This is a string"; // Type error
    }
    ''');
      final analyzerResult = await testFile.runAnalyzer();

      expect(analyzerResult, isNull);
      expect(testFile.analyzerErrors, equals(0));

      final testResult = await testFile.runTest();
      expect(testResult, isNotNull);
      expect(
        testResult,
        contains(
          RegExp(
            r"test[/\\]testgen[/\\]passing_test\.dart:4:15: Error: A value of type"
            r" 'String' can't be assigned to a variable of type 'int'\.",
          ),
        ),
      );
      expect(testFile.testErrors, equals(1));
    });
  });

  group('runFormat', () {
    test('formats file and returns null on success', () async {
      final testFile = TestFile(testPackagePath, 'unformatted_test.dart');
      await testFile.writeTest('void main(){print("hello");}');

      final result = await testFile.runFormat();

      expect(result, isNull);

      final file = File(testFile.testFilePath);
      final fileContent = file.readAsStringSync();
      expect(
        fileContent,
        equals('''
// LLM-Generated test file created by testgen

void main() {
  print("hello");
}
'''),
      );
    });
  });
}
