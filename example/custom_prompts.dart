import 'package:testgen/testgen.dart';

class CustomPromptGenerator extends PromptGenerator {
  @override
  String testCode(String toBeTestedCode, String contextCode) {
    return '''
  Generate a test case for the following Dart code:

  ```dart
  $toBeTestedCode
  ```

  Use the following context to help you understand the code:

  ```dart
  $contextCode
  ```
''';
  }

  @override
  String fixError(String error) {
    return 'fix the following error:\n$error';
  }
}

Future<void> main() async {
  // change the packagePath and scopeOutput to your package
  // and modelName to your preferred model
  
  final packagePath = '/home/user/code/yourPackage';
  final scopeOutput = 'yourPackage';
  final modelName = 'gemini-2.5-pro';

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

  final model = createModel(model: modelName);

  for (final (declaration, lines) in untestedDeclarations) {
    print(
      '[testgen] Generating tests for ${declaration.name}, remaining: '
      '${untestedDeclarations.length}',
    );
    final toBeTestedCode = formatUntestedCode(declaration, lines);
    final contextMap = buildDependencyContext(declaration, maxDepth: 5);
    final contextCode = formatContext(contextMap);

    final (status, chat) = await generateTestFile(
      model: model,
      toBeTestedCode: toBeTestedCode,
      contextCode: contextCode,
      packagePath: packagePath,
      fileName: '${declaration.name}_${declaration.id}_test.dart',
      promptGen: CustomPromptGenerator(),
      // In case you want to keep tests that improve code coverage only
      coverageValidator: CoverageValidator(
        declaration,
        lines.length,
        packagePath,
        scopeOutput,
      ),
      initialBackoff: Duration(seconds: 16),
      maxRetries: 10,
    );
    final tokens = await countTokens(model, chat);
    print(
      '[testgen] Finished generating tests for ${declaration.name} with '
      'status $status using $tokens tokens.',
    );
  }
}
