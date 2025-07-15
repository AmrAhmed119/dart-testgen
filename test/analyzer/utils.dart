import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:testgen/src/analyzer/declaration.dart';
import 'package:path/path.dart' as path;
import 'package:testgen/src/analyzer/parser.dart';

Declaration findDeclarationByName(
  Iterable<Declaration> declarations,
  String name,
) => declarations.firstWhere((d) => d.name == name);

Future<Map<String, Declaration>> extractDeclarationsForSourceFile(
  String filePath,
  List<String> names,
) async {
  final absolute = path.normalize(path.absolute(filePath));
  final content = await File(absolute).readAsString();

  // Set up analyzer context for resolving
  final collection = AnalysisContextCollection(includedPaths: [absolute]);
  final context = collection.contextFor(absolute);
  final session = context.currentSession;
  final result = await session.getResolvedUnit(absolute);

  final visitedDeclarations = <int, Declaration>{};
  final dependencies = <int, List<Declaration>>{};

  if (result is ResolvedUnitResult) {
    parseCompilationUnit(
      result.unit,
      visitedDeclarations,
      dependencies,
      filePath,
      content,
    );
  }

  for (final MapEntry(key: id, value: declarations) in dependencies.entries) {
    if (visitedDeclarations.containsKey(id)) {
      for (final declaration in declarations) {
        if (declaration.id != id) {
          // Avoid adding self-dependency
          declaration.addDependency(visitedDeclarations[id]!);
        }
      }
    }
  }

  return {
    for (final name in names)
      name: findDeclarationByName(visitedDeclarations.values, name),
  };
}
