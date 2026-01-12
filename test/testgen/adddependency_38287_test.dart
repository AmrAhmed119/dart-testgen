// LLM-Generated test file created by testgen

import 'package:test/test.dart';
import 'package:testgen/src/analyzer/declaration.dart';

void main() {
  group('Declaration', () {
    test(
      'addDependency throws ArgumentError when adding a dependency with the same id',
      () {
        const id = 123;
        const name = 'testDeclaration';
        final declaration = Declaration(
          id,
          name: name,
          sourceCode: ['void test() {}'],
          startLine: 1,
          endLine: 1,
          path: 'test.dart',
        );

        expect(
          () => declaration.addDependency(declaration),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              'A declaration cannot depend on itself (id: $id, name: $name)',
            ),
          ),
        );
      },
    );
  });
}
