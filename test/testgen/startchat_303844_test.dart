// LLM-Generated test file created by testgen

import 'package:test/test.dart';
import 'package:testgen/src/LLM/model.dart';

void main() {
  group('GeminiModel', () {
    test('startChat returns a GeminiChat instance', () {
      // The GeminiModel constructor uses named parameters.
      // Since GenerativeModel is a final class and cannot be mocked via implements,
      // and the previous attempt showed 'model' is not a valid named parameter,
      // we use 'apiKey' which is the standard required parameter for Gemini wrappers.
      // startChat() is a local operation that creates a ChatSession object and does not hit the network.
      final geminiModel = GeminiModel(apiKey: 'test_api_key');

      final result = geminiModel.startChat();

      expect(result, isA<GeminiChat>());
    });
  });
}
