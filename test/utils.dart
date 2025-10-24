import 'package:testgen/src/analyzer/declaration.dart';
import 'package:path/path.dart' as path;
import 'package:testgen/src/analyzer/extractor.dart';

const testPackagePath = ['test', 'fixtures', 'test_package'];

// TODO: Ensure the test_package has .dart_tool before running extraction.

Declaration findDeclarationByName(
  List<Declaration> declarations,
  String name,
) => declarations.firstWhere((d) => d.name == name);

Future<Map<String, Declaration>> extractNamedDeclarationsFromFile(
  String filePath,
  List<String> names,
) async {
  final package = path.absolute(path.joinAll(testPackagePath));
  final absolute = path.normalize(path.absolute(filePath));
  final declarations = await extractDeclarations(
    package,
    targetFiles: [absolute],
  );
  return {
    for (final name in names) name: findDeclarationByName(declarations, name),
  };
}
