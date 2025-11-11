import 'dart:io';

import 'package:testgen/src/analyzer/declaration.dart';
import 'package:path/path.dart' as path;
import 'package:testgen/src/analyzer/extractor.dart';

const testPackagePath = ['test', 'fixtures', 'test_package'];

Declaration findDeclarationByName(
  List<Declaration> declarations,
  String name,
) => declarations.firstWhere((d) => d.name == name);

Future<void> _ensureFixturePackageConfig() async {
  final package = path.normalize(path.absolute(path.joinAll(testPackagePath)));
  final packageConfigPath = path.join(
    package,
    '.dart_tool',
    'package_config.json',
  );
  if (!File(packageConfigPath).existsSync()) {
    final result = await Process.run('dart', [
      'pub',
      'get',
    ], workingDirectory: package);
    if (result.exitCode != 0) {
      throw Exception(
        'Failed to run `dart pub get` in $package: ${result.stderr}',
      );
    }
  }
}

Future<Map<String, Declaration>> extractNamedDeclarationsFromFile(
  String filePath,
  List<String> names,
) async {
  await _ensureFixturePackageConfig();
  final package = path.normalize(path.absolute(path.joinAll(testPackagePath)));
  final absolute = path.normalize(path.absolute(filePath));
  final declarations = await extractDeclarations(
    package,
    targetFiles: [absolute],
  );
  return {
    for (final name in names) name: findDeclarationByName(declarations, name),
  };
}

Declaration sampleDecl(
  int id, {
  String name = '',
  String path = '',
  List<String> sourceCode = const [],
  int startLine = 1,
  Declaration? parent,
}) => Declaration(
  id,
  name: name,
  sourceCode: sourceCode,
  startLine: startLine,
  endLine: startLine + sourceCode.length - 1,
  path: path,
  parent: parent,
);
