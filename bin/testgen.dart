import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
import 'package:testgen/src/LLM/context_generator.dart';
import 'package:testgen/src/LLM/llm.dart';
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
        defaultsTo: 'gemini-2.5-pro',
        help: 'Gemini model to use for generating tests.',
      )
      ..addOption(
        'api-key',
        defaultsTo: Platform.environment['GEMINI_API_KEY'],
        help:
            'Gemini API key for authentication (or set GEMINI_API_KEY env var).',
      )
      ..addFlag(
        'effective-tests-only',
        defaultsTo: false,
        help:
            'Restrict test generation to only create tests that increase coverage.',
      )
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

class Flags {
  const Flags({
    required this.package,
    required this.vmServicePort,
    required this.branchCoverage,
    required this.functionCoverage,
    required this.scopeOutput,
    required this.model,
    required this.apiKey,
    required this.effectiveTestsOnly,
  });

  final String package;
  final String vmServicePort;
  final bool branchCoverage;
  final bool functionCoverage;
  final Set<String> scopeOutput;
  final String model;
  final String apiKey;
  final bool effectiveTestsOnly;
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

  if (results['api-key'] == null) {
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
    apiKey: results['api-key'] as String,
    effectiveTestsOnly: results['effective-tests-only'] as bool,
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

  final process = await Process.run('dart', [
    'pub',
    'add',
    'test',
  ], workingDirectory: flags.package);
  if (process.exitCode != 0) {
    print('Failed to run dart pub add test');
    exit(1);
  }

  int done = 0;
  for (final (declaration, lines) in untestedDeclarations) {
    print('${untestedDeclarations.length - done} remaining');
    done++;
    final toBeTestedCode = formatUntestedCode(declaration, lines);
    final contextMap = generateContextForDeclaration(declaration, maxDepth: 5);
    final contextCode = formatContext(contextMap);

    final (status, chat, testFileManager) = await generateTestFile(
      model,
      toBeTestedCode,
      contextCode,
      flags.package,
      '${declaration.name}_${declaration.id}_test.dart',
    );
    if (status == TestStatus.created) {
      if (flags.effectiveTestsOnly) {
        final isImproved = await validateTestCoverageImprovement(
          flags.package,
          declaration,
          lines.length,
          scopeOutput: flags.scopeOutput,
          declarationsByFile: declarationsByFile,
        );
        if (isImproved) {
          print('✅ Test improved coverage for ${declaration.name}.');
        } else {
          print(
            '❌ Test did not improve coverage for ${declaration.name}. '
            'Deleting test file.',
          );
          testFileManager.deleteTest();
        }
      }
    }
  }

  exit(0);
}
