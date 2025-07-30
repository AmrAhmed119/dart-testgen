import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:testgen/src/LLM/context_generator.dart';
import 'package:testgen/src/LLM/llm.dart';
import 'package:testgen/src/LLM/prompt_generator.dart';
import 'package:testgen/src/LLM/utils.dart';
import 'package:testgen/src/analyzer/declaration.dart';
import 'package:testgen/src/analyzer/extractor.dart';
import 'package:testgen/src/coverage/coverage_collection.dart';
import 'package:testgen/src/coverage/util.dart';

ArgParser _createArgParser() =>
    ArgParser()
      ..addOption(
        'package',
        defaultsTo: '.',
        help: 'Root directory of the package to test.',
      )
      ..addOption(
        'port',
        defaultsTo: '0',
        help: 'VM service port. Defaults to using any free port.',
      )
      ..addFlag(
        'function-coverage',
        abbr: 'f',
        defaultsTo: false,
        help: 'Collect function coverage info.',
      )
      ..addFlag(
        'branch-coverage',
        abbr: 'b',
        defaultsTo: false,
        help: 'Collect branch coverage info.',
      )
      ..addMultiOption(
        'scope-output',
        defaultsTo: [],
        help:
            'restrict coverage results so that only scripts that start with '
            'the provided package path are considered. Defaults to the name of '
            'the current package (including all subpackages, if this is a '
            'workspace).',
      )
      ..addOption(
        'model',
        defaultsTo: 'gemini-2.5-flash',
        help: 'The name of the LLM model to use for test generation.',
      )
      ..addOption(
        'api-key',
        help:
            'The API key required for authenticating requests to the service.',
      )
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

/// Contains all the options regarding coverage options or LLM options (to be added)
class Flags {
  const Flags({
    required this.package,
    required this.vmServicePort,
    required this.branchCoverage,
    required this.functionCoverage,
    required this.scopeOutput,
    required this.model,
    required this.apiKey,
  });

  final String package;
  final String vmServicePort;
  final bool branchCoverage;
  final bool functionCoverage;
  final Set<String> scopeOutput;
  final String model;
  final String apiKey;
}

Future<Flags> parseArgs(List<String> arguments) async {
  final parser = _createArgParser();
  final results = parser.parse(arguments);

  void printUsage() {
    print('''
To Be Updated

${parser.usage}
''');
  }

  Never fail(String msg) {
    print('\n$msg\n');
    printUsage();
    exit(1);
  }

  if (results['help'] as bool) {
    print(parser.usage);
    exit(0);
  }

  final packageDir = path.normalize(
    path.absolute(results['package'] as String),
  );
  if (!FileSystemEntity.isDirectorySync(packageDir)) {
    fail('--package is not a valid directory.');
  }

  final pubspecPath = getPubspecPath(packageDir);
  if (!File(pubspecPath).existsSync()) {
    fail(
      "Couldn't find $pubspecPath. Make sure this command is run in a "
      'package directory, or pass --package to explicitly set the directory.',
    );
  }

  final scopes =
      results['scope-output'].isEmpty
          ? getAllWorkspaceNames(packageDir)
          : results['scope-output'] as List<String>;

  if (scopes.length != 1) {
    fail(
      'Workspace support is not implemented yet. '
      'Please specify a single package scope.',
    );
  }

  final key =
      results['api-key'] as String? ?? Platform.environment['GEMINI_API_KEY'];
  if (key == null) {
    fail(
      'No API key provided. Please set the GEMINI_API_KEY environment variable '
      'or use the --api-key option.',
    );
  }

  return Flags(
    package: packageDir,
    vmServicePort: results['port'],
    branchCoverage: results['branch-coverage'],
    functionCoverage: results['function-coverage'],
    scopeOutput: scopes.toSet(),
    model: results['model'] as String,
    apiKey: key,
  );
}

Future<void> main(List<String> arguments) async {
  final flags = await parseArgs(arguments);
  final coverage = await runTestsAndCollectCoverage(
    flags.package,
    vmServicePort: flags.vmServicePort,
    branchCoverage: flags.branchCoverage,
    functionCoverage: flags.functionCoverage,
    scopeOutput: flags.scopeOutput,
  );
  final coverageByFile = formatCoverage(coverage);

  final declarations = await extractDeclarations(
    flags.package,
    flags.scopeOutput.first,
  );

  final Map<String, List<Declaration>> declarationsByFile = {};
  for (final declaration in declarations) {
    declarationsByFile.putIfAbsent(declaration.path, () => []).add(declaration);
  }

  final untestedDeclarations = extractUntestedDeclarations(
    declarationsByFile,
    coverageByFile,
  );

  final model = createModel(model: flags.model, apiKey: flags.apiKey);

  for (final (declaration, lines) in untestedDeclarations) {
    final toBeTestedCode = formatUntestedCode(declaration, lines);
    final contextMap = generateContextForDeclaration(declaration);
    final contextCode = formatContext(contextMap);
    final prompt = PromptGenerator.testCode(toBeTestedCode, contextCode);
    final response = await generateTest(model, prompt);
    final errors =
        response != null ? parseString(content: response.code).errors : [];

    if (errors.isNotEmpty || response == null || response.code.isEmpty) {
      // TODO: implement a retry mechanism (feedback loop)
    }

    if (response == null) {
      stderr.writeln(
        'Failed to generate test for ${declaration.name} (${declaration.id}).',
      );
      continue;
    }

    writeTestToFile(
      response,
      flags.package,
      '${declaration.name}_${declaration.id}_test.dart',
    );
  }

  exit(0);
}
