import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:testgen/src/LLM/prompt_generator.dart';
import 'package:testgen/src/LLM/test_file.dart';
import 'package:testgen/src/LLM/validator.dart';

@GenerateMocks([TestFile, PromptGenerator])
import 'validator_test.mocks.dart';

void main() {
  group('AnalysisValidator', () {
    AnalysisValidator validator = AnalysisValidator();
    MockTestFile mockTestFile = MockTestFile();
    MockPromptGenerator mockPromptGen = MockPromptGenerator();

    test('should pass when there are no analysis errors', () async {
      when(mockTestFile.runAnalyzer()).thenAnswer((_) async => null);

      final result = await validator.validate(mockTestFile, mockPromptGen);

      expect(result.isPassed, isTrue);
      expect(result.recoveryPrompt, isNull);

      verify(mockTestFile.runAnalyzer()).called(1);
      verifyNever(mockPromptGen.analysisError(any));
    });

    test('should fail when there are analysis errors', () async {
      const errorMessage = 'Error: Undefined name "foo"';
      const recoveryPrompt = 'Fix the undefined name error';

      when(mockTestFile.runAnalyzer()).thenAnswer((_) async => errorMessage);
      when(
        mockPromptGen.analysisError(errorMessage),
      ).thenReturn(recoveryPrompt);

      final result = await validator.validate(mockTestFile, mockPromptGen);

      expect(result.isPassed, isFalse);
      expect(result.recoveryPrompt, equals(recoveryPrompt));

      verify(mockTestFile.runAnalyzer()).called(1);
      verify(mockPromptGen.analysisError(errorMessage)).called(1);
    });
  });

  group('TestExecutionValidator', () {
    TestExecutionValidator validator = TestExecutionValidator();
    MockTestFile mockTestFile = MockTestFile();
    MockPromptGenerator mockPromptGen = MockPromptGenerator();

    test('should pass when tests execute successfully', () async {
      when(mockTestFile.runTest()).thenAnswer((_) async => null);

      final result = await validator.validate(mockTestFile, mockPromptGen);

      expect(result.isPassed, isTrue);
      expect(result.recoveryPrompt, isNull);

      verify(mockTestFile.runTest()).called(1);
      verifyNever(mockPromptGen.testFailError(any));
    });

    test('should fail when tests have execution errors', () async {
      const errorMessage = 'Test failed: Expected true but got false';
      const recoveryPrompt = 'Fix the failing test assertion';

      when(mockTestFile.runTest()).thenAnswer((_) async => errorMessage);
      when(
        mockPromptGen.testFailError(errorMessage),
      ).thenReturn(recoveryPrompt);

      final result = await validator.validate(mockTestFile, mockPromptGen);

      expect(result.isPassed, isFalse);
      expect(result.recoveryPrompt, equals(recoveryPrompt));

      verify(mockTestFile.runTest()).called(1);
      verify(mockPromptGen.testFailError(errorMessage)).called(1);
    });
  });

  group('FormatValidator', () {
    FormatValidator validator = FormatValidator();
    MockTestFile mockTestFile = MockTestFile();
    MockPromptGenerator mockPromptGen = MockPromptGenerator();

    test('should pass when formatting is successful', () async {
      when(mockTestFile.runFormat()).thenAnswer((_) async => null);

      final result = await validator.validate(mockTestFile, mockPromptGen);

      expect(result.isPassed, isTrue);
      expect(result.recoveryPrompt, isNull);

      verify(mockTestFile.runFormat()).called(1);
      verifyNever(mockPromptGen.formatError(any));
    });

    test('should fail when formatting has errors', () async {
      const errorMessage = 'Format error: Could not format file';
      const recoveryPrompt = 'Fix syntax errors before formatting';

      when(mockTestFile.runFormat()).thenAnswer((_) async => errorMessage);
      when(mockPromptGen.formatError(errorMessage)).thenReturn(recoveryPrompt);

      final result = await validator.validate(mockTestFile, mockPromptGen);

      expect(result.isPassed, isFalse);
      expect(result.recoveryPrompt, equals(recoveryPrompt));

      verify(mockTestFile.runFormat()).called(1);
      verify(mockPromptGen.formatError(errorMessage)).called(1);
    });
  });

  group('validators list', () {
    test('should contain all standard validators in correct order', () {
      expect(validators.length, equals(3));

      expect(validators[0], isA<AnalysisValidator>());
      expect(validators[1], isA<TestExecutionValidator>());
      expect(validators[2], isA<FormatValidator>());
    });

    test('should be unmodifiable', () {
      // Assert
      expect(() => validators.add(AnalysisValidator()), throwsUnsupportedError);
    });
  });
}
