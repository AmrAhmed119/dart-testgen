import 'dart:convert';
import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';

/// A wrapper around the Gemini [GenerativeModel] for creating, configuring,
/// and interacting with Gemini model.
class GeminiModel {
  GeminiModel({
    String modelName = 'gemini-2.5-pro',
    String? apiKey,
    String systemInstruction =
        'You are a code assistant that generates Dart test '
        'cases based on provided code snippets.',
    int candidateCount = 1,
    double temperature = 0.2,
    double topP = 0.95,
  }) {
    _model = _createModel(
      modelName: modelName,
      apiKey: apiKey ?? _envApiKey(),
      systemInstruction: Content.system(systemInstruction),
      candidateCount: candidateCount,
      temperature: temperature,
      topP: topP,
    );
  }

  late final GenerativeModel _model;

  String _envApiKey() {
    final apiKey = Platform.environment['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw StateError('Missing GEMINI_API_KEY environment variable.');
    }
    return apiKey;
  }

  GenerativeModel _createModel({
    required String modelName,
    required String apiKey,
    required Content systemInstruction,
    required int candidateCount,
    required double temperature,
    required double topP,
  }) {
    final schema = Schema.object(
      description: 'Schema for generated Dart test cases.',
      properties: {
        'code': Schema.string(
          description: 'Generated Dart test code.',
          nullable: false,
        ),
        'needTesting': Schema.boolean(
          description:
              'True only if the code snippet can be usefully tested. '
              'False for trivial getters/setters, data classes, or asserts '
              'that do not make sense to test.',
          nullable: false,
        ),
      },
      requiredProperties: ['code', 'needTesting'],
    );

    return GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      systemInstruction: systemInstruction,
      generationConfig: GenerationConfig(
        candidateCount: candidateCount,
        temperature: temperature,
        topP: topP,
        responseMimeType: 'application/json',
        responseSchema: schema,
      ),
    );
  }

  /// Starts a new chat session with Gemini by creating a new [GeminiChat].
  GeminiChat startChat() {
    final chatSession = _model.startChat();
    return GeminiChat(chatSession);
  }

  /// Returns the total token count for the given [chat] history.
  ///
  /// If token counting fails (e.g., network error), this method returns `0`.
  Future<int> countTokens(GeminiChat chat) async => _model
      .countTokens(chat.history)
      .then((r) => r.totalTokens)
      .catchError((_) => 0);
}

/// A wrapper around the Gemini [ChatSession].
class GeminiChat {
  GeminiChat(this._chat);

  final ChatSession _chat;

  /// The full chat history for use with token counting or debugging.
  Iterable<Content> get history => _chat.history;

  /// Sends a new message to the model and returns the parsed [ChatResponse].
  Future<ChatResponse> sendMessage(String content) async {
    final response = await _chat.sendMessage(Content.text(content));
    return ChatResponse.fromText(response);
  }
}

/// Represents a parsed response from Gemini model chat.
///
/// Contains the generated Dart test [code] and a boolean [needTesting] that
/// indicates whether the model determined the input actually requires tests.
class ChatResponse {
  ChatResponse({required this.code, required this.needTesting});

  final String code;
  final bool needTesting;

  /// Parses a JSON text response from the model into a [ChatResponse].
  ///
  /// Throws [FormatException] if the response contains no text or if the
  /// text cannot be parsed as the expected JSON schema.
  factory ChatResponse.fromText(GenerateContentResponse response) {
    if (response.text == null) {
      throw FormatException(
        'Model returned no text in GenerateContentResponse.',
      );
    }

    try {
      final json = jsonDecode(response.text!) as Map<String, dynamic>;

      return ChatResponse(
        code: json['code'] as String,
        needTesting: json['needTesting'] as bool,
      );
    } catch (e) {
      throw FormatException(
        'Failed to parse model response as JSON: ${response.text}',
      );
    }
  }
}
