import 'dart:io';

import 'package:package_config/package_config.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import 'package:testgen/testgen.dart';

import '../../utils.dart';

void main() {
  final testPackage = path.normalize(
    path.absolute(path.joinAll(testPackagePath)),
  );

  group('Test declarations extraction', () {
    test('Test extraction from all files inside the package', () async {
      final config = await findPackageConfig(Directory(testPackage));
      final decls = await extractDeclarations(testPackage);

      final actualFiles = decls.map((d) => d.path).toSet();
      final expectedFiles =
          Directory(testPackage)
              .listSync(recursive: true)
              .whereType<File>()
              .where((file) => file.path.endsWith('.dart'))
              .map((file) {
                return config?.toPackageUri(file.absolute.uri).toString();
              })
              .toSet();

      expect(expectedFiles, actualFiles);
    });

    test('Test extraction for target files inside the package', () async {
      final config = await findPackageConfig(Directory(testPackage));
      final targetFiles = [
        path.join(testPackage, 'lib', 'parser', 'code.dart'),
        path.join(testPackage, 'lib', 'dependency_graph', 'top_level.dart'),
      ];
      final decls = await extractDeclarations(
        testPackage,
        targetFiles: targetFiles,
      );

      final actualFiles = decls.map((d) => d.path).toSet();
      final expectedFiles =
          targetFiles.map((file) {
            return config?.toPackageUri(File(file).absolute.uri).toString();
          }).toSet();

      expect(expectedFiles, hasLength(2));
      expect(expectedFiles, actualFiles);
    });
  });
}
