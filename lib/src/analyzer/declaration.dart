/// Represents a code declaration extracted from Dart source files during
/// static analysis.
///
/// This is the fundamental unit used by testgen to track code elements
/// (classes, functions, methods, variables, etc.) and their dependency
/// relationships.
///
/// Each declaration contains the necessary metadata for dependency resolution,
/// coverage analysis, and LLM-based test generation.
///
/// Example usage:
/// ```dart
/// final declaration = Declaration(
///   42,
///   name: 'calculateSum',
///   sourceCode: ['int calculateSum(int a, int b) {', '  return a + b;', '}'],
///   startLine: 15,
///   endLine: 17,
///   path: 'package:testgen/src/analyzer/declaration.dart',
/// );
/// ```
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

  /// Unique ID extracted from analyzer package element IDs.
  final int id;

  /// The declared identifier name.
  final String name;

  /// Source lines of this declaration, including any comments and annotations.
  final List<String> sourceCode;

  final int startLine;

  final int endLine;

  /// File path represented in Dart package URI format
  /// (e.g. package:my_pkg/src/file.dart).
  final String path;

  /// Parent declaration for nested elements (e.g., method inside a class).
  final Declaration? parent;

  final Set<Declaration> dependsOn = {};

  void addDependency(Declaration declaration) {
    dependsOn.add(declaration);
  }

  String toCode() => sourceCode.join('\n');

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
  dependsOn: [${dependsOn.map((d) => '${d.name}_${d.id}').join(', ')}]
)''';
  }
}
