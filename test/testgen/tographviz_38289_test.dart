// LLM-Generated test file created by testgen

import 'package:test/test.dart';
import 'package:test_gen_ai/src/analyzer/declaration.dart';

void main() {
  group('Declaration.toGraphviz', () {
    test(
      'should generate correct DOT format for a single declaration without dependencies',
      () {
        final declaration = Declaration(
          101,
          name: 'myFunction',
          sourceCode: ['void myFunction() {}'],
          startLine: 10,
          endLine: 15,
          path: 'package:test_gen_ai/src/analyzer/declaration.dart',
        );

        final result = declaration.toGraphviz();

        // Check for the node definition with correct label and styling
        // Note: \\n in the expectation matches the literal \n in the generated string
        expect(
          result,
          contains(
            'decl_101 [label="myFunction\\n(10:15)", shape=box, fillcolor=lightblue, style=filled];',
          ),
        );
      },
    );

    test('should escape double quotes in the declaration name', () {
      final declaration = Declaration(
        202,
        name: 'my "quoted" name',
        sourceCode: ['void "quoted"() {}'],
        startLine: 1,
        endLine: 2,
        path: 'package:test_gen_ai/src/analyzer/declaration.dart',
      );

      final result = declaration.toGraphviz();

      // The name.replaceAll('"', '\\"') results in a literal backslash before the quote
      // The \\n in the code results in a literal \n in the output string
      expect(result, contains('label="my \\"quoted\\" name\\n(1:2)"'));
    });

    test(
      'should generate dependency edges for each declaration in dependsOn',
      () {
        final mainDecl = Declaration(
          1,
          name: 'main',
          sourceCode: ['void main() {}'],
          startLine: 1,
          endLine: 10,
          path: 'package:test_gen_ai/src/analyzer/declaration.dart',
        );
        final dep1 = Declaration(
          2,
          name: 'dep1',
          sourceCode: ['void dep1() {}'],
          startLine: 11,
          endLine: 15,
          path: 'package:test_gen_ai/src/analyzer/declaration.dart',
        );
        final dep2 = Declaration(
          3,
          name: 'dep2',
          sourceCode: ['void dep2() {}'],
          startLine: 16,
          endLine: 20,
          path: 'package:test_gen_ai/src/analyzer/declaration.dart',
        );

        mainDecl.dependsOn.add(dep1);
        mainDecl.dependsOn.add(dep2);

        final result = mainDecl.toGraphviz();

        // Verify that edges are created from the main declaration to its dependencies
        expect(result, contains('  decl_1 -> decl_2;'));
        expect(result, contains('  decl_1 -> decl_3;'));
      },
    );

    test('should handle empty dependsOn set gracefully', () {
      final declaration = Declaration(
        5,
        name: 'leaf',
        sourceCode: ['void leaf() {}'],
        startLine: 1,
        endLine: 1,
        path: 'package:test_gen_ai/src/analyzer/declaration.dart',
      );

      final result = declaration.toGraphviz();

      // Should contain the node definition but no edge arrows
      expect(result, contains('decl_5'));
      expect(result, isNot(contains('->')));
    });
  });
}
