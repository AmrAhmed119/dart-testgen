import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/source/line_info.dart';
import 'package:testgen/src/analyzer/declaration.dart';

const int failedToExtractID = -1;

List<Declaration> parseCompilationUnit(ast.CompilationUnit unit, String path) {
  final declarations = <Declaration>[];
  final lineInfo = unit.lineInfo;

  for (final member in unit.declarations) {
    switch (member) {
      case ast.ClassDeclaration():
        declarations.addAll(_parseClassDeclaration(member, lineInfo, path));
        break;
      case ast.FunctionDeclaration():
        declarations.add(_parseFunctionDeclaration(member, lineInfo, path));
        break;
      case ast.TopLevelVariableDeclaration():
        declarations.addAll(_parseVariableDeclaration(member, lineInfo, path));
        break;
      // Handle other types of declarations if needed
      // Left for upcoming issues
      // ex: MixinDeclaration, ExtensionDeclaration, EnumDeclaration, TypeAlias
      default:
        break;
    }
  }

  return declarations;
}

// handle both TopLevelVariableDeclaration & FieldDeclaration
List<Declaration> _parseVariableDeclaration(
  dynamic declaration,
  LineInfo lineInfo,
  String path, {
  Declaration? parent,
}) {
  // Variable Declaration might contain multiple variables
  // (ex: int x, y, z = 1), then all the variables will have the same fields
  // except for the variable id which is unique for each variable.

  final sourceCode = declaration.toSource();
  final startLine = lineInfo.getLocation(declaration.offset).lineNumber;
  final endLine = lineInfo.getLocation(declaration.end).lineNumber;
  final comments = declaration.documentationComment?.toSource() ?? '';
  final declarations = <Declaration>[];

  for (final variable in declaration.variables.variables) {
    final id = variable.declaredFragment?.element.id ?? failedToExtractID;
    declarations.add(
      Declaration(
        id,
        name: variable.name.lexeme,
        sourceCode: sourceCode,
        startLine: startLine,
        endLine: endLine,
        path: path,
        comment: comments,
        parent: parent,
      ),
    );
  }

  return declarations;
}

// handle both FunctionDeclaration & MethodDeclaration
Declaration _parseFunctionDeclaration(
  dynamic declaration,
  LineInfo lineInfo,
  String path, {
  Declaration? parent,
}) => Declaration(
  declaration.declaredFragment?.element.id ?? failedToExtractID,
  name: declaration.name.lexeme,
  sourceCode: declaration.toSource(),
  startLine: lineInfo.getLocation(declaration.offset).lineNumber,
  endLine: lineInfo.getLocation(declaration.end).lineNumber,
  path: path,
  comment: declaration.documentationComment?.toSource() ?? '',
  parent: parent,
);

List<Declaration> _parseClassDeclaration(
  ast.ClassDeclaration declaration,
  LineInfo lineInfo,
  String path,
) {
  // ClassDeclaration might contain multiple members (fields, methods, etc.)
  // We need to create a declaration for the class itself and for each
  // method or field within the class.

  Declaration parent = Declaration(
    declaration.declaredFragment?.element.id ?? failedToExtractID,
    name: declaration.name.lexeme,
    sourceCode: declaration.toSource(),
    startLine: lineInfo.getLocation(declaration.offset).lineNumber,
    endLine: lineInfo.getLocation(declaration.end).lineNumber,
    path: path,
  );

  final declarations = <Declaration>[parent];

  for (final member in declaration.members) {
    switch (member) {
      case ast.MethodDeclaration():
        declarations.add(
          _parseFunctionDeclaration(member, lineInfo, path, parent: parent),
        );
        break;
      case ast.FieldDeclaration():
        declarations.addAll(
          _parseVariableDeclaration(member, lineInfo, path, parent: parent),
        );
        break;
      case ast.ConstructorDeclaration():
        declarations.add(
          _parseConstructorDeclaration(member, lineInfo, path, parent: parent),
        );
        break;
    }
  }

  return declarations;
}

Declaration _parseConstructorDeclaration(
  ast.ConstructorDeclaration declaration,
  LineInfo lineInfo,
  String path, {
  Declaration? parent,
}) => Declaration(
  declaration.declaredFragment?.element.id ?? failedToExtractID,
  name:
      declaration.name?.lexeme != null
          ? '${parent!.name}.${declaration.name!.lexeme}'
          : parent!.name,
  sourceCode: declaration.toSource(),
  startLine: lineInfo.getLocation(declaration.offset).lineNumber,
  endLine: lineInfo.getLocation(declaration.end).lineNumber,
  path: path,
  comment: declaration.documentationComment?.toSource() ?? '',
  parent: parent,
);
