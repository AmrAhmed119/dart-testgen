import 'dart:io';
import 'package:path/path.dart' as path;

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:testgen/src/LLM/prompt_generator.dart';
import 'package:testgen/src/LLM/utils.dart';

final _apiKey = () {
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null) {
    stderr.writeln(r'No $GEMINI_API_KEY environment variable');
    exit(1);
  }
  return apiKey;
}();

/// Creates and configures a [GenerativeModel] for LLM-based code generation.
///
/// - [model]: The model name to use. such as:
///     - 'gemini-2.5-flash' (default value)
///     - 'gemini-2.5-pro'
///     - 'gemini-2.5-flash-lite', ...
/// - [apiKey]: Optional API key for authentication. If not provided,
///   uses the GEMINI_API_KEY environment variable.
///
/// The returned model is configured with a response schema for test case generation,
GenerativeModel createModel({
  String model = 'gemini-2.5-flash',
  String? apiKey,
}) {
  final schema = Schema.object(
    description: 'Schema for generated test cases from the model',
    properties: {
      'code': Schema.string(
        description: 'The source code of the generated test cases.',
        nullable: false,
      ),
      'needTesting': Schema.boolean(
        description: 'true or false denoting if the code need test or not',
        nullable: false,
      ),
      'comments': Schema.string(
        description: 'Comments from the model about the generation process.',
        nullable: true,
      ),
    },
    requiredProperties: ['code', 'needTesting'],
  );

  return GenerativeModel(
    model: model,
    apiKey: apiKey ?? _apiKey,
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
      responseSchema: schema,
    ),
  );
}

/// Generates a Dart test file using an LLM, with feedback loop for analyzer
/// and test errors.
///
/// This function sends the prompt to the LLM and parses the response, writes
/// the generated code to a test file, analyzes the generated code for errors
/// and if errors are found, sends feedback to the LLM and retries. It then
/// runs the generated test, and if the test fails, sends feedback to the LLM
/// and retries. The function also formats the generated file, implements
/// exponential backoff on rate limiting, and cleans up the test file if
/// generation fails after all retries.
Future<void> generateTestFile(
  GenerativeModel model,
  String prompt,
  String packagePath,
  String fileName, {
  int maxRetries = 5,
  Duration initialBackoff = const Duration(seconds: 1),
}) async {
  final chat = model.startChat();
  int attempt = 0;
  bool isGenerated = false;
  Duration backoff = initialBackoff;
  print('\t[LLM] Generating test ...');
  var response = await chat.sendMessage(Content.text(prompt));

  while (attempt < maxRetries) {
    try {
      print('\t[LLM] Sending prompt to LLM (attempt ${attempt + 1})...');
      if (response.text == null) {
        print('\t[LLM] Response text is null!');
        throw Exception('No response text received from the model.');
      }
      backoff = initialBackoff;

      print('\t[LLM] Parsing LLM response...');
      final result = jsonParser(response, chat)!;
      if (result.code.isEmpty && !result.needTesting) {
        print('\t[LLM] No need for testing, skipping...');
        break;
      }

      print('\t[LLM] Writing generated test to file...');
      writeTestToFile(result, packagePath, fileName);

      print('\t[LLM] Analyzing generated test file...');
      final analyzeResult = await _analyzeTestFile(packagePath, fileName);

      if (analyzeResult.exitCode != 0) {
        print('\t[LLM] Analyzer found errors.');
        response = await chat.sendMessage(
          Content.text(
            PromptGenerator.analysisError(analyzeResult.stdout.toString()),
          ),
        );
        attempt++;
        continue;
      }

      print('\t[LLM] Running generated test...');
      final testResult = await _runTestFile(packagePath, fileName);

      if (testResult.exitCode != 0) {
        print('\t[LLM] Test failed.');
        response = await chat.sendMessage(
          Content.text(
            PromptGenerator.testFailError(testResult.stdout.toString()),
          ),
        );
        attempt++;
        continue;
      }

      print('\t[LLM] Formatting generated test file...');
      await _formatTestFile(packagePath, fileName);

      isGenerated = true;
      print('\t[LLM] Test generated and passed successfully!');
      break;
    } catch (e) {
      stderr.writeln(
        '[LLM] Rate limited, backing off for ${backoff.inSeconds}s...',
      );
      await Future.delayed(backoff);
      backoff *= 2;
      attempt++;
      continue;
    }
  }
  if (!isGenerated) {
    stderr.writeln('[LLM] Failed to generate test after $maxRetries attempts.');
    // delete the file
    final testFilePath = path.join(packagePath, 'test', 'testgen', fileName);
    if (File(testFilePath).existsSync()) {
      print('\t[LLM] Cleaning up failed test file...');
      File(testFilePath).deleteSync();
    }
  } else {
    print('\t[LLM] Test generated successfully: $fileName');
  }
}

/// Runs `dart analyze` on the generated test file and returns the result.
Future<ProcessResult> _analyzeTestFile(
  String packagePath,
  String fileName,
) async {
  print('\t[LLM] Running dart analyze...');
  return await Process.run('dart', [
    'analyze',
    fileName,
  ], workingDirectory: path.join(packagePath, 'test', 'testgen'));
}

/// Runs `dart test` on the generated test file and returns the result.
Future<ProcessResult> _runTestFile(String packagePath, String fileName) async {
  print('\t[LLM] Running dart test...');
  return await Process.run('dart', [
    'test',
    fileName,
  ], workingDirectory: path.join(packagePath, 'test', 'testgen'));
}

/// Runs `dart format` on the generated test file.
Future<void> _formatTestFile(String packagePath, String fileName) async {
  print('\t[LLM] Running dart format...');
  await Process.run('dart', [
    'format',
    fileName,
  ], workingDirectory: path.join(packagePath, 'test', 'testgen'));
}
