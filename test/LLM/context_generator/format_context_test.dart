import 'package:test/test.dart';
import 'package:testgen/src/LLM/context_generator.dart';

import '../../utils.dart';

void main() {
  final pathA = 'package:pkg/src/a.dart';
  final pathB = 'package:pkg/src/b.dart';

  final funcCode = ['int func(int x) {', '  return x + 1;', '}'];
  final varCode = ['int a = 1;'];

  group('Context code formatter output', () {
    test('formats a parent entry with multiple children', () {
      final parent = sampleDecl(1, path: pathA, sourceCode: ['class Parent {']);
      final c1 = sampleDecl(2, path: pathA, sourceCode: varCode);
      final c2 = sampleDecl(3, path: pathA, sourceCode: funcCode);
      final c3 = sampleDecl(4, path: pathA, sourceCode: ['Parent(this.a);']);

      final formattedCode = formatContext({
        parent: [c1, c2, c3],
      });

      expect(
        formattedCode,
        equals('''
// Code Snippet package path: package:pkg/src/a.dart
class Parent {
  // rest of the code...

int a = 1;

int func(int x) {
  return x + 1;
}

Parent(this.a);

  // rest of the code...
}
'''),
      );
    });

    test('empty map returns empty string', () {
      final formattedCode = formatContext({});

      expect(formattedCode, isNotNull);
      expect(formattedCode, isEmpty);
    });

    test('null group single child with brace adds closing hint', () {
      final parent = sampleDecl(
        1,
        path: pathA,
        sourceCode: ['class Parent extends Person {'],
      );
      final person = sampleDecl(2, path: pathB, sourceCode: ['class Person {']);
      final formattedCode = formatContext({
        null: [parent, person],
      });

      expect(
        formattedCode,
        equals('''
// Code Snippet package path: package:pkg/src/a.dart
class Parent extends Person { ... }

// Code Snippet package path: package:pkg/src/b.dart
class Person { ... }
'''),
      );
    });

    test('null group multiple children adds blank line between children', () {
      final c1 = sampleDecl(1, path: pathA, sourceCode: varCode);
      final c2 = sampleDecl(2, path: pathB, sourceCode: funcCode);
      final c3 = sampleDecl(
        3,
        path: pathB,
        sourceCode: ['/// parent class comment', 'class Parent {'],
      );
      final formattedCode = formatContext({
        null: [c1, c2, c3],
      });

      expect(
        formattedCode,
        equals('''
// Code Snippet package path: package:pkg/src/a.dart
int a = 1;

// Code Snippet package path: package:pkg/src/b.dart
int func(int x) {
  return x + 1;
}

// Code Snippet package path: package:pkg/src/b.dart
/// parent class comment
class Parent { ... }
'''),
      );
    });

    test('multiple entries preserve insertion order and separate blocks', () {
      final parent = sampleDecl(
        1,
        path: pathA,
        sourceCode: ['class Parent extends Person {'],
      );
      final person = sampleDecl(
        2,
        path: pathB,
        sourceCode: ['/// person class comment', 'class Person {'],
      );
      final foo = sampleDecl(
        3,
        path: pathB,
        sourceCode: [
          '/// foo class comment',
          '/// another comment',
          'class Foo {',
        ],
      );
      final c1 = sampleDecl(4, path: pathA, sourceCode: varCode);
      final c2 = sampleDecl(5, path: pathA, sourceCode: funcCode);

      final formattedCode = formatContext({
        parent: [c1, c2],
        person: [c1, c2],
        null: [c1, c2, foo],
      });

      expect(
        formattedCode,
        equals('''
// Code Snippet package path: package:pkg/src/a.dart
class Parent extends Person {
  // rest of the code...

int a = 1;

int func(int x) {
  return x + 1;
}

  // rest of the code...
}

// Code Snippet package path: package:pkg/src/b.dart
/// person class comment
class Person {
  // rest of the code...

int a = 1;

int func(int x) {
  return x + 1;
}

  // rest of the code...
}

// Code Snippet package path: package:pkg/src/a.dart
int a = 1;

// Code Snippet package path: package:pkg/src/a.dart
int func(int x) {
  return x + 1;
}

// Code Snippet package path: package:pkg/src/b.dart
/// foo class comment
/// another comment
class Foo { ... }
'''),
      );
    });
  });
}
