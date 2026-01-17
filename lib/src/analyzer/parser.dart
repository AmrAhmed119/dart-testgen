import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/source/line_info.dart';
import 'package:logging/logging.dart';
import 'package:test_gen_ai/src/analyzer/declaration.dart';
import 'package:test_gen_ai/src/analyzer/visitor.dart';

final _logger = Logger('parser');

void parseCompilationUnit(
  ast.CompilationUnit unit,
  Map<int, Declaration> visitedDeclarations,
  Map<int, List<Declaration>> dependencies,
  String path,
  String content,
) {
  final lineInfo = unit.lineInfo;

  for (final member in unit.declarations) {
    switch (member) {
      case ast.TopLevelVariableDeclaration():
        _parseTopLevelVariableDeclaration(
          member,
          visitedDeclarations,
          dependencies,
          lineInfo,
          path,
          content,
        );
        break;
      case ast.ExtensionDeclaration() ||
          ast.ClassDeclaration() ||
          ast.MixinDeclaration() ||
          ast.EnumDeclaration() ||
          ast.ExtensionTypeDeclaration():
        _parseCompoundDeclaration(
          member,
          visitedDeclarations,
          dependencies,
          lineInfo,
          path,
          content,
        );
        break;
      case ast.NamedCompilationUnitMember():
        _parseNamedCompilationUnitMember(
          member,
          visitedDeclarations,
          dependencies,
          lineInfo,
          path,
          content,
        );
        break;
    }
  }
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
        .replaceAll('\r\n', '\n') // Normalize Windows line endings
        .split('\n'),
    startLine: lineInfo
        .getLocation(groupOffset ?? declaration.offset)
        .lineNumber,
    endLine: lineInfo.getLocation(groupEnd ?? declaration.end).lineNumber,
    path: path,
    parent: parent,
  );
}

void _parseTopLevelVariableDeclaration(
  ast.TopLevelVariableDeclaration declaration,
  Map<int, Declaration> visitedDeclarations,
  Map<int, List<Declaration>> dependencies,
  LineInfo lineInfo,
  String path,
  String content,
) {
  // TopLevelVariableDeclaration might contain multiple variables
  // (ex: int? x, y, z = 1), all the variables will have the same fields
  // except for the id field which is unique for each variable.

  for (final variable in declaration.variables.variables) {
    _logger.fine(
      'Parsing top-level variable declaration: ${variable.name.lexeme}',
    );
    final parsedDeclaration = _parseDeclaration(
      variable,
      lineInfo,
      path,
      content,
      name: variable.name.lexeme,
      groupOffset: declaration.offset,
      groupEnd: declaration.end,
    );
    visitedDeclarations[parsedDeclaration.id] = parsedDeclaration;
    declaration.variables.accept(
      VariableDependencyVisitor(variable, parsedDeclaration, dependencies),
    );
  }
}

void _parseCompoundDeclaration(
  ast.CompilationUnitMember declaration,
  Map<int, Declaration> visitedDeclarations,
  Map<int, List<Declaration>> dependencies,
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

  // For compound declarations store the content, the start, and end line
  // numbers corresponding to the definition (signature) of the compound
  final compoundOffset = declaration.firstTokenAfterCommentAndMetadata.offset;
  final signatureEnd = content.indexOf(RegExp(r'[{;]'), compoundOffset) + 1;

  _logger.fine('Parsing compound declaration: $name');
  final parent = _parseDeclaration(
    declaration,
    lineInfo,
    path,
    content,
    name: name,
    groupEnd: signatureEnd,
  );
  visitedDeclarations[parent.id] = parent;
  declaration.accept(
    CompoundDependencyVisitor(declaration, parent, dependencies),
  );

  _parseClassMembers(
    members,
    visitedDeclarations,
    dependencies,
    lineInfo,
    path,
    content,
    parent,
  );

  if (declaration is ast.EnumDeclaration) {
    _parseEnumConstants(
      declaration,
      visitedDeclarations,
      dependencies,
      lineInfo,
      path,
      content,
      parent,
    );
  }
}

void _parseClassMembers(
  List<ast.ClassMember> members,
  Map<int, Declaration> visitedDeclarations,
  Map<int, List<Declaration>> dependencies,
  LineInfo lineInfo,
  String path,
  String content,
  Declaration parent,
) {
  for (final member in members) {
    late Declaration parsedDecalaration;
    switch (member) {
      case ast.MethodDeclaration():
        _logger.fine('Parsing method declaration: ${member.name.lexeme}');
        parsedDecalaration = _parseDeclaration(
          member,
          lineInfo,
          path,
          content,
          name: member.name.lexeme,
          parent: parent,
        );
        break;
      case ast.FieldDeclaration():
        for (final variable in member.fields.variables) {
          _logger.fine('Parsing field declaration: ${variable.name.lexeme}');
          parsedDecalaration = _parseDeclaration(
            variable,
            lineInfo,
            path,
            content,
            name: variable.name.lexeme,
            groupOffset: member.offset,
            groupEnd: member.end,
            parent: parent,
          );
        }
        break;
      case ast.ConstructorDeclaration():
        final constructorName = member.name?.lexeme != null
            ? '${parent.name}.${member.name!.lexeme}'
            : parent.name;
        _logger.fine('Parsing constructor declaration: $constructorName');
        parsedDecalaration = _parseDeclaration(
          member,
          lineInfo,
          path,
          content,
          name: constructorName,
          parent: parent,
        );
        break;
    }
    visitedDeclarations[parsedDecalaration.id] = parsedDecalaration;
    member.accept(DependencyVisitor(member, parsedDecalaration, dependencies));
  }
}

void _parseEnumConstants(
  ast.EnumDeclaration declaration,
  Map<int, Declaration> visitedDeclarations,
  Map<int, List<Declaration>> dependencies,
  LineInfo lineInfo,
  String path,
  String content,
  Declaration parent,
) {
  for (final constant in declaration.constants) {
    _logger.fine('Parsing enum constant declaration: ${constant.name.lexeme}');
    final parsedDeclaration = _parseDeclaration(
      constant,
      lineInfo,
      path,
      content,
      name: constant.name.lexeme,
      parent: parent,
    );
    visitedDeclarations[parsedDeclaration.id] = parsedDeclaration;
    constant.accept(
      DependencyVisitor(constant, parsedDeclaration, dependencies),
    );
  }
}

void _parseNamedCompilationUnitMember(
  ast.NamedCompilationUnitMember member,
  Map<int, Declaration> visitedDeclarations,
  Map<int, List<Declaration>> dependencies,
  LineInfo lineInfo,
  String path,
  String content,
) {
  // NamedCompilationUnitMember includes top-level functions and type aliases
  _logger.fine('Parsing named compilation unit member: ${member.name.lexeme}');
  final parsedDeclaration = _parseDeclaration(
    member,
    lineInfo,
    path,
    content,
    name: member.name.lexeme,
  );
  visitedDeclarations[parsedDeclaration.id] = parsedDeclaration;
  member.accept(DependencyVisitor(member, parsedDeclaration, dependencies));
}
