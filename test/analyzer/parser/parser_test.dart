import 'package:test/test.dart';
import 'package:testgen/src/analyzer/declaration.dart';
import 'package:path/path.dart' as path;

import '../utils.dart';

void main() {
  late Map<String, Declaration> decls;

  setUpAll(() async {
    decls = await extractDeclarationsForSourceFile(
      path.join('test', 'analyzer', 'parser', 'code.dart'),
      [
        'a',
        'b',
        'StringExtension',
        'reversed',
        'Logger',
        'log',
        'Status',
        'code',
        'describe',
        'pending',
        'approved',
        'rejected',
        'IntCallback',
        'Mapper',
        'UserID',
        'isValid',
        'getUser',
        'Person',
        'Another',
        'name',
        'Person.named',
        'greet',
        'sum',
      ],
    );
  });

  group('parseCompilationUnit', () {
    test('parses top-level variable declaration', () {
      final a = decls['a']!;
      final b = decls['b']!;

      expect(a.name, 'a');
      expect(a.sourceCode, [
        '/// mutli variable declaration',
        'int a = 5, b = 10;',
      ]);
      expect(a.startLine, 1);
      expect(a.endLine, 2);
      expect(a.parent, null);

      expect(b.name, 'b');
      expect(b.sourceCode, [
        '/// mutli variable declaration',
        'int a = 5, b = 10;',
      ]);
      expect(b.startLine, 1);
      expect(b.endLine, 2);
      expect(b.parent, null);
    });

    test('parses extension declaration', () {
      final ext = decls['StringExtension']!;
      final method = decls['reversed']!;

      expect(ext.name, 'StringExtension');
      expect(ext.sourceCode, ['extension StringExtension on String {']);
      expect(ext.startLine, 4);
      expect(ext.endLine, 4);
      expect(ext.parent, null);

      expect(method.name, 'reversed');
      expect(method.startLine, 5);
      expect(method.endLine, 5);
      expect(method.sourceCode, [
        "String reversed() => split('').reversed.join();",
      ]);
      expect(method.parent, ext);
    });

    test('parses mixin declaration', () {
      final mixin = decls['Logger']!;
      final method = decls['log']!;

      expect(mixin.name, 'Logger');
      expect(mixin.sourceCode, ['mixin Logger {']);
      expect(mixin.startLine, 8);
      expect(mixin.endLine, 8);
      expect(mixin.parent, null);

      expect(method.name, 'log');
      expect(method.sourceCode, [
        "void log(String message) => print('Log: new Log');",
      ]);
      expect(method.startLine, 9);
      expect(method.endLine, 9);
      expect(method.parent, mixin);
    });

    test('parses enum declaration', () {
      final enumDecl = decls['Status']!;
      final field = decls['code']!;
      final method = decls['describe']!;
      final constants = [
        decls['pending']!,
        decls['approved']!,
        decls['rejected']!,
      ];

      // 3 constants + 1 field + 1 constructor + 1 method
      expect(
        decls.values.where((d) => d.parent == enumDecl || d == enumDecl),
        hasLength(6),
      );

      expect(enumDecl.startLine, 12);
      expect(enumDecl.endLine, 12);

      expect(constants[0].name, 'pending');
      expect(constants[0].startLine, 13);
      expect(constants[0].endLine, 13);
      expect(constants[0].parent, enumDecl);

      expect(constants[1].name, 'approved');
      expect(constants[1].startLine, 14);
      expect(constants[1].endLine, 14);
      expect(constants[1].parent, enumDecl);

      expect(constants[2].name, 'rejected');
      expect(constants[2].startLine, 15);
      expect(constants[2].endLine, 15);
      expect(constants[2].parent, enumDecl);

      expect(field.name, 'code');
      expect(field.sourceCode, ['final int code;']);
      expect(field.startLine, 17);
      expect(field.endLine, 17);
      expect(field.parent, enumDecl);

      expect(method.name, 'describe');
      expect(method.sourceCode, [
        "void describe() {",
        "    print('Status: \$name with code \$code');",
        '  }',
      ]);
      expect(method.startLine, 21);
      expect(method.endLine, 23);
      expect(method.parent, enumDecl);
    });

    test('parses typedef declaration', () {
      final callbackDef = decls['IntCallback']!;
      final genericDef = decls['Mapper']!;

      expect(callbackDef.name, 'IntCallback');
      expect(callbackDef.sourceCode, [
        '/// A typedef for a callback that takes an int and returns an int.',
        '/// This is a multi-line comment.',
        'typedef IntCallback = int Function(int);',
      ]);
      expect(callbackDef.startLine, 26);
      expect(callbackDef.endLine, 28);
      expect(callbackDef.parent, null);

      expect(genericDef.name, 'Mapper');
      expect(genericDef.sourceCode, [
        '/// generic typedef',
        'typedef Mapper<T> = T Function(T value);',
      ]);
      expect(genericDef.startLine, 30);
      expect(genericDef.endLine, 31);
      expect(genericDef.parent, null);
    });

    test('parses extension type declaration', () {
      final extType = decls['UserID']!;
      final getter = decls['isValid']!;
      final method = decls['getUser']!;

      expect(extType.name, 'UserID');
      expect(extType.sourceCode, [
        '/// Test comment',
        'extension type UserID(int id) {',
      ]);
      expect(extType.startLine, 33);
      expect(extType.endLine, 34);
      expect(extType.parent, null);

      expect(getter.name, 'isValid');
      expect(getter.startLine, 35);
      expect(getter.endLine, 35);
      expect(getter.parent, extType);

      expect(method.name, 'getUser');
      expect(method.startLine, 37);
      expect(method.endLine, 38);
      expect(method.parent, extType);
    });

    test('parses class declaration', () {
      final classDecl = decls['Person']!;
      final field = decls['name']!;
      final constructor = decls['Person.named']!;
      final method = decls['greet']!;

      expect(classDecl.name, 'Person');
      expect(classDecl.sourceCode, [
        '/// Class Definition for [Person]',
        '/// Multi line comment',
        'class Person extends Another with Logger {',
      ]);
      expect(classDecl.startLine, 41);
      expect(classDecl.endLine, 43);
      expect(classDecl.parent, null);

      expect(field.name, 'name');
      expect(field.startLine, 44);
      expect(field.endLine, 45);
      expect(field.parent, classDecl);

      expect(constructor.name, 'Person.named');
      expect(constructor.sourceCode, [
        '/// Constructor for Person',
        '  Person.named(this.name);',
      ]);
      expect(constructor.startLine, 47);
      expect(constructor.endLine, 48);
      expect(constructor.parent, classDecl);

      expect(method.name, 'greet');
      expect(method.startLine, 50);
      expect(method.endLine, 53);
      expect(method.parent, classDecl);
    });

    test('parses top-level function', () {
      final func = decls['sum']!;

      expect(func.name, 'sum');
      expect(func.sourceCode, [
        '/// comment above annotation',
        "@Deprecated('Use sum instead')",
        'int sum(int x, int y) => x + y;',
      ]);
      expect(func.startLine, 58);
      expect(func.endLine, 60);
      expect(func.parent, null);
    });

    test('each declaration has a unique id', () {
      final ids = decls.values.map((d) => d.id).toSet();
      expect(
        ids.length,
        decls.length,
        reason: 'Each declaration should have a unique id',
      );
    });
  });
}
