import 'dart:io';

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:testgen/src/analyzer/declaration.dart';
import 'package:path/path.dart' as path;
import 'package:testgen/src/analyzer/parser.dart';

Declaration findDeclarationByName(
  List<Declaration> declarations,
  String name,
) => declarations.firstWhere((d) => d.name == name);

Future<List<Declaration>> extractDeclarationsForSourceFile(
  String filePath,
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

  for (final entry in dependencies.entries) {
    final int id = entry.key;
    final List<Declaration> declarations = entry.value;

    if (visitedDeclarations.containsKey(id)) {
      for (final declaration in declarations) {
        declaration.addDependency(visitedDeclarations[id]!);
      }
    }
  }
  
  return visitedDeclarations.values.toList();
}
