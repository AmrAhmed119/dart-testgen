import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:testgen/src/analyzer/declaration.dart';

class VariableAndTypeAliasVisitor extends RecursiveAstVisitor<void> {
  VariableAndTypeAliasVisitor(
    this.astNode,
    this.declaration,
    this.visitedDeclarations,
    this.toBeResolvedDeclarations,
  );

  final ast.Declaration astNode;
  final Declaration declaration;
  final Map<int, Declaration> visitedDeclarations;
  final Map<int, List<Declaration>> toBeResolvedDeclarations;

  void _addDependencyById(int? id) {
    if (id == null) return;

    if (visitedDeclarations.containsKey(id)) {
      final dep = visitedDeclarations[id]!;
      if (!declaration.dependsOn.contains(dep) && dep != declaration) {
        declaration.addDependency(dep);
      }
    } else {
      toBeResolvedDeclarations.putIfAbsent(id, () => []).add(declaration);
    }
  }

  // According to the grammar:
  // variableDeclarationList ::= finalConstVarOrType VariableDeclaration (',' VariableDeclaration)*
  // We need to:
  //
  // - Visit {finalConstVarOrType} to capture any explicit type declared before
  //   the variable(s).
  //
  // - Visit the specific VariableDeclaration to capture any type information
  //   defined directly for that variable since we visit  each variable defined
  //   in the variable list alone.
  //
  // The types are captured from the visitNamedType visit function.
  @override
  void visitVariableDeclarationList(ast.VariableDeclarationList node) {
    node.type?.accept(this);
    for (final variable in node.variables) {
      if (variable.declaredFragment?.element.id == declaration.id) {
        variable.accept(this);
      }
    }
  }

  @override
  void visitNamedType(ast.NamedType node) {
    _addDependencyById(node.element2?.id);
    super.visitNamedType(node);
  }

  @override
  void visitMethodInvocation(ast.MethodInvocation node) {
    _addDependencyById(node.methodName.element?.id);
    super.visitMethodInvocation(node);
  }

  // @override
  // void visitPropertyAccess(ast.PropertyAccess node) {
  //   print('Property Access: ${node.propertyName.name}');
  //   _addDependencyById(node.propertyName.element?.id);
  //   super.visitPropertyAccess(node);
  // }

  @override
  void visitPrefixedIdentifier(ast.PrefixedIdentifier node) {
    final element = node.identifier.element;
    // Handle the case where the identifier has not explicitly getter method.
    if (element is PropertyAccessorElement2) {
      _addDependencyById(element.variable3?.id);
    }
    _addDependencyById(element?.id);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitSimpleIdentifier(ast.SimpleIdentifier node) {
    final element = node.element;
    // Handle the case where the identifier has not explicitly getter method.
    if (element is PropertyAccessorElement2) {
      _addDependencyById(element.variable3?.id);
    }
    _addDependencyById(element?.id);
    super.visitSimpleIdentifier(node);
  }

  // To be added: Capture operator overloading
}
