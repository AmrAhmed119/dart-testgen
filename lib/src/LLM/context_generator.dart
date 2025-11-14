import 'dart:collection';

import 'package:testgen/src/analyzer/declaration.dart';

const String indent = '  ';

/// Builds a context map for a given [declaration], by traversing its
/// dependencies up to [maxDepth] levels deep.
///
/// The returned map groups declarations by their parent, which can be `null`
/// for top-level declarations.
Map<Declaration?, List<Declaration>> buildDependencyContext(
  Declaration declaration, {
  int maxDepth = 1,
}) {
  final parentMap = <Declaration?, Set<Declaration>>{};

  for (final dependency in declaration.dependsOn) {
    _dfs(dependency, parentMap, maxDepth: maxDepth);
  }

  // Remove any declarations from the top-level list that are also keys.
  final topLevel = parentMap[null]?.toList() ?? <Declaration>[];
  for (final child in topLevel) {
    if (parentMap.containsKey(child)) {
      parentMap[null]?.remove(child);
    }
  }

  return parentMap.map<Declaration?, List<Declaration>>(
    (parent, set) => MapEntry(parent, set.toList()),
  );
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
    markedCode[line] += '$indent// UNTESTED';
  }

  final hasParent = declaration.parent != null;
  final buffer = StringBuffer();
  buffer.writeln('// Code Snippet package path: ${declaration.path}');

  if (hasParent) {
    buffer
      ..writeln(declaration.parent!.toCode())
      ..writeln('$indent// rest of the code...');
  }

  buffer.writeln(hasParent ? _indentLines(markedCode) : markedCode.join('\n'));

  if (hasParent) {
    buffer
      ..writeln("$indent// rest of the code...")
      ..writeln('}');
  }

  return buffer.toString();
}

/// Join [lines] into a single string and prefix each line with 2 spaces.
String _indentLines(List<String> lines) =>
    lines.map((l) => l.trim().isEmpty ? '' : '$indent$l').join('\n');

void _dfs(
  Declaration declaration,
  Map<Declaration?, Set<Declaration>> parentMap, {
  int currentDepth = 1,
  int maxDepth = 1,
}) {
  if (currentDepth > maxDepth) {
    return;
  }

  parentMap.putIfAbsent(declaration.parent, () => HashSet()).add(declaration);

  for (final dependency in declaration.dependsOn) {
    _dfs(
      dependency,
      parentMap,
      currentDepth: currentDepth + 1,
      maxDepth: maxDepth,
    );
  }
}
