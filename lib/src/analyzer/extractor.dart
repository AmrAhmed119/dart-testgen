import 'dart:io';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as p;

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:testgen/src/analyzer/declaration.dart';
import 'package:testgen/src/analyzer/parser.dart';
import 'package:testgen/src/coverage/coverage_collection.dart';

/// Extracts all [Declaration]s from the given [path].
///
/// - If [path] is a Dart file, only that file is analyzed.
/// - If [path] is a package directory, all Dart files under its `lib/`
///   folder are analyzed recursively.
///
/// Each file is resolved and parsed into [Declaration]s, and dependencies
/// between declarations are linked.
///
/// Returns a [Future] containing all discovered [Declaration]s.
Future<List<Declaration>> extractDeclarations(String path) async {
  print('[Analyzer] Extracting declarations from $path');
  final collection = AnalysisContextCollection(includedPaths: [path]);

  final dartFiles = <String>[];

  final fileSystemEntity = FileSystemEntity.typeSync(path);
  final PackageConfig? config;

  if (fileSystemEntity == FileSystemEntityType.file && path.endsWith('.dart')) {
    config = await findPackageConfig(Directory(p.dirname(path)));
    dartFiles.add(path);
  } else if (fileSystemEntity == FileSystemEntityType.directory) {
    config = await findPackageConfig(Directory(path));
    final libDir = Directory(p.join(path, 'lib'));
    if (!libDir.existsSync()) {
      throw ArgumentError('Directory "$path" does not contain a lib folder');
    }
    libDir.listSync(recursive: true).forEach((entity) {
      if (entity is File && entity.path.endsWith('.dart')) {
        dartFiles.add(entity.path);
      }
    });
  } else {
    throw ArgumentError('Path must be a .dart file or directory');
  }

  if (config == null) {
    throw ArgumentError(
      'Path "$path" is not a package root directory nor a Dart file inside '
      'a package directory.',
    );
  }

  final visitedDeclarations = <int, Declaration>{};

  // Keep track of dependencies while visiting the AST in which the value is
  // the list of dependencies that depends on the key declaration.
  final dependencies = <int, List<Declaration>>{};

  for (final filePath in dartFiles) {
    final context = collection.contextFor(filePath);
    final session = context.currentSession;
    final resolved = await session.getResolvedUnit(filePath);
    final content = await File(filePath).readAsString();

    if (resolved is ResolvedUnitResult) {
      parseCompilationUnit(
        resolved.unit,
        visitedDeclarations,
        dependencies,
        config.toPackageUri(File(filePath).uri).toString(),
        content,
      );
    }
  }

  for (final MapEntry(key: id, value: declarations) in dependencies.entries) {
    if (visitedDeclarations.containsKey(id)) {
      for (final declaration in declarations) {
        // Avoid adding self-dependency
        if (declaration.id != id) {
          declaration.addDependency(visitedDeclarations[id]!);
        }
      }
    }
  }

  return visitedDeclarations.values.toList();
}

/// Extracts declarations that have untested code lines based on coverage data.
///
/// Returns a list of tuples where each tuple contains:
/// - A [Declaration] that has untested lines
/// - A list of relative line numbers (0-indexed from declaration start)
///   that are uncovered
List<(Declaration, List<int>)> extractUntestedDeclarations(
  Map<String, List<Declaration>> declarations,
  CoverageData coverageResults,
) {
  final untestedDeclarations = <(Declaration, List<int>)>[];

  for (final (filePath, uncoveredLines) in coverageResults) {
    final fileDeclarations = declarations[filePath] ?? [];
    for (final declaration in fileDeclarations) {
      final lines = <int>[];
      for (final line in uncoveredLines) {
        if (line >= declaration.startLine && line <= declaration.endLine) {
          lines.add(line - declaration.startLine);
        }
      }
      if (lines.isNotEmpty) {
        untestedDeclarations.add((declaration, lines));
      }
    }
  }

  return untestedDeclarations;
}
