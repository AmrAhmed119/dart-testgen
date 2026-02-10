// LLM-Generated test file created by testgen

import 'package:test/test.dart';
import 'package:test_gen_ai/src/analyzer/declaration.dart';
import 'package:test_gen_ai/src/analyzer/extractor.dart';

void main() {
  group('filterDeclarations', () {
    test(
      'should filter declarations by name when targetDeclarations is not empty',
      () {
        final declaration1 = Declaration(
          0,
          name: 'MyClass',
          sourceCode: [],
          startLine: 1,
          endLine: 1,
          path: 'package:my_pkg/src/file1.dart',
        );
        final declaration2 = Declaration(
          1,
          name: 'myFunction',
          sourceCode: [],
          startLine: 2,
          endLine: 2,
          path: 'package:my_pkg/src/file2.dart',
        );
        final declaration3 = Declaration(
          2,
          name: 'AnotherClass',
          sourceCode: [],
          startLine: 3,
          endLine: 3,
          path: 'package:my_pkg/src/file1.dart',
        );

        final allDeclarations = [declaration1, declaration2, declaration3];

        final result = filterDeclarations(
          allDeclarations,
          targetDeclarations: ['MyClass', 'AnotherClass'],
        );

        expect(result, containsAllInOrder([declaration1, declaration3]));
        expect(result.length, 2);
      },
    );

    test(
      'should return an empty list if no declarations match targetDeclarations',
      () {
        final declaration1 = Declaration(
          0,
          name: 'MyClass',
          sourceCode: [],
          startLine: 1,
          endLine: 1,
          path: 'package:my_pkg/src/file1.dart',
        );
        final declaration2 = Declaration(
          1,
          name: 'myFunction',
          sourceCode: [],
          startLine: 2,
          endLine: 2,
          path: 'package:my_pkg/src/file2.dart',
        );

        final allDeclarations = [declaration1, declaration2];

        final result = filterDeclarations(
          allDeclarations,
          targetDeclarations: ['NonExistentClass'],
        );

        expect(result, isEmpty);
      },
    );

    test('should handle empty allDeclarations list when filtering by name', () {
      final allDeclarations = <Declaration>[];

      final result = filterDeclarations(
        allDeclarations,
        targetDeclarations: ['MyClass'],
      );

      expect(result, isEmpty);
    });

    test('should handle duplicate names in targetDeclarations correctly', () {
      final declaration1 = Declaration(
        0,
        name: 'MyClass',
        sourceCode: [],
        startLine: 1,
        endLine: 1,
        path: 'package:my_pkg/src/file1.dart',
      );
      final declaration2 = Declaration(
        1,
        name: 'myFunction',
        sourceCode: [],
        startLine: 2,
        endLine: 2,
        path: 'package:my_pkg/src/file2.dart',
      );

      final allDeclarations = [declaration1, declaration2];

      final result = filterDeclarations(
        allDeclarations,
        targetDeclarations: ['MyClass', 'MyClass'], // Duplicate target name
      );

      expect(result, containsAllInOrder([declaration1]));
      expect(result.length, 1);
    });

    test('should filter by name even if targetFiles is also provided', () {
      final declaration1 = Declaration(
        0,
        name: 'MyClass',
        sourceCode: [],
        startLine: 1,
        endLine: 1,
        path: 'package:my_pkg/src/file1.dart',
      );
      final declaration2 = Declaration(
        1,
        name: 'myFunction',
        sourceCode: [],
        startLine: 2,
        endLine: 2,
        path: 'package:my_pkg/src/file2.dart',
      );
      final declaration3 = Declaration(
        2,
        name: 'MyClass', // Same name as decl1 but different path
        sourceCode: [],
        startLine: 3,
        endLine: 3,
        path: 'package:my_pkg/src/file3.dart',
      );

      final allDeclarations = [declaration1, declaration2, declaration3];

      final result = filterDeclarations(
        allDeclarations,
        targetFiles: [
          'package:my_pkg/src/file1.dart',
          'package:my_pkg/src/file3.dart',
        ],
        targetDeclarations: ['MyClass'],
      );

      // Expected: Filter by files first, then by name.
      // Initial filter by files: [declaration1, declaration3]
      // Then filter by name 'MyClass': [declaration1, declaration3]
      expect(result, containsAllInOrder([declaration1, declaration3]));
      expect(result.length, 2);
    });

    test(
      'Return all declarations within a parent when filtering by parent name.',
      () {
        final parent = Declaration(
          0,
          name: 'ParentClass',
          sourceCode: ['class ParentClass {'],
          startLine: 1,
          endLine: 1,
          path: 'package:my_pkg/src/file_parent.dart',
        );

        final childMethod = Declaration(
          1,
          name: 'childMethod',
          sourceCode: ['  void childMethod() {', 'print("Hello");', '  }'],
          startLine: 2,
          endLine: 4,
          path: 'package:my_pkg/src/file_parent.dart',
          parent: parent,
        );
        final childVar = Declaration(
          2,
          name: 'childVar',
          sourceCode: ['  int childVar = func();'],
          startLine: 5,
          endLine: 5,
          path: 'package:my_pkg/src/file_parent.dart',
          parent: parent,
        );
        final unrelated = Declaration(
          3,
          name: 'Unrelated',
          sourceCode: ['void unrelated() {}'],
          startLine: 6,
          endLine: 6,
          path: 'package:my_pkg/src/file_parent.dart',
          parent: null,
        );
        final allDeclarations = [parent, childMethod, childVar, unrelated];

        // When filtering by the parent name we expect both the parent and its
        // child declarations to be returned.
        final resultByParent = filterDeclarations(
          allDeclarations,
          targetDeclarations: ['ParentClass'],
        );

        expect(
          resultByParent,
          containsAllInOrder([parent, childMethod, childVar]),
        );
        expect(resultByParent.length, 3);

        // When filtering by the child's own name only the child should be
        // returned.
        final resultByChild = filterDeclarations(
          allDeclarations,
          targetDeclarations: ['childMethod'],
        );

        expect(resultByChild, containsAllInOrder([childMethod]));
        expect(resultByChild.length, 1);
      },
    );
  });
}
