import 'package:testgen/testgen.dart';

Future<void> main() async {
  // change the packagePath and scopeOutput to your package
  final packagePath = '/home/user/code/yourPackage';
  final scopeOutput = 'yourPackage';
  final modelName = 'gemini-3-flash-preview';

  final coverage = await runTestsAndCollectCoverage(
    packagePath,
    scopeOutput: {scopeOutput},
  );
  final coverageByFile = await formatCoverage(coverage, packagePath);

  final declarations = await extractDeclarations(packagePath);

  final Map<String, List<Declaration>> declarationsByFile = {};
  for (final declaration in declarations) {
    declarationsByFile.putIfAbsent(declaration.path, () => []).add(declaration);
  }

  final untestedDeclarations = extractUntestedDeclarations(
    declarationsByFile,
    coverageByFile,
  );

  final model = GeminiModel(modelName: modelName);
  final testGenerator = TestGenerator(model: model, packagePath: packagePath);

  for (final (declaration, lines) in untestedDeclarations) {
    print('[testgen] Generating tests for ${declaration.name}');
    final toBeTestedCode = formatUntestedCode(declaration, lines);
    final contextMap = buildDependencyContext(declaration);
    final contextCode = formatContext(contextMap);

    final response = await testGenerator.generate(
      toBeTestedCode: toBeTestedCode,
      contextCode: contextCode,
      fileName:
          '${declaration.name}_${declaration.id}_${lines.length}_test.dart',
    );

    print(
      '[testgen] Finished generating tests for ${declaration.name} with '
      'status ${response.status} using ${response.tokens} tokens.',
    );
  }
}
