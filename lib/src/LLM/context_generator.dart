import 'package:testgen/src/analyzer/declaration.dart';

/// Generates a context map for a given [declaration], traversing its dependencies
/// up to [maxDepth] levels deep. The returned map groups declarations by their parent,
/// which can be used to reconstruct the code context for LLM prompt.
Map<Declaration?, List<Declaration>> generateContextForDeclaration(
  Declaration declaration, {
  int maxDepth = 1,
}) {
  final visitedDeclarations = <Declaration>{};
  final parentMap = <Declaration?, List<Declaration>>{};

  for (final dependent in declaration.dependsOn) {
    _dfs(dependent, visitedDeclarations, parentMap, maxDepth: maxDepth);
  }

  return parentMap;
}

/// Formats the context map produced by [generateContextForDeclaration] into a
/// human-readable string, including code snippets and their file paths.
String formatContext(Map<Declaration?, List<Declaration>> parentMap) {
  final buffer = StringBuffer();

  for (final MapEntry(key: parent, value: children) in parentMap.entries) {
    if (parent != null) {
      buffer.writeln('// Code Snippet package path: ${parent.path} \n');

      buffer.writeln('${parent.sourceCode.join('\n')} \n');
      buffer.writeln('// rest of the code... \n');
      for (final child in children) {
        buffer.writeln('${child.sourceCode.join('\n')} \n');
      }
      buffer.writeln('// rest of the code... \n');
      buffer.writeln('} \n');
    } else {
      for (final child in children) {
        if (parentMap.containsKey(child)) continue;
        buffer.writeln('// Code Snippet package path: ${child.path} \n');
        buffer.writeln('${child.sourceCode.join('\n')} \n');
      }
    }
  }

  return buffer.toString();
}

/// Marks the specified [lines] in the [declaration]'s source code as untested
/// by appending a comment to each line. Returns the modified source code as a string.
String markUntestedLines(Declaration declaration, List<int> lines) {
  final newCode = List<String>.from(declaration.sourceCode);
  for (final line in lines) {
    newCode[line] += ' // UNTESTED';
  }
  return newCode.join('\n');
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

  for (final dependent in declaration.dependsOn) {
    _dfs(
      dependent,
      visitedDeclarations,
      parentMap,
      currentDepth: currentDepth + 1,
      maxDepth: maxDepth,
    );
  }
}
