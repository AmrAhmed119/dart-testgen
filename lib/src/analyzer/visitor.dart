import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:testgen/src/analyzer/declaration.dart';

class DependencyVisitor extends RecursiveAstVisitor<void> {
  const DependencyVisitor(
    this.astNode,
    this.declaration,
    this.visitedDeclarations,
    this.dependencies,
  );

  final ast.Declaration astNode;
  final Declaration declaration;
  final Map<int, Declaration> visitedDeclarations;
  final Map<int, List<Declaration>> dependencies;

  void _addDependencyById(int? id) {
    if (id == null) return;

    dependencies.putIfAbsent(id, () => []).add(declaration);
  }

  // Captures type references such as class names, type parameters.
  @override
  void visitNamedType(ast.NamedType node) {
    _addDependencyById(node.element2?.id);
    super.visitNamedType(node);
  }

  // Captures variable references, property access, and method calls.
  // Examples:
  // - Variable references: myVariable, globalVar
  // - Property access: obj.property (captures 'property')
  // - Method calls: obj.method() (captures 'method')
  // - Getter access: obj.value (captures underlying variable if it's a property)
  // - TODO: Setter access: currently has a problem with setters.
  //
  // This method is sufficient for most dependencies since SimpleIdentifier
  // tokens are used throughout the Dart grammar and will be  visited
  // automatically by the recursive visitor for most language constructs.
  @override
  void visitSimpleIdentifier(ast.SimpleIdentifier node) {
    final element = node.element;
    _addDependencyById(element?.id);

    // Handle the case where the element is an implicit getter so we need to
    // capture the underlying variable id.
    if (element is PropertyAccessorElement2) {
      _addDependencyById(element.variable3?.id);
    }
    super.visitSimpleIdentifier(node);
  }
}

class VariableDependencyVisitor extends DependencyVisitor {
  const VariableDependencyVisitor(
    super.astNode,
    super.declaration,
    super.visitedDeclarations,
    super.dependencies,
  );

  // According to the grammar:
  // variableDeclarationList ::= finalConstVarOrType VariableDeclaration (',' VariableDeclaration)*
  // We need to:
  //
  // - Visit {finalConstVarOrType} to capture any explicit type declared before
  //   the variable(s).
  //
  // - Visit the specific VariableDeclaration to capture any type information
  //   defined directly for that variable since we call the accept method on
  //   each variable defined in the variable list.
  //
  // This is necessary to avoid capturing dependencies from other variables in
  // the same variable list
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
    super.dependencies,
  );

  void _visitExtendsClause(ast.ExtendsClause? extendsClause) {
    extendsClause?.superclass.accept(this);
  }

  void _visitImplementsClause(ast.ImplementsClause? implementsClause) {
    for (final interface in implementsClause?.interfaces ?? []) {
      interface.accept(this);
    }
  }

  // For all overridden methods below, we do not call super because we do not
  // need to recursively visit all compound declaration members (such as fields,
  // methods, or constructors). Instead, we only extract dependencies from the
  // relevant clauses (extends, implements, mixins, constraints, etc.) that define
  // type relationships for the declaration.

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
