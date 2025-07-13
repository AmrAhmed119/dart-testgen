/// Represents a code declaration (such as a class, function, or variable)
/// within a source file.
///
/// This class stores metadata about the declaration, including:
/// - A unique [id] for the declaration.
/// - The [name] of the declaration.
/// - The [sourceCode] lines for the declaration.
/// - The source file [path] where the declaration is found.
/// - The line range ([startLine] to [endLine]) in the file.
/// - An optional [parent] declaration (for nested structures,
///   e.g., methods inside a class).
/// - A set of [dependsOn] declarations that this declaration depends on.
///
/// This structure enables tracking of code elements and their relationships.
class Declaration {
  Declaration(
    this.id, {
    required this.name,
    required this.sourceCode,
    required this.startLine,
    required this.endLine,
    required this.path,
    this.parent,
  });

  final int id;

  final String name;

  /// Lines of source code for the declaration (inlcuding comments,
  /// annotations, and the code itself).
  final List<String> sourceCode;

  final int startLine;

  final int endLine;

  final String path;

  final Declaration? parent;

  final Set<Declaration> dependsOn = {};

  void addDependency(Declaration declaration) {
    dependsOn.add(declaration);
  }

  @override
  String toString() {
    return '''
Declaration(
  id: $id,
  name: $name,
  path: $path,
  sourceCode: $sourceCode,
  startLine: $startLine,
  endLine: $endLine,
  parent: ${parent?.name ?? 'null'},
  dependsOn: $dependsOn
)''';
  }
}
