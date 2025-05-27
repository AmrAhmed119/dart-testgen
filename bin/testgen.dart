import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:testgen/src/file_manager.dart';
import 'package:testgen/src/llm.dart';
import 'package:testgen/src/utils.dart';

Future<bool> processFile(
  String filePath,
  String fileContent,
  GenerativeModel model,
) async {
  final (respone, chat) = await generateTest(filePath, fileContent, model);

  if (respone == null || !respone.needTesting) {
    print('⚠️ Skipping $filePath: No tests needed.');
    return false;
  }

  final testFilePath = generateTestFilePath(filePath);

  writeToFile(testFilePath, respone.code);

  final isTestCompiled = await runDartTest(chat, testFilePath, respone);
  final isAnalysisPassed = await runDartAnalyze(chat, testFilePath, respone);

  if (isAnalysisPassed && isTestCompiled) {
    writeToFile(getHintFilePath(filePath), '''
    Comments Provided about the generation:
    ${respone.comments}

    List of required dependencies:
    ${respone.dependencies}
    ''');
    return true;
  }

  deleteFile(testFilePath);

  return false;
}

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    stderr.writeln(r'No directory path is provided');
    exit(1);
  }

  final rootDirectory = arguments[0];
  final filePaths = exploreDartFiles(rootDirectory);

  final model = createModel();
  filePaths.removeAt(0); // Remove the export file of the package from the list.

  for (final filePath in filePaths) {
    final fileContent = readFromFile(filePath);
    final fileRelativePath = getRootDirectoryRelativePath(filePath);

    print('Generating Test file... for \'$fileRelativePath\'');

    final isTestFileGenerated = await processFile(filePath, fileContent, model);

    if (isTestFileGenerated) {
      print('✅ Test file generated successfully for $fileRelativePath');
    } else {
      print('❌ Test file not generated successfully');
    }
  }}

