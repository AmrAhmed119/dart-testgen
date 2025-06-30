/// Represents a code declaration (such as a class, function, or variable)
/// within a source file.
///
/// Stores metadata about the declaration, including its unique [id], [name],
/// source file [path], line range ([startLine] to [endLine]), and the actual
/// [sourceCode]. Optionally, a list of [comments] associated with the 
/// declaration can be provided.
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
    this.comments = const [],
  });

  final int id;

  final String name;

  final String sourceCode;

  final int startLine;

  final int endLine;

  final String path;

  final List<String> comments;

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
  startLine: $startLine,
  endLine: $endLine,
  comments: $comments,
  dependsOn: $dependsOn
)''';
  }
}
