// LLM-Generated test file created by testgen

import 'dart:io';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as path;
import 'package:test_gen_ai/src/LLM/test_generator.dart';
import 'package:test_gen_ai/src/LLM/validator.dart';
import 'package:test_gen_ai/src/LLM/model.dart';

class MockModel extends Mock implements GeminiModel {}

void main() {
  group('TestGenerator Constructor', () {
    late MockModel mockModel;
    late String tempPath;

    setUp(() {
      mockModel = MockModel();
      tempPath = Directory.systemTemp.createTempSync('testgen_test').path;
    });

    tearDown(() {
      final dir = Directory(tempPath);
      if (dir.existsSync()) {
        try {
          dir.deleteSync(recursive: true);
        } catch (_) {
          // Ignore cleanup errors in temp directory
        }
      }
    });

    test('initializes with default validators when none are provided', () {
      final generator = TestGenerator(model: mockModel, packagePath: tempPath);
      expect(generator.validators, equals(defaultValidators));
    });

    test(
      'throws ArgumentError when TestExecutionValidator is missing from validators',
      () {
        final invalidValidators = [AnalysisValidator(), FormatValidator()];
        expect(
          () => TestGenerator(
            model: mockModel,
            packagePath: tempPath,
            validators: invalidValidators,
          ),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains(
                'The provided validators list must include an instance of TestExecutionValidator.',
              ),
            ),
          ),
        );
      },
    );

    test('creates log file when verbose is enabled', () {
      final logFilePath = path.join(tempPath, 'testgen_prompts.log');
      final logFile = File(logFilePath);

      expect(logFile.existsSync(), isFalse);

      TestGenerator(model: mockModel, packagePath: tempPath, verbose: true);

      expect(logFile.existsSync(), isTrue);
    });

    test('accepts custom validators if TestExecutionValidator is present', () {
      final customValidators = [TestExecutionValidator()];
      final generator = TestGenerator(
        model: mockModel,
        packagePath: tempPath,
        validators: customValidators,
      );
      expect(generator.validators, equals(customValidators));
    });
  });
}
