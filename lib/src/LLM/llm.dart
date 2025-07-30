import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';
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
///     - 'gemini-2.5-flash'
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
        description: 'true or false denoting if the file need test or not',
        nullable: false,
      ),
      'comments': Schema.string(
        description: 'Comments from the model about the generation process.',
        nullable: true,
      ),
    },
    requiredProperties: ['code'],
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

Future<LLMResponse?> generateTest(GenerativeModel model, String prompt) async {
  final chat = model.startChat();

  try {
    final response = await chat.sendMessage(Content.text(prompt));
    Future.delayed(const Duration(seconds: 3));
    if (response.text == null) {
      throw Exception('No response text received from the model.');
    }

    final json = jsonDecode(response.text!);
    return LLMResponse(
      code: json['code'],
      chatSession: chat,
      comments: json['comments'] ?? '',
    );
  } catch (e) {
    stderr.writeln('Error during test generation: $e');
    return null;
  }
}
