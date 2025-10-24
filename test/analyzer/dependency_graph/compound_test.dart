import 'package:test/test.dart';
import 'package:testgen/src/analyzer/declaration.dart';
import 'package:path/path.dart' as path;

import '../../utils.dart';

void main() {
  late Map<String, Declaration> decls;

  setUpAll(() async {
    decls = await extractNamedDeclarationsFromFile(
      path.join(
        'test',
        'fixtures',
        'test_package',
        'lib',
        'dependency_graph',
        'compound.dart',
      ),
      [
        'Mixin1',
        'Mixin2',
        'Mixin3',
        'Abstract1',
        'Abstract2',
        'Abstract3',
        'Class1',
        'Class2',
        'Enum',
        'Extension',
        'ExtensionType',
      ],
    );
  });

  group('Test Compound Declarations Dependencies', () {
    test('Test (Abstract) Class Dependencies', () {
      expect(decls['Class2']!.dependsOn, hasLength(5));
      expect(
        decls['Class2']!.dependsOn,
        containsAll([
          decls['Class1'],
          decls['Mixin1'],
          decls['Mixin2'],
          decls['Abstract1'],
          decls['Abstract2'],
        ]),
      );

      expect(decls['Abstract3']!.dependsOn, hasLength(4));
      expect(
        decls['Abstract3']!.dependsOn,
        containsAll([
          decls['Abstract1'],
          decls['Mixin1'],
          decls['Mixin2'],
          decls['Abstract2'],
        ]),
      );
    });

    test('Test Mixin Dependencies', () {
      expect(decls['Mixin3']!.dependsOn, hasLength(4));
      expect(
        decls['Mixin3']!.dependsOn,
        containsAll([
          decls['Mixin1'],
          decls['Mixin2'],
          decls['Class1'],
          decls['Class2'],
        ]),
      );
    });

    test('Test Enum Dependencies', () {
      expect(decls['Enum']!.dependsOn, hasLength(2));
      expect(
        decls['Enum']!.dependsOn,
        containsAll([decls['Abstract1'], decls['Abstract2']]),
      );
    });

    test('Test Extension Dependencies', () {
      expect(decls['Extension']!.dependsOn, hasLength(1));
      expect(decls['Extension']!.dependsOn, contains(decls['Class1']));
    });

    test('Test Extension Type Dependencies', () {
      expect(decls['ExtensionType']!.dependsOn, hasLength(4));
      expect(
        decls['ExtensionType']!.dependsOn,
        containsAll([
          decls['Class2'],
          decls['Class1'],
          decls['Abstract1'],
          decls['Abstract2'],
        ]),
      );
    });
  });
}
