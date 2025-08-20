import 'dart:async';
import 'dart:io';

import 'package:coverage/coverage.dart';
import 'package:package_config/package_config.dart';
import 'package:path/path.dart' as path;
import 'package:stack_trace/stack_trace.dart';
import 'package:testgen/src/analyzer/declaration.dart';
import 'package:testgen/src/analyzer/extractor.dart';
import 'package:testgen/src/coverage/util.dart';

typedef CoverageData = List<(String, List<int>)>;

final _allProcesses = <Process>[];
bool _isSignalsWatched = false;

Future<void> _dartRun(
  List<String> args, {
  required String packageAbsolutePath,
  required void Function(String) onStdout,
  required void Function(String) onStderr,
}) async {
  final process = await Process.start(
    Platform.executable,
    args,
    workingDirectory: packageAbsolutePath,
  );
  _allProcesses.add(process);

  void listen(
    Stream<List<int>> stream,
    IOSink sink,
    void Function(String) onLine,
  ) {
    final broadStream = stream.asBroadcastStream();
    broadStream.listen(sink.add);
    broadStream.lines().listen(onLine);
  }

  listen(process.stdout, stdout, onStdout);
  listen(process.stderr, stderr, onStderr);

  final result = await process.exitCode;

  // Don't throw an error if the process exits with code 79 which is
  // common for no tests found.
  if (result != 0 && result != 79) {
    throw ProcessException(Platform.executable, args, '', result);
  }
}

void _killSubprocessesAndExit(ProcessSignal signal) {
  for (final process in _allProcesses) {
    process.kill(signal);
  }
  exit(1);
}

void _watchExitSignal(ProcessSignal signal) {
  signal.watch().listen(_killSubprocessesAndExit);
}

/// Runs Dart tests in the specified package directory and collects coverage data.
///
/// This function starts a Dart test process with the appropriate VM service
/// and coverage flags, waits for the VM service URI to become available,
/// and then collects coverage data from all isolates in the running Dart VM.
/// The collected coverage data is returned as a map of coverage information.
///
/// [packageDir] specifies the root directory of the Dart package to test.
///
/// [vmServicePort] specifies the port to use for the Dart VM service,
/// default is '0', which means it will use any available port.
///
/// [branchCoverage] enables branch coverage collection if true.
///
/// [functionCoverage] enables function-level coverage collection if true.
///
/// [scopeOutput] restricts coverage output to scripts that start with
/// any of the provided paths.
///
/// Returns a [CoverageData] map containing the merged coverage information for all isolates.
Future<Map<String, dynamic>> runTestsAndCollectCoverage(
  String packageDir, {
  String vmServicePort = '0',
  bool branchCoverage = false,
  bool functionCoverage = false,
  required Set<String> scopeOutput,
}) async {
  if (!_isSignalsWatched) {
    _watchExitSignal(ProcessSignal.sighup);
    _watchExitSignal(ProcessSignal.sigint);
    if (!Platform.isWindows) {
      _watchExitSignal(ProcessSignal.sigterm);
    }
    _isSignalsWatched = true;
  }

  final serviceUriCompleter = Completer<Uri>();
  final testProcess = _dartRun(
    [
      if (branchCoverage) '--branch-coverage',
      'run',
      '--pause-isolates-on-exit',
      '--disable-service-auth-codes',
      '--enable-vm-service=$vmServicePort',
      'test',
    ],
    packageAbsolutePath: packageDir,
    onStdout: (line) {
      if (!serviceUriCompleter.isCompleted) {
        final uri = extractVMServiceUri(line);
        if (uri != null) {
          serviceUriCompleter.complete(uri);
        }
      }
    },
    onStderr: (line) {
      if (!serviceUriCompleter.isCompleted) {
        if (line.contains('Could not start the VM service')) {
          _killSubprocessesAndExit(ProcessSignal.sigkill);
        }
      }
    },
  );

  final serviceUri = await serviceUriCompleter.future;

  final coverageResults = await Chain.capture(
    () async {
      return await collect(
        serviceUri,
        true,
        true,
        false,
        scopeOutput,
        branchCoverage: branchCoverage,
        functionCoverage: functionCoverage,
      );
    },
    onError: (dynamic error, Chain chain) {
      stderr.writeln(error);
      stderr.writeln(chain.terse);
      // See http://www.retro11.de/ouxr/211bsd/usr/include/sysexits.h.html
      // EX_SOFTWARE
      exit(70);
    },
  );

  await testProcess;

  await _addUntrackedFiles(coverageResults, packageDir);

  return coverageResults;
}

