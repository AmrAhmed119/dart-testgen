import 'dart:io';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as path;

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:testgen/src/analyzer/declaration.dart';
import 'package:testgen/src/analyzer/parser.dart';
import 'package:testgen/src/coverage/coverage_collection.dart';

/// Extracts [Declaration]s from the given [package].
///
/// If [targetFiles] is provided, only declarations in the provided file paths
/// are returned.
///
/// Each file is resolved and parsed into [Declaration]s, and dependencies
/// between declarations are linked.
///
/// Returns a [Future] containing discovered [Declaration]s.
Future<List<Declaration>> extractDeclarations(
  String package, {
  List<String> targetFiles = const [],
}) async {
  print('[Analyzer] Extracting declarations from $package');
  final collection = AnalysisContextCollection(includedPaths: [package]);

  final config = await findPackageConfig(Directory(package));
  if (config == null) {
    throw ArgumentError('Path "$package" is not a dart package root directory');
  }

  final libDir = Directory(path.join(package, 'lib'));
  if (!libDir.existsSync()) {
    throw ArgumentError('Directory "$package" does not contain a lib folder');
  }

  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .map((file) => file.path)
      .toList();

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

  final allDeclarations = visitedDeclarations.values.toList();

  if (targetFiles.isNotEmpty) {
    final targetSet = targetFiles
        .map((file) => config.toPackageUri(File(file).uri).toString())
        .toSet();
    return allDeclarations.where((d) => targetSet.contains(d.path)).toList();
  }

  return allDeclarations;
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
