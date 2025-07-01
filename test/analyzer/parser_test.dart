import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:test/test.dart';
import 'package:testgen/src/analyzer/parser.dart';

void main() {
  group('parseCompilationUnit', () {
    test('parses top-level variable declaration', () {
      const source = '''
/// mutli variable declaration
int a = 5, b = 10;
''';

      final unit = parseString(content: source).unit;
      final declarations = parseCompilationUnit(unit, 'test_file.dart');

      expect(declarations.length, 2);
      expect(declarations[0].name, 'a');
      expect(declarations[1].name, 'b');
      expect(declarations[0].path, 'test_file.dart');
      expect(declarations[0].startLine, 1);
      expect(declarations[0].endLine, 2);
      expect(declarations[0].comment, '/// mutli variable declaration');
      expect(declarations[1].comment, '/// mutli variable declaration');
    });

    test('parses class with methods and fields', () {
      const source = '''
/// Class Definition for [Person]
/// Multi line comment
class Person {

  /// The name of the person
  String name;
  
  /// Constructor for Person
  Person.named(this.name);

  /// Greet the person
  void greet() {
    print('Hello \$name');
  }
}
''';

      final unit = parseString(content: source).unit;
      final declarations = parseCompilationUnit(unit, 'test_file.dart');

      expect(declarations.length, 4); // class + field + constructor + method

      final classDecl = declarations.first;
      expect(classDecl.name, 'Person');
      expect(classDecl.startLine, 1);
      expect(classDecl.endLine, 15);
      expect(
        classDecl.comment,
        '/// Class Definition for [Person]\n/// Multi line comment',
      );

      final field = declarations.firstWhere((d) => d.name == 'name');
      final method = declarations.firstWhere((d) => d.name == 'greet');
      final constructor = declarations.firstWhere(
        (d) => d.name == 'Person.named',
      );

      expect(field.parent, classDecl);
      expect(field.startLine, 5);
      expect(field.endLine, 6);
      expect(field.comment, '/// The name of the person');

      expect(constructor.parent, classDecl);
      expect(constructor.startLine, 8);
      expect(constructor.endLine, 9);
      expect(constructor.comment, '/// Constructor for Person');

      expect(method.parent, classDecl);
      expect(method.startLine, 11);
      expect(method.endLine, 14);
      expect(method.comment, '/// Greet the person');
    });

    test('parses top-level function', () {
      const source = '''
/// comment above annotation
@Deprecated('Use sum instead')
int sum(int x, int y) => x + y;
''';

      final unit = parseString(content: source).unit;
      final declarations = parseCompilationUnit(unit, 'test_file.dart');

      expect(declarations.length, 1);
      final func = declarations.first;

      expect(func.name, 'sum');
      expect(func.path, 'test_file.dart');
      expect(
        func.sourceCode,
        '@Deprecated(\'Use sum instead\') int sum(int x, int y) => x + y;',
      );
      expect(func.startLine, 1);
      expect(func.endLine, 3);
      expect(func.comment, '/// comment above annotation');
    });
  });
}
