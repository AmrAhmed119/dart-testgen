// LLM-Generated test file created by testgen

import 'package:test/test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:testgen/src/LLM/model.dart';

void main() {
  group('GeminiChat', () {
    test('history returns the history from the underlying ChatSession', () {
      // Since ChatSession is a final class, it cannot be mocked using 'implements'.
      // We use a real instance of ChatSession created via a GenerativeModel.
      // This allows us to test the delegation without violating final class restrictions.
      final model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: 'unused-api-key',
      );

      final mockHistory = [
        Content.text('Hello'),
        Content.model([TextPart('Hi there!')]),
      ];

      // Create a real ChatSession with the desired history.
      final chatSession = model.startChat(history: mockHistory);

      // Initialize the wrapper with the real session.
      // Based on the context, GeminiChat wraps a ChatSession.
      final geminiChat = GeminiChat(chatSession);

      // Act
      final result = geminiChat.history;

      // Assert
      expect(result, equals(mockHistory));
    });
  });
}
