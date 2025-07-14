import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:testgen/src/analyzer/declaration.dart';

class DependencyVisitor extends RecursiveAstVisitor<void> {
  const DependencyVisitor(
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

  @override
  void visitNamedType(ast.NamedType node) {
    _addDependencyById(node.element2?.id);
    super.visitNamedType(node);
  }

  @override
  void visitSimpleIdentifier(ast.SimpleIdentifier node) {
    final element = node.element;
    if (element is PropertyAccessorElement2) {
      _addDependencyById(element.variable3?.id);
    }
    _addDependencyById(element?.id);
    super.visitSimpleIdentifier(node);
  }
}

class VariableDependencyVisitor extends DependencyVisitor {
  const VariableDependencyVisitor(
    super.astNode,
    super.declaration,
    super.visitedDeclarations,
    super.toBeResolvedDeclarations,
  );

  // According to the grammar:
  // variableDeclarationList ::= finalConstVarOrType VariableDeclaration (',' VariableDeclaration)*
  // We need to:
  //
  // - Visit {finalConstVarOrType} to capture any explicit type declared before
  //   the variable(s).
  //
  // - Visit the specific VariableDeclaration to capture any type information
  //   defined directly for that variable since we call the accept on each
  //   variable defined in the variable list.
  //
  // The types are then captured from the visitNamedType function.
  @override
  void visitVariableDeclarationList(ast.VariableDeclarationList node) {
    node.type?.accept(this);
    for (final variable in node.variables) {
      if (variable.declaredFragment?.element.id == declaration.id) {
        variable.accept(this);
      }
    }
  }
}

class CompoundDependencyVisitor extends DependencyVisitor {
  const CompoundDependencyVisitor(
    super.astNode,
    super.declaration,
    super.visitedDeclarations,
    super.toBeResolvedDeclarations,
  );

  void _visitExtendsClause(ast.ExtendsClause? extendsClause) {
    extendsClause?.superclass.accept(this);
  }

  void _visitImplementsClause(ast.ImplementsClause? implementsClause) {
    for (final interface in implementsClause?.interfaces ?? []) {
      interface.accept(this);
    }
  }

  @override
  void visitClassDeclaration(ast.ClassDeclaration node) {
    _visitExtendsClause(node.extendsClause);

    final mixins = node.withClause?.mixinTypes ?? [];
    for (final mixin in mixins) {
      mixin.accept(this);
    }

    _visitImplementsClause(node.implementsClause);
  }

  @override
  void visitMixinDeclaration(ast.MixinDeclaration node) {
    final constraints = node.onClause?.superclassConstraints ?? [];
    for (final constraint in constraints) {
      constraint.accept(this);
    }

    _visitImplementsClause(node.implementsClause);
  }

  @override
  void visitEnumDeclaration(ast.EnumDeclaration node) {
    _visitImplementsClause(node.implementsClause);
  }

  @override
  void visitExtensionDeclaration(ast.ExtensionDeclaration node) {
    node.onClause?.extendedType.accept(this);
  }

  @override
  void visitExtensionTypeDeclaration(ast.ExtensionTypeDeclaration node) {
    // target type of the extension type
    node.representation.accept(this);

    _visitImplementsClause(node.implementsClause);
  }
}
