import 'dart:io';

import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:testgen/src/LLM/model.dart';
import 'package:testgen/src/LLM/test_generator.dart';
import 'package:testgen/src/LLM/validator.dart';

@GenerateNiceMocks([
  MockSpec<GeminiModel>(),
  MockSpec<GeminiChat>(),
  MockSpec<AnalysisValidator>(),
  MockSpec<TestExecutionValidator>(),
  MockSpec<FormatValidator>(),
])
import 'test_generator_test.mocks.dart';

void main() {
  final tmpDir = path.absolute(path.join('test', 'tmp'));

  late MockGeminiModel mockModel;
  late MockGeminiChat mockChat;
  late MockAnalysisValidator mockAnalysisValidator;
  late MockTestExecutionValidator mockTestExecutionValidator;
  late MockFormatValidator mockFormatValidator;
  late TestGenerator generator;

  setUp(() {
    mockModel = MockGeminiModel();
    mockChat = MockGeminiChat();
    mockAnalysisValidator = MockAnalysisValidator();
    mockTestExecutionValidator = MockTestExecutionValidator();
    mockFormatValidator = MockFormatValidator();
    generator = TestGenerator(
      model: mockModel,
      validators: [
        mockAnalysisValidator,
        mockTestExecutionValidator,
        mockFormatValidator,
      ],
      packagePath: tmpDir,
      initialBackoff: Duration(seconds: 0),
    );

    when(mockModel.startChat()).thenReturn(mockChat);
    when(mockModel.countTokens(any)).thenAnswer((_) async => 1000);
  });

  tearDown(() {
    // Clean up generated test files in `tmp` directory
    final tmpTestDirectory = Directory(tmpDir);

    if (tmpTestDirectory.existsSync()) {
      tmpTestDirectory.deleteSync(recursive: true);
    }
  });

  group('TestGenerator.generate()', () {
    test('Create a valid test file on first attempt', () async {
      when(
        mockAnalysisValidator.validate(any, any),
      ).thenAnswer((_) async => ValidationResult(isPassed: true));
      when(
        mockTestExecutionValidator.validate(any, any),
      ).thenAnswer((_) async => ValidationResult(isPassed: true));
      when(
        mockFormatValidator.validate(any, any),
      ).thenAnswer((_) async => ValidationResult(isPassed: true));

      when(
        mockChat.sendMessage(any),
      ).thenAnswer((_) async => ChatResponse(code: '', needTesting: true));

      final result = await generator.generate(
        toBeTestedCode: '',
        contextCode: '',
        fileName: 'tmp_file.dart',
      );

      expect(result.status, equals(TestStatus.created));
      expect(result.attempts, equals(1));
      expect(result.tokens, equals(1000));

      verify(mockChat.sendMessage(any)).called(1);
      verify(mockModel.countTokens(mockChat)).called(1);
      verify(mockAnalysisValidator.validate(any, any)).called(1);
      verify(mockFormatValidator.validate(any, any)).called(1);
      verify(mockTestExecutionValidator.validate(any, any)).called(1);
    });

    test('Skip test generation when needTesting is false', () async {
      when(
        mockChat.sendMessage(any),
      ).thenAnswer((_) async => ChatResponse(code: '', needTesting: false));

      final result = await generator.generate(
        toBeTestedCode: '',
        contextCode: '',
        fileName: 'tmp_file.dart',
      );

      expect(result.status, equals(TestStatus.skipped));
      expect(result.attempts, equals(1));
      expect(result.tokens, equals(1000));

      verify(mockChat.sendMessage(any)).called(1);
      verify(mockModel.countTokens(mockChat)).called(1);
      verifyNever(mockAnalysisValidator.validate(any, any));
      verifyNever(mockFormatValidator.validate(any, any));
      verifyNever(mockTestExecutionValidator.validate(any, any));
    });

    test(
      'Retry on analysis validation failure and succeed on second attempt',
      () async {
        final responses = [
          ValidationResult(
            isPassed: false,
            recoveryPrompt: 'Fix the analysis errors',
          ),
          ValidationResult(isPassed: true),
        ];
        when(
          mockAnalysisValidator.validate(any, any),
        ).thenAnswer((_) async => responses.removeAt(0));
        when(
          mockTestExecutionValidator.validate(any, any),
        ).thenAnswer((_) async => ValidationResult(isPassed: true));

        when(
          mockFormatValidator.validate(any, any),
        ).thenAnswer((_) async => ValidationResult(isPassed: true));

        when(
          mockChat.sendMessage(any),
        ).thenAnswer((_) async => ChatResponse(code: '', needTesting: true));

        final result = await generator.generate(
          toBeTestedCode: '',
          contextCode: '',
          fileName: 'tmp_file.dart',
        );

        expect(result.status, equals(TestStatus.created));
        expect(result.attempts, equals(2));
        expect(result.tokens, equals(1000));

        verify(mockChat.sendMessage(any)).called(2);
        verify(mockAnalysisValidator.validate(any, any)).called(2);
        verify(mockTestExecutionValidator.validate(any, any)).called(1);
        verify(mockFormatValidator.validate(any, any)).called(1);
      },
    );

    test(
      'Retry on test execution failure and succeed on second attempt',
      () async {
        when(
          mockAnalysisValidator.validate(any, any),
        ).thenAnswer((_) async => ValidationResult(isPassed: true));

        final responses = [
          ValidationResult(
            isPassed: false,
            recoveryPrompt: 'Fix the test execution errors',
          ),
          ValidationResult(isPassed: true),
        ];
        when(
          mockTestExecutionValidator.validate(any, any),
        ).thenAnswer((_) async => responses.removeAt(0));
        when(
          mockFormatValidator.validate(any, any),
        ).thenAnswer((_) async => ValidationResult(isPassed: true));

        when(
          mockChat.sendMessage(any),
        ).thenAnswer((_) async => ChatResponse(code: '', needTesting: true));

        final result = await generator.generate(
          toBeTestedCode: '',
          contextCode: '',
          fileName: 'tmp_file.dart',
        );

        expect(result.status, equals(TestStatus.created));
        expect(result.attempts, equals(2));
        expect(result.tokens, equals(1000));

        verify(mockChat.sendMessage(any)).called(2);
        verify(mockAnalysisValidator.validate(any, any)).called(2);
        verify(mockTestExecutionValidator.validate(any, any)).called(2);
        verify(mockFormatValidator.validate(any, any)).called(1);
      },
    );

    test('Fail after exceeding max retries', () async {
      when(mockAnalysisValidator.validate(any, any)).thenAnswer(
        (_) async => ValidationResult(
          isPassed: false,
          recoveryPrompt: 'Fix the analysis errors',
        ),
      );

      when(
        mockChat.sendMessage(any),
      ).thenAnswer((_) async => ChatResponse(code: '', needTesting: true));

      final result = await generator.generate(
        toBeTestedCode: '',
        contextCode: '',
        fileName: 'tmp_file.dart',
      );

      expect(result.status, equals(TestStatus.failed));
      expect(result.attempts, equals(5));
      expect(result.tokens, equals(1000));

      verify(mockChat.sendMessage(any)).called(5);
      verify(mockAnalysisValidator.validate(any, any)).called(5);
      verifyNever(mockTestExecutionValidator.validate(any, any));
      verifyNever(mockFormatValidator.validate(any, any));
    });

    test('Multiple validation failures before success', () async {
      final analysisResponses = [
        ValidationResult(isPassed: false, recoveryPrompt: 'Fix analysis'),
        ValidationResult(isPassed: true),
        ValidationResult(isPassed: true),
      ];
      when(
        mockAnalysisValidator.validate(any, any),
      ).thenAnswer((_) async => analysisResponses.removeAt(0));

      final testExecutionResponses = [
        ValidationResult(isPassed: false, recoveryPrompt: 'Fix test execution'),
        ValidationResult(isPassed: true),
      ];
      when(
        mockTestExecutionValidator.validate(any, any),
      ).thenAnswer((_) async => testExecutionResponses.removeAt(0));

      when(
        mockFormatValidator.validate(any, any),
      ).thenAnswer((_) async => ValidationResult(isPassed: true));

      when(
        mockChat.sendMessage(any),
      ).thenAnswer((_) async => ChatResponse(code: '', needTesting: true));

      final result = await generator.generate(
        toBeTestedCode: '',
        contextCode: '',
        fileName: 'tmp_file.dart',
      );

      expect(result.status, equals(TestStatus.created));
      expect(result.attempts, equals(3));

      verify(mockChat.sendMessage(any)).called(3);
      verify(mockAnalysisValidator.validate(any, any)).called(3);
      verify(mockTestExecutionValidator.validate(any, any)).called(2);
      verify(mockFormatValidator.validate(any, any)).called(1);
    });
  });

  group('Exception handling', () {
    test('Handle rate limit error with backoff and retry', () async {
      when(
        mockAnalysisValidator.validate(any, any),
      ).thenAnswer((_) async => ValidationResult(isPassed: true));

      when(
        mockTestExecutionValidator.validate(any, any),
      ).thenAnswer((_) async => ValidationResult(isPassed: true));

      when(
        mockFormatValidator.validate(any, any),
      ).thenAnswer((_) async => ValidationResult(isPassed: true));

      final responses = [
        Exception('Rate limit exceeded'),
        ChatResponse(code: '', needTesting: true),
      ];
      when(mockChat.sendMessage(any)).thenAnswer((_) async {
        final response = responses.removeAt(0);
        if (response is Exception) {
          throw response;
        }
        return response as ChatResponse;
      });

      final result = await generator.generate(
        toBeTestedCode: '',
        contextCode: '',
        fileName: 'tmp_file.dart',
      );

      expect(result.status, equals(TestStatus.created));
      expect(result.attempts, equals(2));

      verify(mockChat.sendMessage(any)).called(2);
      verify(mockAnalysisValidator.validate(any, any)).called(1);
      verify(mockTestExecutionValidator.validate(any, any)).called(1);
      verify(mockFormatValidator.validate(any, any)).called(1);
    });

    test('Throw error when daily quota exceeded', () async {
      final generatorWithShortBackoff = TestGenerator(
        model: mockModel,
        validators: [
          mockAnalysisValidator,
          mockTestExecutionValidator,
          mockFormatValidator,
        ],
        packagePath: tmpDir,
        initialBackoff: Duration(seconds: 128),
      );

      when(
        mockChat.sendMessage(any),
      ).thenAnswer((_) async => throw Exception('Rate limit exceeded'));

      expect(
        () async => await generatorWithShortBackoff.generate(
          toBeTestedCode: '',
          contextCode: '',
          fileName: 'tmp_file.dart',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Handle non-rate-limit errors (network, parsing, ...)', () async {
      when(
        mockAnalysisValidator.validate(any, any),
      ).thenAnswer((_) async => ValidationResult(isPassed: true));

      when(
        mockTestExecutionValidator.validate(any, any),
      ).thenAnswer((_) async => ValidationResult(isPassed: true));

      when(
        mockFormatValidator.validate(any, any),
      ).thenAnswer((_) async => ValidationResult(isPassed: true));

      final responses = [
        Exception('Network error'),
        ChatResponse(code: '', needTesting: true),
      ];
      when(mockChat.sendMessage(any)).thenAnswer((_) async {
        final response = responses.removeAt(0);
        if (response is Exception) {
          throw response;
        }
        return response as ChatResponse;
      });

      final result = await generator.generate(
        toBeTestedCode: '',
        contextCode: '',
        fileName: 'tmp_file.dart',
      );

      expect(result.status, equals(TestStatus.created));
      expect(result.attempts, equals(2));

      verify(mockChat.sendMessage(any)).called(2);
      verify(mockAnalysisValidator.validate(any, any)).called(1);
      verify(mockTestExecutionValidator.validate(any, any)).called(1);
      verify(mockFormatValidator.validate(any, any)).called(1);
    });
  });

  group('Test file existence', () {
    test('File exists when test is created', () async {
      when(
        mockAnalysisValidator.validate(any, any),
      ).thenAnswer((_) async => ValidationResult(isPassed: true));
      when(
        mockTestExecutionValidator.validate(any, any),
      ).thenAnswer((_) async => ValidationResult(isPassed: true));
      when(
        mockFormatValidator.validate(any, any),
      ).thenAnswer((_) async => ValidationResult(isPassed: true));

      when(mockChat.sendMessage(any)).thenAnswer(
        (_) async => ChatResponse(code: 'test code', needTesting: true),
      );

      final result = await generator.generate(
        toBeTestedCode: '',
        contextCode: '',
        fileName: 'tmp_file.dart',
      );

      expect(result.status, equals(TestStatus.created));
      expect(
        File(
          path.join(tmpDir, 'test', 'testgen', 'tmp_file.dart'),
        ).existsSync(),
        isTrue,
      );
    });

    test('File does not exist when test generation failed', () async {
      when(mockAnalysisValidator.validate(any, any)).thenAnswer(
        (_) async => ValidationResult(
          isPassed: false,
          recoveryPrompt: 'Fix the analysis errors',
        ),
      );

      when(mockChat.sendMessage(any)).thenAnswer(
        (_) async => ChatResponse(code: 'test code', needTesting: true),
      );

      final result = await generator.generate(
        toBeTestedCode: '',
        contextCode: '',
        fileName: 'tmp_file.dart',
      );

      expect(result.status, equals(TestStatus.failed));
      expect(
        File(
          path.join(tmpDir, 'test', 'testgen', 'tmp_file.dart'),
        ).existsSync(),
        isFalse,
      );
    });

    test('File does not exist when created and then skipped', () async {
      final responses = [
        ChatResponse(code: 'test code', needTesting: true),
        ChatResponse(code: 'test code', needTesting: false),
      ];
      when(
        mockChat.sendMessage(any),
      ).thenAnswer((_) async => responses.removeAt(0));

      when(mockAnalysisValidator.validate(any, any)).thenAnswer(
        (_) async => ValidationResult(
          isPassed: false,
          recoveryPrompt: 'Fix the analysis errors',
        ),
      );

      final result = await generator.generate(
        toBeTestedCode: '',
        contextCode: '',
        fileName: 'tmp_file.dart',
      );

      expect(result.status, equals(TestStatus.skipped));
      expect(result.attempts, equals(2));
      expect(
        File(
          path.join(tmpDir, 'test', 'testgen', 'tmp_file.dart'),
        ).existsSync(),
        isFalse,
      );
    });

    test(
      'File does not exist when daily limit reached after being created',
      () async {
        final generatorWithShortBackoff = TestGenerator(
          model: mockModel,
          validators: [
            mockAnalysisValidator,
            mockTestExecutionValidator,
            mockFormatValidator,
          ],
          packagePath: tmpDir,
          initialBackoff: Duration(seconds: 128),
        );

        when(mockAnalysisValidator.validate(any, any)).thenAnswer(
          (_) async => ValidationResult(
            isPassed: false,
            recoveryPrompt: 'Fix the analysis errors',
          ),
        );

        final responses = [
          ChatResponse(code: 'test code', needTesting: true),
          Exception('rate limit exceeded'),
        ];
        when(mockChat.sendMessage(any)).thenAnswer((_) async {
          final response = responses.removeAt(0);
          if (response is Exception) {
            throw response;
          }
          return response as ChatResponse;
        });

        expect(
          () async => await generatorWithShortBackoff.generate(
            toBeTestedCode: '',
            contextCode: '',
            fileName: 'tmp_file.dart',
          ),
          throwsA(isA<StateError>()),
        );

        expect(
          File(
            path.join(tmpDir, 'test', 'testgen', 'tmp_file.dart'),
          ).existsSync(),
          isFalse,
        );
      },
    );
  });
}
