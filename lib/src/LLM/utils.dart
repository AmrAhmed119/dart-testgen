import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:path/path.dart' as path;

class LLMResponse {
  final String code;
  final bool needTesting;
  final ChatSession chatSession;
  final String? comments;

  LLMResponse({
    required this.code,
    required this.needTesting,
    required this.chatSession,
    this.comments,
  });
}

LLMResponse? jsonParser(GenerateContentResponse response, ChatSession chat) {
  if (response.text == null) return null;

  final json = jsonDecode(response.text!);
  return LLMResponse(
    code: json['code'],
    needTesting: json['needTesting'],
    chatSession: chat,
    comments: json['comments'] ?? '',
  );
}

void writeTestToFile(
  LLMResponse response,
  String packagePath,
  String fileName,
) {
  final testFilePath = path.join(packagePath, 'test', 'testgen', fileName);
  final testFile = File(testFilePath);

  if (!testFile.existsSync()) {
    testFile.createSync(recursive: true);
  }

  testFile.writeAsStringSync(response.code);
}



// /// Runs a command (e.g., `dart analyze` or `dart test`) with retry logic.
// Future<bool> retry({
//   required ChatSession chat,
//   required List<String> error,
//   required LLMResponse initialResponse,
//   required String Function(String) promptGenerator,
//   int retryLimit = 5,
// }) async {
//   int attempt = 1;

//   while (attempt <= retryLimit && error.isNotEmpty) {
//     await Future.delayed(Duration(seconds: 5));
//     final errorReason = error.join('\n');

//     final chatResponse = await chat.sendMessage(
//       Content.text(promptGenerator(errorReason)),
//     );

//     final currentResponse = jsonParser(chatResponse);
//     if (currentResponse == null) {
//       error = [
//         'Failed to parse response from the model. Please check the model configuration.',
//       ];
//       continue;
//     }
//     initialResponse = currentResponse;
    
//     final newAnalysis = parseString(content: currentResponse.code);
//     final severity = newAnalysis.errors.where(
//       (e) => e.severity == Severity.error,
//     );

//     if (severity.isEmpty) {
//       return true;
//     }

//     error = severity.map((e) => e.message).toList();
//     attempt++;
//   }

//   return error.isEmpty;
// }

// /// Runs `dart analyze` on the test file.
// Future<bool> runDartAnalyze(
//   ChatSession chat,
//   String testFilePath,
//   LLMResponse initialResponse,
// ) {
//   return _runWithRetry(
//     chat: chat,
//     command: 'dart',
//     args: ['analyze', testFilePath],
//     testFilePath: testFilePath,
//     initialResponse: initialResponse,
//     promptGenerator: PromptGenerator.analyzeErrorPrompt,
//   );
// }

// /// Runs `dart test` on the test file.
// Future<bool> runDartTest(
//   ChatSession chat,
//   String testFilePath,
//   LLMResponse initialResponse,
// ) {
//   return _runWithRetry(
//     chat: chat,
//     command: 'dart',
//     args: ['test', testFilePath],
//     testFilePath: testFilePath,
//     initialResponse: initialResponse,
//     promptGenerator: PromptGenerator.testNotRunningErrorPrompt,
//   );
// }



// /// Runs a command (e.g., `dart analyze` or `dart test`) with retry logic.
// Future<bool> _runWithRetry({
//   required ChatSession chat,
//   required String command,
//   required List<String> args,
//   required String testFilePath,
//   required LLMResponse initialResponse,
//   required String Function(String) promptGenerator,
// }) async {
//   var result = Process.runSync(
//     command,
//     args,
//     workingDirectory: testFilePath,
//   );
//   int attempt = 1;

//   while (result.exitCode != 0 && attempt <= retryLimit) {
//     print('Error running `$command ${args.join(' ')}`');

//     await Future.delayed(Duration(seconds: 10));
//     final error = result.stdout.toString();

//     final chatResponse = await chat.sendMessage(
//       Content.text(
//         attempt == retryLimit
//             ? PromptGenerator.commentErrors(error)
//             : promptGenerator(error),
//       ),
//     );

//     final currentResponse = jsonParser(chatResponse);
//     if (currentResponse == null) continue;

//     writeToFile(testFilePath, currentResponse.code);
//     result = Process.runSync(
//       command,
//       args,
//       workingDirectory: getRootDirectoryAbsolutePath(testFilePath),
//     );
//     attempt++;
//   }

//   return result.exitCode == 0;
// }

// /// Runs `dart analyze` on the test file.
// Future<bool> runDartAnalyze(
//   ChatSession chat,
//   String testFilePath,
//   LLMResponse initialResponse,
// ) {
//   return _runWithRetry(
//     chat: chat,
//     command: 'dart',
//     args: ['analyze', testFilePath],
//     testFilePath: testFilePath,
//     initialResponse: initialResponse,
//     promptGenerator: PromptGenerator.analyzeErrorPrompt,
//   );
// }

// /// Runs `dart test` on the test file.
// Future<bool> runDartTest(
//   ChatSession chat,
//   String testFilePath,
//   LLMResponse initialResponse,
// ) {
//   return _runWithRetry(
//     chat: chat,
//     command: 'dart',
//     args: ['test', testFilePath],
//     testFilePath: testFilePath,
//     initialResponse: initialResponse,
//     promptGenerator: PromptGenerator.testNotRunningErrorPrompt,
//   );
// }