import 'package:testgen/src/LLM/model.dart';
import 'package:testgen/src/LLM/prompt_generator.dart';
import 'package:testgen/src/LLM/test_file.dart';
import 'package:testgen/src/LLM/validator.dart'
    show validators, ValidationResult;

enum TestStatus { created, failed, skipped }

/// Result object returned after attempting to generate tests.
///
/// Contains:
/// - the generated test file,
/// - final status of test generation,
/// - total consumed tokens,
/// - number of attempts made.
class GenerationResponse {
  GenerationResponse({
    required this.testFile,
    required this.status,
    required this.tokens,
    required this.attempts,
  });

  final TestFile testFile;
  final TestStatus status;
  final int tokens;
  final int attempts;

  @override
  String toString() {
    const String reset = '\x1b[0m';
    const String red = '\x1b[31m';
    const String green = '\x1b[32m';
    const String yellow = '\x1b[33m';

    return '''[testgen] Test generation ended with ${switch (status) {
      TestStatus.created => green,
      TestStatus.skipped => yellow,
      TestStatus.failed => red,
    }}$status$reset and used $tokens tokens.
      With $attempts attempt(s) including ${testFile.analyzerErrors} analyzer
      errors and ${testFile.testErrors} test errors.
      ''';
  }
}

/// Class coordinates the LLM interaction, validation, and file writing
/// required to generate a valid test for a Dart source code.
class TestGenerator {
  TestGenerator({
    required this.model,
    required this.packagePath,
    this.promptGenerator = const PromptGenerator(),
    this.maxRetries = 5,
    this.initialBackoff = const Duration(seconds: 32),
  });

  final GeminiModel model;
  final String packagePath;
  final PromptGenerator promptGenerator;
  final int maxRetries;
  final Duration initialBackoff;

  Future<ValidationResult> _runValidators(
    TestFile testFile,
    PromptGenerator promptGenerator,
  ) async {
    for (final check in validators) {
      final checkResult = await check.validate(testFile, promptGenerator);
      if (!checkResult.isPassed) {
        return checkResult;
      }
    }
    return ValidationResult(isPassed: true);
  }

  /// Generates a test file for the provided source code using the [model].
  /// It takes [toBeTestedCode] as the main code to test, [contextCode] to give
  /// the model additional context about dependencies, and [fileName] to
  /// determine where the generated test should be saved.
  ///
  /// The method prompts the LLM, validates the output, retries on failure, and
  /// returns the final [GenerationResponse].
  Future<GenerationResponse> generate({
    required String toBeTestedCode,
    required String contextCode,
    required String fileName,
  }) async {
    final chat = model.startChat();
    TestStatus status = TestStatus.failed;
    Duration backoff = initialBackoff;
    final testFile = TestFile(packagePath, fileName);
    String prompt = promptGenerator.testCode(toBeTestedCode, contextCode);

    int attempt = 1;
    for (; attempt <= maxRetries && status == TestStatus.failed; attempt++) {
      print(
        '[LLM] Attempt $attempt / $maxRetries to generate test for $fileName',
      );
      try {
        final response = await chat.sendMessage(prompt);

        // reset backoff on successful response
        backoff = initialBackoff;

        if (response.needTesting) {
          await testFile.writeTest(response.code);

          final validation = await _runValidators(testFile, promptGenerator);

          if (validation.isPassed) {
            status = TestStatus.created;
          } else {
            prompt = validation.recoveryPrompt!;
          }
        } else {
          print('[LLM] No significant logic to test in $fileName. Skipping.');
          status = TestStatus.skipped;
        }
      } catch (e) {
        final errorMessage = e.toString().toLowerCase();

        bool isRateLimitError =
            errorMessage.contains('rate limit exceeded') ||
            errorMessage.contains('you exceeded your current quota');

        // Exit only if the daily quota (RPD) exceeded and prevent exiting if
        // the quota exceeded for (RPM) or (TPM) by waiting at least a minute.
        if (isRateLimitError && backoff.inSeconds >= 128) {
          status = TestStatus.failed;
          await testFile.deleteTest();
          throw StateError(
            'You exceeded your daily quota, try again later or change model',
          );
        }

        if (isRateLimitError) {
          print('[LLM] Rate limit exceeded, retrying in $backoff...');
          await Future.delayed(backoff);
          backoff *= 2;
          continue;
        }

        print('[LLM] Error encountered');
        prompt = promptGenerator.fixError(errorMessage);
      }
    }

    if (status == TestStatus.failed || status == TestStatus.skipped) {
      await testFile.deleteTest();
    }

    final tokens = await model.countTokens(chat);

    return GenerationResponse(
      testFile: testFile,
      status: status,
      tokens: tokens,
      attempts: attempt,
    );
  }
}
