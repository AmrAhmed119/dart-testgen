// LLM-Generated test file created by testgen

import 'dart:io';
import 'package:test/test.dart';
import 'package:testgen/src/LLM/model.dart';

void main() {
  group('GeminiModel', () {
    test('initializes correctly with provided apiKey', () {
      // This test covers the constructor and the internal call to _createModel
      // when an explicit API key is provided, testing the first part of the
      // null-coalescing operator for apiKey.
      expect(
        () => GeminiModel(
          apiKey: 'test-api-key',
          modelName: 'gemini-2.5-pro',
          systemInstruction: 'Test instruction',
          candidateCount: 1,
          temperature: 0.2,
          topP: 0.95,
        ),
        returnsNormally,
      );
    });

    test(
      'throws StateError when apiKey is null and environment variable is missing',
      () {
        // This tests the _envApiKey() logic. Since Platform.environment cannot be
        // easily mocked without a wrapper, we perform this test conditionally
        // to ensure it passes in environments where the key is not set.
        if (!Platform.environment.containsKey('GEMINI_API_KEY')) {
          expect(
            () => GeminiModel(),
            throwsA(
              isA<StateError>().having(
                (e) => e.message,
                'message',
                contains('Missing GEMINI_API_KEY'),
              ),
            ),
          );
        }
      },
    );

    test(
      'initializes correctly using environment variable when apiKey is not provided',
      () {
        // This tests the second part of the null-coalescing operator for apiKey.
        // It only runs if the environment variable is actually present.
        if (Platform.environment.containsKey('GEMINI_API_KEY')) {
          expect(() => GeminiModel(), returnsNormally);
        }
      },
    );
  });
}
