// LLM-Generated test file created by testgen

import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as path;
import 'package:test_gen_ai/src/coverage/util.dart';

class MockFile extends Mock implements File {
  @override
  String readAsStringSync({Encoding encoding = utf8}) =>
      super.noSuchMethod(
            Invocation.method(#readAsStringSync, [], {#encoding: encoding}),
            returnValue: '',
          )
          as String;
}

void main() {
  group('getAllWorkspaceNames', () {
    test('should return all workspace names recursively', () {
      final rootPath = 'root';
      final rootPubspec = 'name: root_pkg\nworkspace:\n  - pkgs/a\n  - pkgs/b';
      final pkgAPubspec = 'name: pkg_a';
      final pkgBPubspec = 'name: pkg_b';

      IOOverrides.runZoned(
        () {
          final names = getAllWorkspaceNames(rootPath);
          expect(names, containsAll(['root_pkg', 'pkg_a', 'pkg_b']));
          expect(names.length, 3);
        },
        createFile: (String p) {
          final mockFile = MockFile();
          final normalizedPath = path.normalize(p);

          final rootPubspecPath = path.normalize(
            path.join(rootPath, 'pubspec.yaml'),
          );
          final pkgAPubspecPath = path.normalize(
            path.join(rootPath, 'pkgs', 'a', 'pubspec.yaml'),
          );
          final pkgBPubspecPath = path.normalize(
            path.join(rootPath, 'pkgs', 'b', 'pubspec.yaml'),
          );

          if (normalizedPath == rootPubspecPath) {
            when(
              mockFile.readAsStringSync(encoding: utf8),
            ).thenReturn(rootPubspec);
          } else if (normalizedPath == pkgAPubspecPath) {
            when(
              mockFile.readAsStringSync(encoding: utf8),
            ).thenReturn(pkgAPubspec);
          } else if (normalizedPath == pkgBPubspecPath) {
            when(
              mockFile.readAsStringSync(encoding: utf8),
            ).thenReturn(pkgBPubspec);
          }
          return mockFile;
        },
      );
    });

    test(
      'should return only the package name when no workspace is present',
      () {
        final rootPath = 'root';
        final rootPubspec = 'name: root_pkg';

        IOOverrides.runZoned(
          () {
            final names = getAllWorkspaceNames(rootPath);
            expect(names, equals(['root_pkg']));
          },
          createFile: (String p) {
            final mockFile = MockFile();
            if (path.normalize(p) ==
                path.normalize(path.join(rootPath, 'pubspec.yaml'))) {
              when(
                mockFile.readAsStringSync(encoding: utf8),
              ).thenReturn(rootPubspec);
            }
            return mockFile;
          },
        );
      },
    );
  });
}
