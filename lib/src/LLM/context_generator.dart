import 'package:testgen/src/analyzer/declaration.dart';

/// Builds a context map for a given [declaration], by traversing its
/// dependencies up to [maxDepth] levels deep.
///
/// The returned map groups declarations by their parent, which can be `null`
/// for top-level declarations.
Map<Declaration?, List<Declaration>> buildDependencyContext(
  Declaration declaration, {
  int maxDepth = 1,
}) {
  final visitedDeclarations = <Declaration>{};
  final parentMap = <Declaration?, List<Declaration>>{};

  for (final dependency in declaration.dependsOn) {
    _dfs(dependency, visitedDeclarations, parentMap, maxDepth: maxDepth);
  }

  return parentMap;
}

/// Formats the context map produced by [buildDependencyContext] into a
/// human-readable string, including code snippets and their file paths.
String formatContext(Map<Declaration?, List<Declaration>> parentMap) {
  final buffer = StringBuffer();

  for (final MapEntry(key: parent, value: children) in parentMap.entries) {
    if (parent != null) {
      buffer.writeln('// Code Snippet package path: ${parent.path}');

      buffer.writeln('${parent.toCode()} \n');
      buffer.writeln('// rest of the code... \n');
      for (final child in children) {
        buffer.writeln('${child.toCode()} \n');
      }
      buffer.writeln('// rest of the code... \n');
      buffer.writeln('} \n');
    } else {
      for (final child in children) {
        if (parentMap.containsKey(child)) continue;
        buffer.writeln('// Code Snippet package path: ${child.path}');
        buffer.writeln('${child.toCode()} \n');
      }
    }
  }

  return buffer.toString();
}

/// Returns the code for [declaration] after marking the specified [lines]
/// as untested, and wrapping it in the parent declaration's context if exists.
String formatUntestedCode(Declaration declaration, List<int> lines) {
  final markedCode = List<String>.from(declaration.sourceCode);
  for (final line in lines) {
    markedCode[line] += ' // UNTESTED';
  }

  return '''
// Code Snippet package path: ${declaration.path}
${declaration.parent?.toCode() ?? ''}

${markedCode.join('\n')}

${declaration.parent != null ? '}' : ''}
''';
}

void _dfs(
  Declaration declaration,
  Set<Declaration> visitedDeclarations,
  Map<Declaration?, List<Declaration>> parentMap, {
  int currentDepth = 1,
  int maxDepth = 1,
}) {
  if (visitedDeclarations.contains(declaration) || currentDepth > maxDepth) {
    return;
  }

  visitedDeclarations.add(declaration);
  parentMap.putIfAbsent(declaration.parent, () => []).add(declaration);

  for (final dependency in declaration.dependsOn) {
    _dfs(
      dependency,
      visitedDeclarations,
      parentMap,
      currentDepth: currentDepth + 1,
      maxDepth: maxDepth,
    );
  }
}
