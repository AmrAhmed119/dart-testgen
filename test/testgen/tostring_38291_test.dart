// LLM-Generated test file created by testgen

import 'package:test/test.dart';
import 'package:testgen/src/analyzer/declaration.dart';

void main() {
  group('Declaration.toString', () {
    test(
      'should return a correctly formatted string representation with all fields',
      () {
        final parent = Declaration(
          10,
          name: 'ParentClass',
          sourceCode: ['class ParentClass {}'],
          startLine: 1,
          endLine: 10,
          path: 'package:test/file.dart',
        );

        final dependency = Declaration(
          20,
          name: 'depFunc',
          sourceCode: ['void depFunc() {}'],
          startLine: 15,
          endLine: 17,
          path: 'package:test/file.dart',
        );

        final declaration = Declaration(
          42,
          name: 'myMethod',
          sourceCode: ['void myMethod() {}'],
          startLine: 5,
          endLine: 7,
          path: 'package:test/file.dart',
          parent: parent,
        );
        declaration.dependsOn.add(dependency);

        final output = declaration.toString();

        expect(output, contains('id: 42'));
        expect(output, contains('name: myMethod'));
        expect(output, contains('path: package:test/file.dart'));
        expect(output, contains('sourceCode: [void myMethod() {}]'));
        expect(output, contains('startLine: 5'));
        expect(output, contains('endLine: 7'));
        expect(output, contains('parent: ParentClass'));
        expect(output, contains('dependsOn: [depFunc_20]'));
      },
    );

    test(
      'should handle null parent and empty dependencies in string representation',
      () {
        final declaration = Declaration(
          42,
          name: 'myMethod',
          sourceCode: [],
          startLine: 5,
          endLine: 7,
          path: 'package:test/file.dart',
        );

        final output = declaration.toString();

        expect(output, contains('parent: null'));
        expect(output, contains('dependsOn: []'));
      },
    );
  });
}
