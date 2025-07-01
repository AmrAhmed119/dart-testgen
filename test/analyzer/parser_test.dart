import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:test/test.dart';
import 'package:testgen/src/analyzer/parser.dart';

void main() {
  group('parseCompilationUnit', () {
    test('parses top-level variable declaration', () {
      const source = '''
int a = 5, b = 10;
''';

      final unit = parseString(content: source).unit;
      final declarations = parseCompilationUnit(unit, 'test_file.dart');

      expect(declarations.length, 2);
      expect(declarations[0].name, 'a');
      expect(declarations[1].name, 'b');
      expect(declarations[0].path, 'test_file.dart');
      expect(declarations[0].startLine, 1);
      expect(declarations[0].endLine, 1);
    });

    test('parses class with methods and fields', () {
      const source = '''
class Person {
  String name;
  
  Person(this.name);

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

      final field = declarations.firstWhere((d) => d.name == 'name');
      final method = declarations.firstWhere((d) => d.name == 'greet');
      expect(field.parent, classDecl);
      expect(method.parent, classDecl);

      expect(method.startLine, 6);
      expect(method.endLine, 8);
    });

    test('parses top-level function', () {
      const source = '''
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
      expect(func.endLine, 2);
    });
  });
}
