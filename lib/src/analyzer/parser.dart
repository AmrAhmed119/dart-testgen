import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/source/line_info.dart';
import 'package:testgen/src/analyzer/declaration.dart';

List<Declaration> parseCompilationUnit(
  ast.CompilationUnit unit,
  String path,
  String content,
) {
  final declarations = <Declaration>[];
  final lineInfo = unit.lineInfo;

  for (final member in unit.declarations) {
    switch (member) {
      case ast.TopLevelVariableDeclaration():
        declarations.addAll(
          _parseTopLevelVariableDeclaration(member, lineInfo, path, content),
        );
        break;
      case ast.ExtensionDeclaration() ||
          ast.ClassDeclaration() ||
          ast.MixinDeclaration() ||
          ast.EnumDeclaration() ||
          ast.ExtensionTypeDeclaration():
        declarations.addAll(
          _parseCompoundDeclaration(member, lineInfo, path, content),
        );
        break;
      case ast.NamedCompilationUnitMember():
        declarations.add(
          _parseDeclaration(
            member,
            lineInfo,
            path,
            content,
            name: member.name.lexeme,
          ),
        );
        break;
    }
  }

  return declarations;
}

Declaration _parseDeclaration(
  ast.Declaration declaration,
  LineInfo lineInfo,
  String path,
  String content, {
  String? name,
  int? groupOffset,
  int? groupEnd,
  Declaration? parent,
}) {
  // In fully resolved, valid Dart code, every declaration node is expected
  // to contain a declaredFragment representing its metadata.
  // If declaredFragment is unexpectedly null here, throw an error.
  if (declaration.declaredFragment == null) {
    throw StateError('''
        Unexpected AST State:
        - File: $path
        - Declaration Type: ${declaration.runtimeType}
        - Line Number: ${lineInfo.getLocation(declaration.offset).lineNumber}
        
        This declaration is missing its 'declaredFragment'
        ''');
  }
  return Declaration(
    declaration.declaredFragment!.element.id,
    name: name ?? '',
    sourceCode: content
        .substring(
          groupOffset ?? declaration.offset,
          groupEnd ?? declaration.end,
        )
        .split('\n'),
    startLine:
        lineInfo.getLocation(groupOffset ?? declaration.offset).lineNumber,
    endLine: lineInfo.getLocation(groupEnd ?? declaration.end).lineNumber,
    path: path,
    parent: parent,
  );
}

List<Declaration> _parseTopLevelVariableDeclaration(
  ast.TopLevelVariableDeclaration declaration,
  LineInfo lineInfo,
  String path,
  String content,
) {
  // TopLevelVariableDeclaration might contain multiple variables
  // (ex: int? x, y, z = 1), all the variables will have the same fields
  // except for the id field which is unique for each variable.

  final declarations = <Declaration>[];

  for (final variable in declaration.variables.variables) {
    declarations.add(
      _parseDeclaration(
        variable,
        lineInfo,
        path,
        content,
        name: variable.name.lexeme,
        groupOffset: declaration.offset,
        groupEnd: declaration.end,
      ),
    );
  }

  return declarations;
}

List<Declaration> _parseCompoundDeclaration(
  ast.CompilationUnitMember declaration,
  LineInfo lineInfo,
  String path,
  String content,
) {
  // Compound declarations include ClassDeclaration, MixinDeclaration, etc
  // These are declarations that can contain class members such as methods,
  // fields, and constructors.
  // For each compound declaration, we create a Declaration for the compound
  // itself, as well as for each of its contained class members.

  final (String? name, List<ast.ClassMember> members) = switch (declaration) {
    ast.ClassDeclaration(:final name, :final members) => (name.lexeme, members),
    ast.MixinDeclaration(:final name, :final members) => (name.lexeme, members),
    ast.EnumDeclaration(:final name, :final members) => (name.lexeme, members),
    ast.ExtensionTypeDeclaration(:final name, :final members) => (
      name.lexeme,
      members,
    ),
    ast.ExtensionDeclaration(:final name, :final members) => (
      name?.lexeme,
      members,
    ),
    _ => ('', []),
  };

  final parent = _parseDeclaration(
    declaration,
    lineInfo,
    path,
    content,
    name: name,
  );

  return [
    parent,
    ..._parseClassMembers(members, lineInfo, path, content, parent),
    if (declaration is ast.EnumDeclaration)
      ..._parseEnumConstants(declaration, lineInfo, path, content, parent),
  ];
}

List<Declaration> _parseClassMembers(
  List<ast.ClassMember> members,
  LineInfo lineInfo,
  String path,
  String content,
  Declaration parent,
) {
  final declarations = <Declaration>[];

  for (final member in members) {
    switch (member) {
      case ast.MethodDeclaration():
        declarations.add(
          _parseDeclaration(
            member,
            lineInfo,
            path,
            content,
            name: member.name.lexeme,
            parent: parent,
          ),
        );
        break;
      case ast.FieldDeclaration():
        for (final variable in member.fields.variables) {
          declarations.add(
            _parseDeclaration(
              variable,
              lineInfo,
              path,
              content,
              name: variable.name.lexeme,
              groupOffset: member.offset,
              groupEnd: member.end,
              parent: parent,
            ),
          );
        }
        break;
      case ast.ConstructorDeclaration():
        declarations.add(
          _parseDeclaration(
            member,
            lineInfo,
            path,
            content,
            name:
                member.name?.lexeme != null
                    ? '${parent.name}.${member.name!.lexeme}'
                    : parent.name,
            parent: parent,
          ),
        );
        break;
    }
  }

  return declarations;
}

List<Declaration> _parseEnumConstants(
  ast.EnumDeclaration declaration,
  LineInfo lineInfo,
  String path,
  String content,
  Declaration parent,
) {
  final declarations = <Declaration>[];

  for (final constant in declaration.constants) {
    final constantName = constant.name.lexeme;
    declarations.add(
      _parseDeclaration(
        constant,
        lineInfo,
        path,
        content,
        name: constantName,
        parent: parent,
      ),
    );
  }

  return declarations;
}
