import 'dart:async';
import 'dart:convert' show json, LineSplitter;
import 'dart:io';

import 'package:coverage/coverage.dart';
import 'package:stack_trace/stack_trace.dart';

final _allProcesses = <Process>[];

void _killSubprocessesAndExit(ProcessSignal signal) {
  for (final process in _allProcesses) {
    process.kill(signal);
  }
  exit(1);
}

void _watchExitSignal(ProcessSignal signal) {
  signal.watch().listen(_killSubprocessesAndExit);
}

Future<Map<String, dynamic>> getTestCoverage(String packagRootDirectory) async {
  _watchExitSignal(ProcessSignal.sighup);
  _watchExitSignal(ProcessSignal.sigint);
  if (!Platform.isWindows) {
    _watchExitSignal(ProcessSignal.sigterm);
  }

  final serviceUriCompleter = Completer<Uri>();

  final testProcess = _dartRun(
    [
      'run',
      '--pause-isolates-on-exit',
      '--disable-service-auth-codes',
      '--enable-vm-service=0',
      'test',
    ],
    onStdout: (line) {
      if (!serviceUriCompleter.isCompleted) {
        final uri = _extractVMServiceUri(line);
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
    workingDirectory: packagRootDirectory,
  );

  final serviceUri = await serviceUriCompleter.future;

  // TODO: need to extract the scope output from the pubsec.yaml file
  final Set<String> scopes = {};
  Map<String, dynamic>? coverage;
  await Chain.capture(
    () async {
      print("Collecting coverage from $packagRootDirectory");
      coverage = await collect(
        serviceUri,
        true,
        true,
        false,
        scopes,
        functionCoverage: true,
      );
      print(json.encode(coverage));
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
  return coverage!;
}

Future<void> _dartRun(
  List<String> args, {
  required void Function(String) onStdout,
  required void Function(String) onStderr,
  required String workingDirectory,
}) async {
  final process = await Process.start(
    Platform.executable,
    args,
    workingDirectory: workingDirectory,
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

Uri? _extractVMServiceUri(String str) {
  final listeningMessageRegExp = RegExp(
    r'(?:Observatory|The Dart VM service is) listening on ((http|//)[a-zA-Z0-9:/=_\-\.\[\]]+)',
  );
  final match = listeningMessageRegExp.firstMatch(str);
  if (match != null) {
    return Uri.parse(match[1]!);
  }
  return null;
}

extension StandardOutExtension on Stream<List<int>> {
  Stream<String> lines() =>
      transform(const SystemEncoding().decoder).transform(const LineSplitter());
}
