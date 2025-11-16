import 'dart:collection';

import 'package:testgen/src/analyzer/declaration.dart';

const indent = '  ';
const newLine = '\n';
const rest = '// rest of the code...';
const packagePathPrefix = '// Code Snippet package path: ';

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
      buffer
        ..writeln('$packagePathPrefix${parent.path}')
        ..writeln(parent.toCode())
        ..writeln('$indent$rest$newLine');

      for (final child in children) {
        buffer.writeln('${child.sourceCode.join('\n')}$newLine');
      }

      buffer
        ..writeln('$indent$rest')
        ..writeln('}');
    } else {
      for (final child in children) {
        final closing = child.toCode().endsWith('{') ? ' ... }' : '';
        buffer
          ..writeln('$packagePathPrefix${child.path}')
          ..writeln(child.toCode() + closing);

        if (child != children.last) {
          buffer.writeln();
        }
      }
    }

    if (parent != parentMap.keys.last) {
      buffer.writeln();
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
  buffer.writeln('$packagePathPrefix${declaration.path}');

  if (hasParent) {
    buffer
      ..writeln(declaration.parent!.toCode())
      ..writeln('$indent$rest$newLine');
  }

  buffer.writeln(markedCode.join('\n'));

  if (hasParent) {
    buffer
      ..writeln("$newLine$indent$rest")
      ..writeln('}');
  }

  return buffer.toString();
}

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
