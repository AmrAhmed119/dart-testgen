import 'package:testgen/src/analyzer/declaration.dart';
import 'package:path/path.dart' as path;
import 'package:testgen/src/analyzer/extractor.dart';

Declaration findDeclarationByName(
  List<Declaration> declarations,
  String name,
) => declarations.firstWhere((d) => d.name == name);

Future<Map<String, Declaration>> extractDeclarationsForSourceFile(
  String filePath,
  List<String> names,
) async {
  final absolute = path.normalize(path.absolute(filePath));
  final declarations = await extractDeclarations(absolute);
  return {
    for (final name in names) name: findDeclarationByName(declarations, name),
  };
}
