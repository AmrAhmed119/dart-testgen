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

  /// Returns a Graphviz DOT format representation of this declaration.
  String toGraphviz() {
    final buffer = StringBuffer();

    // Create node for this declaration
    final nodeId = 'decl_$id';
    final escapedName = name.replaceAll('"', '\\"');

    String shape = 'box';
    String color = 'lightblue';

    buffer.writeln(
      '  $nodeId [label="$escapedName\\n($startLine:$endLine)", shape=$shape, '
      'fillcolor=$color, style=filled];',
    );

    for (final dependency in dependsOn) {
      final depNodeId = 'decl_${dependency.id}';
      buffer.writeln('  $nodeId -> $depNodeId;');
    }

    return buffer.toString();
  }

  /// Creates a complete Graphviz DOT graph from a list of declarations.
  ///
  /// This static method generates a full DOT graph that can be rendered
  /// with Graphviz tools. It includes all declarations and their dependencies.
  ///
  /// Parameters:
  /// - [declarations]: List of declarations to include in the graph
  /// - [title]: Optional title for the graph
  /// - [rankdir]: Direction of the graph layout
  ///
  /// Returns a complete DOT format string ready for Graphviz rendering.
  static String toGraphvizFromDeclarations(
    List<Declaration> declarations, {
    String title = 'Declaration Dependencies',
    String rankdir = 'LR',
  }) {
    final buffer = StringBuffer();

    buffer.writeln('digraph G {');
    buffer.writeln('  rankdir=$rankdir;');
    buffer.writeln('  node [fontname="Arial", fontsize=10];');
    buffer.writeln('  edge [fontname="Arial", fontsize=8];');
    buffer.writeln('  label="$title";');
    buffer.writeln('  labelloc=t;');
    buffer.writeln('  fontsize=16;');
    buffer.writeln();

    // Add all declarations and their dependencies
    for (final declaration in declarations) {
      buffer.write(declaration.toGraphviz());
    }

    buffer.writeln('}');
    return buffer.toString();
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
