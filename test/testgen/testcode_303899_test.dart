// LLM-Generated test file created by testgen

import 'package:test/test.dart';
import 'package:testgen/src/LLM/prompt_generator.dart';

void main() {
  group('PromptGenerator', () {
    late PromptGenerator generator;

    setUp(() {
      generator = PromptGenerator();
    });

    test(
      'testCode should generate prompt without context section when contextCode is empty',
      () {
        final toBeTestedCode = 'void myFunc() {}';
        final result = generator.testCode(toBeTestedCode, '');

        expect(
          result,
          contains('Generate a Dart test cases for the following code:'),
        );
        expect(result, contains('```dart\n$toBeTestedCode\n```'));
        expect(result, isNot(contains('With the following context:')));
        expect(result, contains('Requirements:'));
        expect(
          result,
          contains('- Test ONLY the lines marked with `// UNTESTED`'),
        );
      },
    );

    test(
      'testCode should generate prompt with context section when contextCode is provided',
      () {
        final toBeTestedCode = 'void myFunc() {}';
        final contextCode = 'class MyClass {}';
        final result = generator.testCode(toBeTestedCode, contextCode);

        expect(
          result,
          contains('Generate a Dart test cases for the following code:'),
        );
        expect(result, contains('```dart\n$toBeTestedCode\n```'));
        expect(result, contains('With the following context:'));
        expect(result, contains('```dart\n$contextCode\n```'));
        expect(result, contains('Requirements:'));
      },
    );

    test('testCode should handle whitespace-only contextCode as empty', () {
      final toBeTestedCode = 'void myFunc() {}';
      final result = generator.testCode(toBeTestedCode, '   \n  ');

      expect(result, isNot(contains('With the following context:')));
    });
  });
}
