import 'dart:io';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:test/test.dart';
import 'package:testgen/src/analyzer/declaration.dart';
import 'package:testgen/src/analyzer/parser.dart';
import 'package:path/path.dart' as path;

Declaration _findDeclarationByName(
  List<Declaration> declarations,
  String name,
) => declarations.firstWhere((d) => d.name == name);

void main() {
  late List<Declaration> declarations;

  setUpAll(() async {
    final codePath = 'test/analyzer/code.dart';
    final absolute = path.normalize(path.absolute(codePath));
    final codeContent = await File(absolute).readAsString();

    // Set up analyzer context for resolving
    final collection = AnalysisContextCollection(includedPaths: [absolute]);
    final context = collection.contextFor(absolute);
    final session = context.currentSession;
    final result = await session.getResolvedUnit(absolute);
    final visitedDeclarations = <int, Declaration>{};

    if (result is ResolvedUnitResult) {
      parseCompilationUnit(
        result.unit,
        visitedDeclarations,
        {},
        codePath,
        codeContent,
      );
      declarations = visitedDeclarations.values.toList();
    } else {
      declarations = [];
    }
  });

  group('parseCompilationUnit', () {
    test('parses top-level variable declaration', () {
      final a = _findDeclarationByName(declarations, 'a');
      final b = _findDeclarationByName(declarations, 'b');

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
      final ext = _findDeclarationByName(declarations, 'StringExtension');
      final method = _findDeclarationByName(declarations, 'reversed');

      expect(ext.name, 'StringExtension');
      expect(ext.sourceCode, [
        'extension StringExtension on String {',
        "  String reversed() => split('').reversed.join();",
        '}',
      ]);
      expect(ext.startLine, 4);
      expect(ext.endLine, 6);
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
      final mixin = _findDeclarationByName(declarations, 'Logger');
      final method = _findDeclarationByName(declarations, 'log');

      expect(mixin.name, 'Logger');
      expect(mixin.sourceCode, [
        'mixin Logger {',
        "  void log(String message) => print('Log: new Log');",
        '}',
      ]);
      expect(mixin.startLine, 8);
      expect(mixin.endLine, 10);
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
      final enumDecl = _findDeclarationByName(declarations, 'Status');
      final field = _findDeclarationByName(declarations, 'code');
      final method = _findDeclarationByName(declarations, 'describe');
      final constants = [
        _findDeclarationByName(declarations, 'pending'),
        _findDeclarationByName(declarations, 'approved'),
        _findDeclarationByName(declarations, 'rejected'),
      ];

      // 1 enum + 3 constants + 1 field + 1 constructor + 1 method = 7
      expect(
        declarations.where((d) => d.parent == enumDecl || d == enumDecl).length,
        7,
      );

      expect(enumDecl.startLine, 12);
      expect(enumDecl.endLine, 24);

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
      final callbackDef = _findDeclarationByName(declarations, 'IntCallback');
      final genericDef = _findDeclarationByName(declarations, 'Mapper');

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
      final extType = _findDeclarationByName(declarations, 'UserID');
      final getter = _findDeclarationByName(declarations, 'isValid');
      final method = _findDeclarationByName(declarations, 'getUser');

      expect(extType.name, 'UserID');
      expect(extType.sourceCode, [
        'extension type UserID(int id) {',
        '  bool get isValid => id > 0;',
        '',
        '  /// get user id in a formatted string',
        "  String getUser() => 'UserID(\$id)';",
        '}',
      ]);
      expect(extType.startLine, 33);
      expect(extType.endLine, 38);
      expect(extType.parent, null);

      expect(getter.name, 'isValid');
      expect(getter.startLine, 34);
      expect(getter.endLine, 34);
      expect(getter.parent, extType);

      expect(method.name, 'getUser');
      expect(method.startLine, 36);
      expect(method.endLine, 37);
      expect(method.parent, extType);
    });

    test('parses class declaration', () {
      final classDecl = _findDeclarationByName(declarations, 'Person');
      final field = _findDeclarationByName(declarations, 'name');
      final constructor = _findDeclarationByName(declarations, 'Person.named');
      final method = _findDeclarationByName(declarations, 'greet');

      expect(classDecl.name, 'Person');
      expect(classDecl.startLine, 40);
      expect(classDecl.endLine, 53);
      expect(classDecl.parent, null);

      expect(field.name, 'name');
      expect(field.startLine, 43);
      expect(field.endLine, 44);
      expect(field.parent, classDecl);

      expect(constructor.name, 'Person.named');
      expect(constructor.sourceCode, [
        '/// Constructor for Person',
        '  Person.named(this.name);',
      ]);
      expect(constructor.startLine, 46);
      expect(constructor.endLine, 47);
      expect(constructor.parent, classDecl);

      expect(method.name, 'greet');
      expect(method.startLine, 49);
      expect(method.endLine, 52);
      expect(method.parent, classDecl);
    });

    test('parses top-level function', () {
      final func = _findDeclarationByName(declarations, 'sum');

      expect(func.name, 'sum');
      expect(func.sourceCode, [
        '/// comment above annotation',
        "@Deprecated('Use sum instead')",
        'int sum(int x, int y) => x + y;',
      ]);
      expect(func.startLine, 55);
      expect(func.endLine, 57);
      expect(func.parent, null);
    });

    test('each declaration has a unique id', () {
      final ids = declarations.map((d) => d.id).toSet();
      expect(
        ids.length,
        declarations.length,
        reason: 'Each declaration should have a unique id',
      );
    });
  });
}
