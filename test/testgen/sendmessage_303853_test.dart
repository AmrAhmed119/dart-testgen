// LLM-Generated test file created by testgen

import 'dart:convert';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:testgen/src/LLM/model.dart';

/// A fake HTTP client to intercept requests from the GenerativeModel.
/// This avoids the need to mock final classes like ChatSession or GenerativeModel.
class FakeHttpClient extends Fake implements http.Client {
  Future<http.Response> Function(
    Uri, {
    Map<String, String>? headers,
    Object? body,
  })?
  onPost;

  @override
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    if (onPost != null) return onPost!(url, headers: headers, body: body);
    return Future.value(http.Response('Not Found', 404));
  }
}

void main() {
  group('GeminiChat.sendMessage', () {
    late FakeHttpClient fakeClient;
    late GeminiChat geminiChat;

    setUp(() {
      fakeClient = FakeHttpClient();
      // We use the real GenerativeModel and ChatSession but control the transport layer.
      final model = GenerativeModel(
        model: 'gemini-pro',
        apiKey: 'test-key',
        httpClient: fakeClient,
      );
      final session = model.startChat();

      // Assuming GeminiChat has a constructor that allows injecting the ChatSession.
      // Based on the snippet provided, _chat is a final field.
      geminiChat = GeminiChat(session);
    });

    test(
      'should send message and return a parsed ChatResponse on success',
      () async {
        const testContent = 'Generate a test for this code';
        const expectedCode = 'void main() { print("test"); }';

        final responseData = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'code': expectedCode,
                      'needTesting': true,
                    }),
                  },
                ],
              },
            },
          ],
        };

        fakeClient.onPost = (url, {headers, body}) async {
          return http.Response(jsonEncode(responseData), 200);
        };

        final result = await geminiChat.sendMessage(testContent);

        expect(result.code, equals(expectedCode));
        expect(result.needTesting, isTrue);
      },
    );

    test(
      'should throw FormatException when the model returns invalid JSON',
      () async {
        final responseData = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': 'This is not JSON'},
                ],
              },
            },
          ],
        };

        fakeClient.onPost = (url, {headers, body}) async {
          return http.Response(jsonEncode(responseData), 200);
        };

        expect(
          () => geminiChat.sendMessage('test'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Failed to parse model response as JSON'),
            ),
          ),
        );
      },
    );

    test(
      'should throw FormatException when the model returns no text',
      () async {
        final responseData = {
          'candidates': [
            {
              'content': {
                'parts': [], // No text part
              },
            },
          ],
        };

        fakeClient.onPost = (url, {headers, body}) async {
          return http.Response(jsonEncode(responseData), 200);
        };

        expect(
          () => geminiChat.sendMessage('test'),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('Model returned no text'),
            ),
          ),
        );
      },
    );
  });
}
