import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:testgen/src/LLM/model.dart';

@GenerateNiceMocks([MockSpec<GeminiChat>()])
import 'sample_mock_test.mocks.dart';

void main() {
  test('Test mocking chat response', () {
    final mockChat = MockGeminiChat();

    when(mockChat.sendMessage(any)).thenAnswer(
      (_) async => ChatResponse(
        code: 'void main() { print("Hello, World!"); }',
        needTesting: true,
      ),
    );

    final response = mockChat.sendMessage('Generate Dart code');

    verify(mockChat.sendMessage(any)).called(1);

    expect(
      response,
      completion(
        isA<ChatResponse>()
            .having(
              (r) => r.code,
              'code',
              'void main() { print("Hello, World!"); }',
            )
            .having((r) => r.needTesting, 'needTesting', true),
      ),
    );
  });
}
