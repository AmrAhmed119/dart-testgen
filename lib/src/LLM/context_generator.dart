import 'dart:collection';

import 'package:collection/collection.dart';
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
  parentMap[null]?.removeWhere((decl) => parentMap.containsKey(decl));

  return parentMap.map<Declaration?, List<Declaration>>(
    (parent, set) =>
        MapEntry(parent, set.toList()..sortBy((decl) => decl.name)),
  );
}

/// Formats the context map produced by [buildDependencyContext] into a
/// human-readable string, including code snippets and their file paths.
String formatContext(Map<Declaration?, List<Declaration>> parentMap) {
  final buffer = StringBuffer();

  for (final MapEntry(key: parent, value: children) in parentMap.entries) {
    if (parent != null) {
      buffer.write('''
$packagePathPrefix${parent.path}
${parent.toCode()}
$indent$rest$newLine
''');

      for (final child in children) {
        buffer.writeln('${child.sourceCode.join('\n')}$newLine');
      }

      buffer.write(''' 
$indent$rest
}
''');
    } else {
      for (final child in children) {
        final closing = child.toCode().endsWith('{') ? ' ... }' : '';
        buffer.write(''' 
$packagePathPrefix${child.path}
${child.toCode()}$closing
''');
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
    buffer.write('''
${declaration.parent!.toCode()}
$indent$rest$newLine
''');
  }

  buffer.writeln(markedCode.join('\n'));

  if (hasParent) {
    buffer.write('''
$newLine$indent$rest
}
''');
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
