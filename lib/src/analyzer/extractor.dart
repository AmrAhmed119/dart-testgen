import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:testgen/src/analyzer/declaration.dart';
import 'package:testgen/src/analyzer/parser.dart';
import 'package:testgen/src/coverage/coverage_collection.dart';

/// Extracts all top-level [Declaration]s from Dart files at [path].
///
/// If [path] is a Dart file, only that file is analyzed. If [path] is
/// a directory, all Dart files within it (recursively) are analyzed.
/// Each file is resolved and parsed, and all discovered declarations are
/// returned. Dependencies between declarations are also resolved.
/// 
/// [packageName] is used to generate package import paths for each file,
///
/// Returns a [Future] that completes with a list of [Declaration] objects.
Future<List<Declaration>> extractDeclarations(
  String path,
  String packageName,
) async {
  final collection = AnalysisContextCollection(includedPaths: [path]);

  final dartFiles = <String>[];

  final fileSystemEntity = FileSystemEntity.typeSync(path);
  if (fileSystemEntity == FileSystemEntityType.file && path.endsWith('.dart')) {
    dartFiles.add(path);
  } else if (fileSystemEntity == FileSystemEntityType.directory) {
    Directory(p.join(path, 'lib')).listSync(recursive: true).forEach((entity) {
      if (entity is File && entity.path.endsWith('.dart')) {
        dartFiles.add(entity.path);
      }
    });
  } else {
    throw ArgumentError('Path must be a .dart file or directory');
  }

  // Map to hold visited declarations that have been processed
  final visitedDeclarations = <int, Declaration>{};

  // This is used to handle cases where a declaration depends on another
  // declaration that hasn't been visited yet.
  // the value is a list of declarations that depend on the key which
  // is a declaration id that has not been visited yet.
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
        _toPackageImportPath(
          absoluteFilePath: filePath,
          projectRoot: path,
          packageName: packageName,
        ),
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

List<Declaration> extractUntestedDeclarations(
  Map<String, List<Declaration>> declarations,
  CoverageData coverageResults,
) {
  final untestedDeclarations = <Declaration>{};

  for (final MapEntry(key: filePath, value: uncoveredLines)
      in coverageResults.entries) {
    final fileDeclarations = declarations[filePath] ?? [];
    for (final declaration in fileDeclarations) {
      int start = declaration.startLine;
      int end = declaration.endLine;
      for (final line in uncoveredLines) {
        if (line >= start && line <= end) {
          untestedDeclarations.add(declaration);
          declaration.addUncoveredLine(line);
          break;
        }
      }
    }
  }

  return untestedDeclarations.toList();
}

/// Converts an absolute file path into a package import path
String _toPackageImportPath({
  required String absoluteFilePath,
  required String projectRoot,
  required String packageName,
}) {
  final libPath = p.join(projectRoot, 'lib');
  if (!p.isWithin(libPath, absoluteFilePath) && absoluteFilePath != projectRoot) {
    throw ArgumentError(
      'File is not inside the lib directory: $absoluteFilePath',
    );
  }

  final relativePath = p.relative(absoluteFilePath, from: libPath);
  return 'package:$packageName/$relativePath';
}
