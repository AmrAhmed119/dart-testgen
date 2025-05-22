import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:testgen/src/file_manager.dart';
import 'package:testgen/src/prompt_generator.dart';
import 'package:testgen/src/utils.dart';

class LLMResponse {
  final String code;
  final String comments;
  final List<dynamic> dependencies;
  final bool needTesting;

  LLMResponse({
    required this.code,
    required this.needTesting,
    this.comments = '',
    List<dynamic>? dependencies,
  }) : dependencies = dependencies ?? [];
}

final _apiKey = () {
  final apiKey = Platform.environment['GEMINI_API_KEY'];
  if (apiKey == null) {
    stderr.writeln(r'No $GEMINI_API_KEY environment variable');
    exit(1);
  }
  return apiKey;
}();

GenerativeModel createModel() {
  // Define `Structured output` schema for the model output.
  final schema = Schema.object(
    description: 'Schema for generated test cases from the model',
    properties: {
      'code': Schema.string(
        description: 'The source code of the generated test cases.',
        nullable: false,
      ),
      'needTesting': Schema.boolean(
        description: 'true or false denoting if the file need test or not',
        nullable: false,
      ),
      'comments': Schema.string(
        description: 'Comments from the model about the generation process.',
        nullable: true,
      ),
      'dependencies': Schema.array(
        description: 'List of additional dependencies required for testing.',
        items: Schema.string(),
        nullable: true,
      ),
    },
    requiredProperties: ['code'],
  );

  return GenerativeModel(
    model: 'gemini-2.0-flash',
    apiKey: _apiKey,
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
      responseSchema: schema,
    ),
  );
}

Future<(LLMResponse?, ChatSession)> generateTest(
  String filePath,
  String fileCode,
  GenerativeModel model,
) async {
  final chat = model.startChat();

  try {
    final response = await chat.sendMessage(
      Content.text(
        PromptGenerator.testPrompt(
          fileCode,
          getRootDirectoryRelativePath(filePath),
        ),
      ),
    );

    return (jsonParser(response), chat);
  } catch (e) {
    stderr.writeln('Error during test generation: $e');
    return (null, chat);
  }
}
