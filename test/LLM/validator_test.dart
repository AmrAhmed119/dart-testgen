import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:testgen/src/LLM/prompt_generator.dart';
import 'package:testgen/src/LLM/test_file.dart';
import 'package:testgen/src/LLM/validator.dart';

@GenerateNiceMocks([MockSpec<TestFile>()])
import 'validator_test.mocks.dart';

void main() {
  const promptGenerator = PromptGenerator();

  group('AnalysisValidator', () {
    final validator = AnalysisValidator();
    late MockTestFile mockTestFile;

    setUpAll(() {
      mockTestFile = MockTestFile();
    });

    test('should pass when there are no analysis errors', () async {
      when(mockTestFile.runAnalyzer()).thenAnswer((_) async => null);

      final result = await validator.validate(mockTestFile, promptGenerator);

      expect(result.isPassed, isTrue);
      expect(result.recoveryPrompt, isNull);

      verify(mockTestFile.runAnalyzer()).called(1);
    });

    test('should fail when there are analysis errors', () async {
      when(
        mockTestFile.runAnalyzer(),
      ).thenAnswer((_) async => 'Error: Undefined name "foo"');

      final result = await validator.validate(mockTestFile, promptGenerator);

      expect(result.isPassed, isFalse);
      expect(
        result.recoveryPrompt,
        equals('''
The generated Dart code contains the following analyzer error(s):

Error: Undefined name "foo"

Fix these issues and return only the corrected, complete test code that will pass dart analyze.
'''),
      );

      verify(mockTestFile.runAnalyzer()).called(1);
    });
  });

  group('TestExecutionValidator', () {
    final validator = TestExecutionValidator();
    late MockTestFile mockTestFile;

    setUpAll(() {
      mockTestFile = MockTestFile();
    });

    test('should pass when tests execute successfully', () async {
      when(mockTestFile.runTest()).thenAnswer((_) async => null);

      final result = await validator.validate(mockTestFile, promptGenerator);

      expect(result.isPassed, isTrue);
      expect(result.recoveryPrompt, isNull);

      verify(mockTestFile.runTest()).called(1);
    });

    test('should fail when tests have execution errors', () async {
      when(
        mockTestFile.runTest(),
      ).thenAnswer((_) async => 'Test failed: Expected true but got false');

      final result = await validator.validate(mockTestFile, promptGenerator);

      expect(result.isPassed, isFalse);
      expect(
        result.recoveryPrompt,
        equals('''
The generated test failed with the following error(s):

Test failed: Expected true but got false

Fix the test code and return only the corrected, complete test code that will pass all tests.
'''),
      );

      verify(mockTestFile.runTest()).called(1);
    });
  });

  group('FormatValidator', () {
    final validator = FormatValidator();
    late MockTestFile mockTestFile;

    setUpAll(() {
      mockTestFile = MockTestFile();
    });

    test('should pass when formatting is successful', () async {
      when(mockTestFile.runFormat()).thenAnswer((_) async => null);

      final result = await validator.validate(mockTestFile, promptGenerator);

      expect(result.isPassed, isTrue);
      expect(result.recoveryPrompt, isNull);

      verify(mockTestFile.runFormat()).called(1);
    });

    test('should fail when formatting has errors', () async {
      when(
        mockTestFile.runFormat(),
      ).thenAnswer((_) async => 'Format error: Could not format file');

      final result = await validator.validate(mockTestFile, promptGenerator);

      expect(result.isPassed, isFalse);
      expect(
        result.recoveryPrompt,
        equals('''
The generated Dart code has formatting issues:

Format error: Could not format file

Fix these issues and return only the correctly formatted, complete test code.
'''),
      );

      verify(mockTestFile.runFormat()).called(1);
    });
  });

  group('validators list', () {
    test('should contain all standard validators in correct order', () {
      expect(defaultValidators.length, equals(3));

      expect(defaultValidators[0], isA<AnalysisValidator>());
      expect(defaultValidators[1], isA<TestExecutionValidator>());
      expect(defaultValidators[2], isA<FormatValidator>());
    });

    test('should be unmodifiable', () {
      expect(
        () => defaultValidators.add(AnalysisValidator()),
        throwsUnsupportedError,
      );
    });
  });
}
