/// Represents a code declaration (such as a class, function, or variable)
/// within a source file.
///
/// Stores metadata about the declaration, including:
/// - a unique [id]
/// - the [name] of the declaration
/// - the [sourceCode] for the declaration
/// - the source file [path]
/// - the line range ([startLine] to [endLine]) in the file
/// - any associated [comment] (as a string)
/// - an optional [parent] declaration (for nested structures - typically
///   used for methods and fields inside a class)
///
/// The [dependsOn] list tracks other [Declaration]s that this declaration
/// depends on, allowing for dependency analysis between code elements.
class Declaration {
  Declaration(
    this.id, {
    required this.name,
    required this.sourceCode,
    required this.startLine,
    required this.endLine,
    required this.path,
    this.comment = '',
    this.parent,
  });

  final int id;

  final String name;

  // May be need to be a list of strings?
  // Will contain the annotations described above the declaration.
  final String sourceCode;

  final int startLine;

  final int endLine;

  final String path;

  final String comment;

  final Declaration? parent;

  final List<Declaration> dependsOn = [];

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
  comments: $comment,
  dependsOn: $dependsOn
)''';
  }
}
