import 'dart:collection';
import 'dart:io';

import 'package:args/args.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:testgen/src/LLM/context_generator.dart';
import 'package:testgen/src/LLM/model.dart';
import 'package:testgen/src/LLM/test_generator.dart';
import 'package:testgen/src/analyzer/declaration.dart';
import 'package:testgen/src/analyzer/extractor.dart';
import 'package:testgen/src/coverage/coverage_collection.dart';
import 'package:testgen/src/coverage/util.dart';

final _logger = Logger('testgen');

ArgParser _createArgParser() => ArgParser()
  ..addOption(
    'package',
    defaultsTo: '.',
    help: 'Root directory of the package to test.',
  )
  ..addMultiOption(
    'target-files',
    defaultsTo: [],
    help: 'Limit test generation to specific dart files inside the package.',
    valueHelp: 'lib/foo.dart,lib/src/temp.dart',
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
    help: 'Gemini API key for authentication (or set GEMINI_API_KEY env var).',
  )
  ..addOption(
    'max-depth',
    defaultsTo: '2',
    help: 'Maximum dependency depth for context generation.',
  )
  ..addOption(
    'max-attempts',
    defaultsTo: '5',
    help:
        'Maximum number of attempts to generate tests for each declaration on failure.',
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
    required this.targetFiles,
    required this.vmServicePort,
    required this.branchCoverage,
    required this.functionCoverage,
    required this.scopeOutput,
    required this.model,
    required this.apiKey,
    required this.effectiveTestsOnly,
    required this.maxDepth,
    required this.maxAttempts,
  });

  final String package;
  final List<String> targetFiles;
  final String vmServicePort;
  final bool branchCoverage;
  final bool functionCoverage;
  final Set<String> scopeOutput;
  final String model;
  final String apiKey;
  final bool effectiveTestsOnly;
  final int maxDepth;
  final int maxAttempts;
}

Future<Flags> parseArgs(List<String> arguments) async {
  final parser = _createArgParser();
  final results = parser.parse(arguments);

  void printUsage() {
    print('''
TestGen - LLM-based test generation tool

Generates comprehensive Dart unit tests using LLM (Gemini) for uncovered code.

Analyzes code coverage, identifies untested declarations, and creates targeted
tests to improve coverage metrics through an iterative validation process.

Usage: testgen [OPTIONS]

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

  final libDir = path.join(packageDir, 'lib');
  final targetFiles = (results['target-files'] as List<String>).map((file) {
    final fullPath = path.normalize(path.join(packageDir, file));

    if (!file.endsWith('.dart') ||
        !path.isWithin(libDir, fullPath) ||
        !FileSystemEntity.isFileSync(fullPath)) {
      fail('target-files must contain dart files exist inside lib directory');
    }
    return fullPath;
  }).toList();

  final scopes = results['scope-output'].isEmpty
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
    targetFiles: targetFiles,
    vmServicePort: results['port'],
    branchCoverage: results['branch-coverage'],
    functionCoverage: results['function-coverage'],
    scopeOutput: scopes.toSet(),
    model: results['model'] as String,
    apiKey: results['api-key'] as String,
    effectiveTestsOnly: results['effective-tests-only'] as bool,
    maxDepth: int.parse(results['max-depth'] as String),
    maxAttempts: int.parse(results['max-attempts'] as String),
  );
}

Future<void> main(List<String> arguments) async {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    print(
      '[${record.time}] [${record.loggerName}] [${record.level.name}] '
      '${record.message}',
    );
  });

  final flags = await parseArgs(arguments);
  final coverage = await runTestsAndCollectCoverage(
    flags.package,
    vmServicePort: flags.vmServicePort,
    branchCoverage: flags.branchCoverage,
    functionCoverage: flags.functionCoverage,
    scopeOutput: flags.scopeOutput,
  );
  final coverageByFile = await formatCoverage(coverage, flags.package);

  final declarations = await extractDeclarations(
    flags.package,
    targetFiles: flags.targetFiles,
  );

  final Map<String, List<Declaration>> declarationsByFile = {};
  for (final declaration in declarations) {
    declarationsByFile.putIfAbsent(declaration.path, () => []).add(declaration);
  }

  var untestedDeclarations = extractUntestedDeclarations(
    declarationsByFile,
    coverageByFile,
  );

  final model = GeminiModel(modelName: flags.model, apiKey: flags.apiKey);
  final testGenerator = TestGenerator(
    model: model,
    packagePath: flags.package,
    maxRetries: flags.maxAttempts,
  );

  final process = await Process.run('dart', [
    'pub',
    'add',
    'test',
  ], workingDirectory: flags.package);
  if (process.exitCode != 0) {
    _logger.shout('Failed to run dart pub add test');
    exit(1);
  }

  final skippedOrFailedDeclarations = HashSet<int>();

  while (untestedDeclarations.isNotEmpty) {
    final idx = untestedDeclarations.indexWhere(
      (pair) => !skippedOrFailedDeclarations.contains(pair.$1.id),
    );
    if (idx == -1) {
      break;
    }
    _logger.info(
      'Remaining untested declarations: '
      '${untestedDeclarations.length - skippedOrFailedDeclarations.length}',
    );
    final (declaration, lines) = untestedDeclarations[idx];

    final toBeTestedCode = formatUntestedCode(declaration, lines);
    final contextMap = buildDependencyContext(
      declaration,
      maxDepth: flags.maxDepth,
    );
    final contextCode = formatContext(contextMap);

    final result = await testGenerator.generate(
      toBeTestedCode: toBeTestedCode,
      contextCode: contextCode,
      fileName: '${declaration.name}_${declaration.id}_test.dart',
    );

    bool isTestDeleted = result.status != TestStatus.created;
    if (flags.effectiveTestsOnly && result.status == TestStatus.created) {
      final isImproved = await validateTestCoverageImprovement(
        declaration: declaration,
        baselineUncoveredLines: lines.length,
        packageDir: flags.package,
        scopeOutput: flags.scopeOutput,
        vmServicePort: flags.vmServicePort,
        branchCoverage: flags.branchCoverage,
        functionCoverage: flags.functionCoverage,
      );

      if (!isImproved) {
        _logger.info(
          'Generated tests for ${declaration.name} did not improve '
          'coverage. Discarding...\n',
        );
        await result.testFile.deleteTest();
        isTestDeleted = true;
      }
    }

    final newCoverage = await runTestsAndCollectCoverage(
      flags.package,
      vmServicePort: flags.vmServicePort,
      branchCoverage: flags.branchCoverage,
      functionCoverage: flags.functionCoverage,
      scopeOutput: flags.scopeOutput,
      isInternalCall: true,
    );
    final newCoverageByFile = await formatCoverage(newCoverage, flags.package);

    if (result.status == TestStatus.created && !isTestDeleted) {
      untestedDeclarations = extractUntestedDeclarations(
        declarationsByFile,
        newCoverageByFile,
      );
    } else {
      skippedOrFailedDeclarations.add(declaration.id);
    }
  }

  exit(0);
}
