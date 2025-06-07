import 'dart:async';
import 'dart:io';

import 'package:coverage/coverage.dart';
import 'package:stack_trace/stack_trace.dart';
import 'package:testgen/src/coverage/util.dart';

typedef CoverageData = Map<String, dynamic>;

final _allProcesses = <Process>[];

Future<void> _dartRun(
  List<String> args,
  String packageDir, {
  required void Function(String) onStdout,
  required void Function(String) onStderr,
}) async {
  final process = await Process.start(
    Platform.executable,
    args,
    workingDirectory: packageDir,
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
  if (result != 0) {
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

Future<CoverageData> runTestsAndCollectCoverage(
  String packageDir,
  String vmServicePort,
  bool branchCoverage,
  bool functionCoverage,
  Set<String> scopeOutput,
) async {
  _watchExitSignal(ProcessSignal.sighup);
  _watchExitSignal(ProcessSignal.sigint);
  if (!Platform.isWindows) {
    _watchExitSignal(ProcessSignal.sigterm);
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
    packageDir,
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

  CoverageData coverage = {};
  await Chain.capture(
    () async {
      print("Collecting coverage from $packageDir");
      coverage = await collect(
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

  return coverage;
}
