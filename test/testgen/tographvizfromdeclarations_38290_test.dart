// LLM-Generated test file created by testgen

import 'package:test/test.dart';
import 'package:test_gen_ai/src/analyzer/declaration.dart';

void main() {
  group('Declaration.toGraphvizFromDeclarations', () {
    test('should generate a complete DOT graph with default values', () {
      final decl1 = Declaration(
        1,
        name: 'funcA',
        sourceCode: ['void funcA() {}'],
        startLine: 10,
        endLine: 12,
        path: 'lib/a.dart',
      );
      final decl2 = Declaration(
        2,
        name: 'funcB',
        sourceCode: ['void funcB() {}'],
        startLine: 20,
        endLine: 22,
        path: 'lib/b.dart',
      );

      // Add dependency to test edge generation
      decl1.dependsOn.add(decl2);

      final dotOutput = Declaration.toGraphvizFromDeclarations([decl1, decl2]);

      // Verify graph header
      expect(dotOutput, contains('digraph G {'));
      expect(dotOutput, contains('rankdir=LR;'));
      expect(dotOutput, contains('label="Declaration Dependencies";'));
      expect(dotOutput, contains('labelloc=t;'));
      expect(dotOutput, contains('fontsize=16;'));

      // Verify node definitions (checking for escaped newline in label)
      expect(dotOutput, contains('decl_1 [label="funcA\\n(10:12)"'));
      expect(dotOutput, contains('decl_2 [label="funcB\\n(20:22)"'));

      // Verify edges
      expect(dotOutput, contains('decl_1 -> decl_2;'));

      // Verify footer
      expect(dotOutput.trim(), endsWith('}'));
    });

    test('should respect custom title and rankdir parameters', () {
      final dotOutput = Declaration.toGraphvizFromDeclarations(
        [],
        title: 'Custom Dependency Graph',
        rankdir: 'TB',
      );

      expect(dotOutput, contains('rankdir=TB;'));
      expect(dotOutput, contains('label="Custom Dependency Graph";'));
    });

    test('should handle an empty list of declarations gracefully', () {
      final dotOutput = Declaration.toGraphvizFromDeclarations([]);

      expect(dotOutput, contains('digraph G {'));
      expect(dotOutput, contains('rankdir=LR;'));
      expect(dotOutput, contains('}'));
      // Should not contain any node identifiers
      expect(dotOutput, isNot(contains('decl_')));
    });
  });
}