/// Files that are never imported or touched by any test are completely missing
/// from coverage data which only tracks files that are executed during tests.
///
/// This function finds those untracked files in the lib directory and adds them
/// to the coverage results with all lines marked as uncovered so they can be
/// identified for test generation.
Future<void> _addUntrackedFiles(
  Map<String, dynamic> coverageResults,
  String packageDir,
) async {
  final List<Map<String, dynamic>> coverage = coverageResults['coverage'];

  final config = await loadPackageConfig(
    File(path.join(packageDir, '.dart_tool', 'package_config.json')),
  );

  final trackedFiles =
      coverage.map((entry) => entry['source'] as String).toSet();

  final untrackedFiles = Directory(path.join(packageDir, 'lib'))
      .listSync(recursive: true)
      .whereType<File>()
      .map((file) => file.path)
      .where(
        (filePath) =>
            filePath.endsWith('.dart') &&
            !trackedFiles.contains(
              config.toPackageUri(File(filePath).uri).toString(),
            ),
      );

  for (final filePath in untrackedFiles) {
    coverage.add({
      'source': config.toPackageUri(File(filePath).uri).toString(),
      'hits': _markAllLinesAsUntested(filePath),
    });
  }
}

List<int> _markAllLinesAsUntested(String filePath) {
  final file = File(filePath);
  final lineCount = file.readAsLinesSync().length;

  return Iterable<int>.generate(
    lineCount,
  ).expand((lineNum) => [lineNum + 1, 0]).toList();
}

/// Formats raw coverage results into a [CoverageData] structure.
///
/// [CoverageData] is a `List<(String, List<int>)>` where:
///   - The first element is the package path of a Dart source file.
///   - The second element is a list of line numbers in that file which were
///     not hit by any test case (i.e., lines that require additional testing).
Future<CoverageData> formatCoverage(
  Map<String, dynamic> coverageResults,
  String packageDir,
) async {
  final List<Map<String, dynamic>> coverage = coverageResults['coverage'];
  final hitmaps = await HitMap.parseJson(coverage, packagePath: packageDir);
  return hitmaps.entries
      .map(
        (fileHits) => (
          fileHits.key,
          fileHits.value.lineHits.entries
              .where((lineHit) => lineHit.value == 0)
              .map((lineHit) => lineHit.key)
              .toList(),
        ),
      )
      .where((fileHits) => fileHits.$2.isNotEmpty)
      .toList();
}

/// Evaluates whether a generated test file has successfully improved code
/// coverage for a specific declaration.
///
/// This function runs test after a new test has been generated and compares
/// the current coverage metrics against the baseline coverage metrics that were
/// recorded before test generation. It determines if the newly generated test
/// is actually hitting the previously uncovered lines.
Future<bool> validateTestCoverageImprovement(
  String packageDir,
  Declaration declaration,
  int baselineUncoveredLines, {
  required Set<String> scopeOutput,
  required Map<String, List<Declaration>> declarationsByFile,
}) async {
  final coverage = await runTestsAndCollectCoverage(
    packageDir,
    scopeOutput: scopeOutput,
  );
  final coverageByFile = await formatCoverage(coverage, packageDir);

  final untestedDeclarations = extractUntestedDeclarations(
    declarationsByFile,
    coverageByFile,
  );

  final currentStatus =
      untestedDeclarations.where((d) => d.$1.id == declaration.id).firstOrNull;

  final currentUncoveredLines = currentStatus?.$2.length ?? 0;

  print(
    '📊 Coverage analysis for ${declaration.name}:\n'
    '   • Baseline uncovered lines: $baselineUncoveredLines\n'
    '   • Current uncovered lines: $currentUncoveredLines\n'
    '   • Coverage improved: ${currentUncoveredLines < baselineUncoveredLines}',
  );
  return currentUncoveredLines < baselineUncoveredLines;
}
