// LLM-Generated test file created by testgen

import 'package:test/test.dart';
import 'package:test_gen_ai/src/LLM/prompt_generator.dart';

void main() {
  group('PromptGenerator', () {
    late PromptGenerator promptGenerator;

    setUp(() {
      promptGenerator = PromptGenerator();
    });

    test('testCode includes helper tests when provided', () {
      final toBeTestedCode = 'void main() {}';
      final contextCode = 'class A {}';
      final helperTestsCode = ['test("h1", () {});', 'test("h2", () {});'];

      final result = promptGenerator.testCode(
        toBeTestedCode,
        contextCode,
        helperTestsCode: helperTestsCode,
      );

      expect(
        result,
        contains(
          'Also use the following existing tests as examples (few-shot):',
        ),
      );
      expect(result, contains('test("h1", () {});'));
      expect(result, contains('test("h2", () {});'));
    });

    test(
      'testCode does not include helper tests section when helperTestsCode is null',
      () {
        final result = promptGenerator.testCode(
          'code',
          'context',
          helperTestsCode: null,
        );
        expect(
          result,
          isNot(
            contains(
              'Also use the following existing tests as examples (few-shot):',
            ),
          ),
        );
      },
    );

    test(
      'testCode does not include helper tests section when helperTestsCode is empty',
      () {
        final result = promptGenerator.testCode(
          'code',
          'context',
          helperTestsCode: [],
        );
        expect(
          result,
          isNot(
            contains(
              'Also use the following existing tests as examples (few-shot):',
            ),
          ),
        );
      },
    );
  });
}
