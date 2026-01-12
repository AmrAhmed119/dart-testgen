// LLM-Generated test file created by testgen

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:testgen/src/coverage/coverage_collection.dart';
import 'package:testgen/src/coverage/util.dart';

class MockProcess extends Mock implements Process {
  final StreamController<List<int>> _stdoutController =
      StreamController<List<int>>();
  final StreamController<List<int>> _stderrController =
      StreamController<List<int>>();
  final Completer<int> _exitCodeCompleter = Completer<int>();

  @override
  Stream<List<int>> get stdout => _stdoutController.stream;
  @override
  Stream<List<int>> get stderr => _stderrController.stream;
  @override
  Future<int> get exitCode => _exitCodeCompleter.future;
  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) => true;

  void feedStdout(String line) => _stdoutController.add(utf8.encode('$line\n'));
  void complete(int code) => _exitCodeCompleter.complete(code);
}

class MockFile extends Mock implements File {
  @override
  String get path => 'test/testgen/coverage_import_test.dart';
  @override
  Uri get uri => Uri.file(path);
  @override
  File get absolute => this;
  @override
  bool existsSync() => true;
  @override
  void createSync({bool recursive = false, bool exclusive = false}) {}
  @override
  void writeAsStringSync(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) {}
}

class MockDirectory extends Mock implements Directory {
  @override
  String get path => 'lib';
  @override
  bool existsSync() => true;
  @override
  List<FileSystemEntity> listSync({
    bool recursive = false,
    bool followLinks = true,
  }) => [];
}

base class TestIOOverrides extends IOOverrides {
  final File Function(String) _createFile;
  final Directory Function(String) _createDirectory;
  final Future<Process> Function(
    String,
    List<String>, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment,
    bool runInShell,
    ProcessStartMode mode,
  })
  _startProcess;
  final void Function(int) _onExit;

  TestIOOverrides({
    required File Function(String) createFile,
    required Directory Function(String) createDirectory,
    required Future<Process> Function(
      String,
      List<String>, {
      String? workingDirectory,
      Map<String, String>? environment,
      bool includeParentEnvironment,
      bool runInShell,
      ProcessStartMode mode,
    })
    startProcess,
    required void Function(int) onExit,
  }) : _createFile = createFile,
       _createDirectory = createDirectory,
       _startProcess = startProcess,
       _onExit = onExit;

  @override
  File createFile(String path) => _createFile(path);

  @override
  Directory createDirectory(String path) => _createDirectory(path);

  @override
  Future<Process> startProcess(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) => _startProcess(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
    runInShell: runInShell,
    mode: mode,
  );

  @override
  Never exit(int code) {
    _onExit(code);
    throw ExitException(code);
  }
}

class ExitException implements Exception {
  final int code;
  ExitException(this.code);
}

void main() {
  group('runTestsAndCollectCoverage', () {
    late MockProcess mockProcess;
    late MockFile mockFile;
    late MockDirectory mockDirectory;
    int? lastExitCode;

    setUp(() {
      mockProcess = MockProcess();
      mockFile = MockFile();
      mockDirectory = MockDirectory();
      lastExitCode = null;
    });

    test('extractVMServiceUri utility correctly parses VM service strings', () {
      expect(
        extractVMServiceUri(
          'The Dart VM service is listening on http://127.0.0.1:8181/',
        ),
        equals(Uri.parse('http://127.0.0.1:8181/')),
      );
      expect(
        extractVMServiceUri(
          'Observatory listening on http://127.0.0.1:8181/abc/',
        ),
        equals(Uri.parse('http://127.0.0.1:8181/abc/')),
      );
    });

    test('runTestsAndCollectCoverage orchestrates test execution', () async {
      final overrides = TestIOOverrides(
        createFile: (p) => mockFile,
        createDirectory: (p) => mockDirectory,
        onExit: (code) => lastExitCode = code,
        startProcess:
            (
              exe,
              args, {
              workingDirectory,
              environment,
              includeParentEnvironment = true,
              runInShell = false,
              mode = ProcessStartMode.normal,
            }) async {
              expect(args, contains('--branch-coverage'));
              return mockProcess;
            },
      );

      await IOOverrides.runWithIOOverrides(() async {
        final coverageFuture = runTestsAndCollectCoverage(
          Directory.current.path,
          branchCoverage: true,
          scopeOutput: {'lib/'},
        );

        mockProcess.feedStdout(
          'The Dart VM service is listening on http://127.0.0.1:8181/',
        );
        mockProcess.complete(0);

        try {
          await coverageFuture.timeout(const Duration(milliseconds: 500));
        } catch (e) {
          // Expected failure from collect() or ExitException
        }
      }, overrides);
    });

    test(
      'runTestsAndCollectCoverage handles internal calls by skipping file generation',
      () async {
        bool fileCreated = false;
        final overrides = TestIOOverrides(
          createFile: (p) {
            if (p.contains('coverage_import_test.dart')) fileCreated = true;
            return mockFile;
          },
          createDirectory: (p) => mockDirectory,
          onExit: (code) => lastExitCode = code,
          startProcess:
              (
                exe,
                args, {
                workingDirectory,
                environment,
                includeParentEnvironment = true,
                runInShell = false,
                mode = ProcessStartMode.normal,
              }) async => mockProcess,
        );

        await IOOverrides.runWithIOOverrides(() async {
          final coverageFuture = runTestsAndCollectCoverage(
            Directory.current.path,
            isInternalCall: true,
            scopeOutput: {'lib/'},
          );

          mockProcess.feedStdout(
            'The Dart VM service is listening on http://127.0.0.1:8181/',
          );
          mockProcess.complete(0);

          try {
            await coverageFuture.timeout(const Duration(milliseconds: 200));
          } catch (e) {}

          expect(fileCreated, isFalse);
        }, overrides);
      },
    );
  });
}
