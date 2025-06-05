import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as path;
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
      ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

/// Contains all the options regarding coverage options or LLM options (to be added)
class Flags {
  const Flags({
    required this.package,
    required this.vmServicePort,
    required this.branchCoverage,
    required this.functionCoverage,
    required this.scopeOutput,
  });

  final String package;
  final String vmServicePort;
  final bool branchCoverage;
  final bool functionCoverage;
  final List<String> scopeOutput;
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
          : results['scope-output'];

  return Flags(
    package: packageDir,
    vmServicePort: results['port'],
    branchCoverage: results['branch-coverage'],
    functionCoverage: results['function-coverage'],
    scopeOutput: scopes,
  );
}

Future<void> main(List<String> arguments) async {
  await parseArgs(arguments);
}
