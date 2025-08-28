import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:testgen/src/LLM/validator.dart';
import 'package:testgen/src/LLM/prompt_generator.dart';
import 'package:testgen/src/LLM/test_file.dart';

enum TestStatus { created, failed, skipped }

class LLMResponse {
  final String code;
  final bool needTesting;

  LLMResponse({required this.code, required this.needTesting});

  factory LLMResponse.fromJson(Map<String, dynamic> json) {
    return LLMResponse(
      code: json['code'] as String,
      needTesting: json['needTesting'] as bool,
    );
  }
}

final _apiKey = () {
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null) {
    stderr.writeln(r'No $GEMINI_API_KEY environment variable');
    exit(1);
  }
  return apiKey;
}();

/// Creates and configures a [GenerativeModel] for LLM-based test generation.
///
/// Parameters:
/// - [model]: The model name to use. such as:
///     - 'gemini-2.5-pro' (default value)
///     - 'gemini-2.5-flash'
///     - 'gemini-2.5-flash-lite', ...
/// - [apiKey]: Optional API key for authentication. If not provided,
///   uses the GEMINI_API_KEY environment variable.
///
/// Returns a configured model with JSON response schema for generating
/// structured responses.
GenerativeModel createModel({String model = 'gemini-2.5-pro', String? apiKey}) {
  final schema = Schema.object(
    description: 'Schema for generated test cases from the model',
    properties: {
      'code': Schema.string(
        description:
            'Generated Dart test code. Empty string if needTesting is false.',
        nullable: false,
      ),
      'needTesting': Schema.boolean(
        description:
            'Only true if code has significant logic requiring tests.'
            'False for: simple getters/setters, basic constructors,'
            'trivial methods, constants, or simple data classes.',
        nullable: false,
      ),
    },
    requiredProperties: ['code', 'needTesting'],
  );

  return GenerativeModel(
    model: model,
    apiKey: apiKey ?? _apiKey,
    systemInstruction: Content.text(
      'You are a code assistant that generates'
      'Dart test cases based on provided code snippets.',
    ),
    generationConfig: GenerationConfig(
      candidateCount: 1,
      temperature: 0.2,
      topP: 0.95,
      responseMimeType: 'application/json',
      responseSchema: schema,
    ),
  );
}

/// Generates and validates a Dart test file using an LLM through an iterative
/// feedback loop. This function orchestrates the complete test generation
/// process by prompting the LLM to create a test for the provided
/// [toBeTestedCode] and [contextCode], writing the generated test to a file
/// in the `test/testgen/` directory, and running validation checks including
/// analysis, execution, and formatting. If validation fails, it sends error
/// feedback to the LLM for correction and repeats until all checks pass or
/// [maxRetries] is reached.
///
/// The function applies exponential backoff on rate limit errors starting
/// with [initialBackoff] delay.
///
/// The [promptGen] parameter allows custom prompt templates while
/// [coverageValidator] ensures generated tests improve code coverage.
///
/// Returns a tuple containing a [TestStatus] indicating whether the test was
/// created, failed, or skipped, along with the [ChatSession] for token counting
/// and analytics. Failed or skipped test files are automatically cleaned up.
Future<(TestStatus, ChatSession)> generateTestFile({
  required GenerativeModel model,
  required String toBeTestedCode,
  required String contextCode,
  required String packagePath,
  required String fileName,
  PromptGenerator promptGen = const PromptGenerator(),
  Validator? coverageValidator,
  int maxRetries = 5,
  Duration initialBackoff = const Duration(seconds: 1),
}) async {
  final chat = model.startChat();
  TestStatus status = TestStatus.failed;
  Duration backoff = initialBackoff;
  final TestFile testFileManager = TestFile(packagePath, fileName);
  String prompt = promptGen.testCode(toBeTestedCode, contextCode);

  int attempt = 0;
  while (attempt < maxRetries) {
    attempt++;
    print(
      '[LLM] Attempt $attempt / $maxRetries to generate test for $fileName',
    );
    try {
      final response = await chat.sendMessage(Content.text(prompt));
      if (response.text == null) {
        throw Exception('No response text received from the model.');
      }

      backoff = initialBackoff;
      final result = LLMResponse.fromJson(jsonDecode(response.text!));

      if (!result.needTesting) {
        print('[LLM] No significant logic to test in $fileName. Skipping.');
        status = TestStatus.skipped;
        break;
      }

      await testFileManager.writeTest(result.code);

      bool allChecksPassed = true;
      for (final check in validators) {
        final checkResult = await check.validate(testFileManager, promptGen);
        if (!checkResult.isPassed) {
          print('[Validator] Check failed.');
          prompt = checkResult.recoveryPrompt!;
          allChecksPassed = false;
          break;
        }
      }
      if (allChecksPassed) {
        status = TestStatus.created;
        break;
      }
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();

      // Exit only if the daily quota (RPD) exceeded and prevent exiting if
      // the quota exceeded for (RPM) or (TPM) by waiting at least a minute.
      if (errorMessage.contains('you exceeded your current quota') &&
          backoff.inSeconds >= 128) {
        status = TestStatus.failed;
        stderr.writeln(
          "You exceeded you daily quota, try again tomorrow or try another model",
        );
        exit(0);
      }

      if (errorMessage.contains('rate limit exceeded') ||
          errorMessage.contains('you exceeded your current quota')) {
        await Future.delayed(backoff);
        print('[LLM] Rate limit exceeded, retrying in $backoff...');
        backoff *= 2;
        continue;
      }

      print('[LLM] Error encountered');
      prompt = promptGen.fixError(errorMessage);
    }
  }

  if (coverageValidator != null && status == TestStatus.created) {
    final coverageResult = await coverageValidator.validate(
      testFileManager,
      promptGen,
    );
    if (!coverageResult.isPassed) {
      status = TestStatus.failed;
    }
  }

  if (status == TestStatus.failed || status == TestStatus.skipped) {
    await testFileManager.deleteTest();
  }

  return (status, chat);
}

/// Returns the total number of tokens used in the [chat] session.
Future<int> countTokens(GenerativeModel model, ChatSession chat) async =>
    (await model.countTokens(chat.history)).totalTokens;
