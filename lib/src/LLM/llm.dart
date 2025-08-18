import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:testgen/src/LLM/prompt_generator.dart';
import 'package:testgen/src/LLM/test_file.dart';

enum TestStatus { created, failed, skipped }

class LLMResponse {
  final String code;
  final bool needTesting;
  final String? comments;

  LLMResponse({required this.code, required this.needTesting, this.comments});

  factory LLMResponse.fromJson(Map<String, dynamic> json) {
    return LLMResponse(
      code: json['code'] as String,
      needTesting: json['needTesting'] as bool,
      comments: json['comments'] as String?,
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
/// - [model]: The model name to use. such as:
///     - 'gemini-2.5-pro' (default value)
///     - 'gemini-2.5-flash'
///     - 'gemini-2.5-flash-lite', ...
/// - [apiKey]: Optional API key for authentication. If not provided,
///   uses the GEMINI_API_KEY environment variable.
///
/// The returned model is configured with a response schema for test case generation,
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
      'comments': Schema.string(
        description: 'Any Comments about the test generation process.',
        nullable: true,
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
/// feedback loop. It prompts the LLM to create a test for the provided Dart
/// code and context, writes the generated test to a file, analyzes it for
/// errors, and sends any analyzer or test failures back to the LLM for
/// correction. This process repeats until the test passes or the maximum
/// number of retries is reached, applying exponential backoff on rate limits.
///
/// If successful, the test file is formatted; otherwise, it is removed.
///
/// Returns a [TestStatus] indicating whether the test was created, failed, or
/// skipped, along with the [ChatSession] for any further analytics.
Future<(TestStatus, ChatSession, TestFile)> generateTestFile(
  GenerativeModel model,
  String toBeTestedCode,
  String contextCode,
  String packagePath,
  String fileName, {
  int maxRetries = 5,
  Duration initialBackoff = const Duration(seconds: 1),
}) async {
  final chat = model.startChat();
  print('Starting test generation for $fileName');

  int attempt = 0;
  TestStatus status = TestStatus.failed;
  Duration backoff = initialBackoff;
  final TestFile testFileManager = TestFile(packagePath, fileName);
  String prompt = PromptGenerator.testCode(toBeTestedCode, contextCode);

  while (attempt < maxRetries) {
    attempt++;
    print('\t Sending prompt to LLM (attempt $attempt/$maxRetries)');

    try {
      final response = await chat.sendMessage(Content.text(prompt));
      if (response.text == null) {
        throw Exception('No response text received from the model.');
      }
      backoff = initialBackoff;

      final result = LLMResponse.fromJson(jsonDecode(response.text!));
      if (!result.needTesting) {
        print('\t Code does not need testing - skipping');
        status = TestStatus.skipped;
        break;
      }

      print('\t Writing generated test to file');
      await testFileManager.writeTest(result.code, result.comments);

      print('\t Analyzing generated test code');
      final analyzerErrors = await testFileManager.runAnalyzer(result.code);
      if (analyzerErrors != null) {
        print('\t Analyzer found errors, sending feedback to LLM');
        print(analyzerErrors);
        prompt = PromptGenerator.analysisError(analyzerErrors);
        continue;
      }

      print('\t Running generated test');
      final testResult = await testFileManager.runTest();
      if (testResult != null) {
        print('\t ❌ Test execution failed, sending feedback to LLM');
        print(testResult);
        prompt = PromptGenerator.testFailError(testResult);
        continue;
      }

      print('\t Formatting test file');
      await testFileManager.formatTest();

      print('\t ✅ Test generated successfully!');
      status = TestStatus.created;
      break;
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();

      if (errorMessage.contains('you exceeded your current quota')) {
        testFileManager.deleteTest();
        print('\t API quota exceeded - stopping retries');
        exit(0);
      }

      if (errorMessage.contains('rate limit exceeded')) {
        print('\t Rate limit exceeded');
        await Future.delayed(backoff);
        backoff *= 2;
        continue;
      }

      prompt = PromptGenerator.fixError(errorMessage);
      print('Error details: $e');
    }
  }

  if (status == TestStatus.failed || status == TestStatus.skipped) {
    print('\t 💥 Test generation failed after $maxRetries attempts');
    print('\t 🗑️ Cleaning up failed test file');
    await testFileManager.deleteTest();
  }

  print('\t 🏁 Test generation completed with status: ${status.name}');
  return (status, chat, testFileManager);
}

Future<int> getTokenCount(GenerativeModel model, ChatSession chat) async {
  final historyContents = chat.history.toList();

  final tokenResponse = await model.countTokens(historyContents);
  final totalTokens = tokenResponse.totalTokens;

  return totalTokens;
}
