import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:testgen/src/analyzer/declaration.dart';
import 'package:testgen/src/analyzer/parser.dart';

/// Resolves Dart files within the specified [packageRoot] and extracts their
/// top-level declarations.
///
/// This function creates an [AnalysisContextCollection] for the given package
/// root, then iterates over a list of Dart file paths.
/// For each file, it resolves the compilation unit and parses its declarations,
/// collecting them into a list. The function returns a list of all discovered
/// [Declaration]s.
///
/// Returns a [Future] that completes with a list of [Declaration] objects
/// extracted from the resolved Dart files.
Future<List<Declaration>> extractDeclarations(String packageRoot) async {
  final collection = AnalysisContextCollection(includedPaths: [packageRoot]);

  final dartFiles = <String>[];
  Directory(packageRoot).listSync(recursive: true).forEach((entity) {
    if (entity is File && entity.path.endsWith('.dart')) {
      dartFiles.add(entity.path);
    }
  });

  final visitedDeclarations = <Declaration>[];

  for (final filePath in dartFiles) {
    final context = collection.contextFor(filePath);
    final session = context.currentSession;
    final resolved = await session.getResolvedUnit(filePath);

    if (resolved is ResolvedUnitResult) {
      visitedDeclarations.addAll(parseCompilationUnit(resolved.unit, filePath));
    }
  }

  return visitedDeclarations;
}
