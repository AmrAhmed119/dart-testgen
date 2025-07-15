import 'package:test/test.dart';
import 'package:testgen/src/analyzer/declaration.dart';
import 'package:path/path.dart' as path;

import '../../utils.dart';

void main() {
  late List<Declaration> declarations;

  setUpAll(() async {
    declarations = await extractDeclarationsForSourceFile(
      path.join(
        'test',
        'analyzer',
        'dependency_graph',
        'code',
        'compound.dart',
      ),
    );
  });

  group('Test Compound Declarations Dependencies', () {
    final mixin1 = findDeclarationByName(declarations, 'Mixin1');
    final mixin2 = findDeclarationByName(declarations, 'Mixin2');
    final mixin3 = findDeclarationByName(declarations, 'Mixin2');

    final abstract1 = findDeclarationByName(declarations, 'Abstract1');
    final abstract2 = findDeclarationByName(declarations, 'Abstract2');
    final abstract3 = findDeclarationByName(declarations, 'Abstract3');

    final class1 = findDeclarationByName(declarations, 'Class1');
    final class2 = findDeclarationByName(declarations, 'Class2');

    final enum1 = findDeclarationByName(declarations, 'Enum');

    final extension = findDeclarationByName(declarations, 'Extension');

    final extensionType = findDeclarationByName(declarations, 'ExtensionType');

    test('Test (Abstract) Class Dependencies', () {
      expect(class2.dependsOn, hasLength(5));
      expect(
        class2.dependsOn,
        containsAll([class1, mixin1, mixin2, abstract1, abstract2]),
      );

      expect(abstract3.dependsOn, hasLength(4));
      expect(
        abstract3.dependsOn,
        containsAll([abstract1, mixin1, mixin2, abstract2]),
      );
    });

    test('Test Mixin Dependencies', () {
      expect(mixin3.dependsOn, hasLength(4));
      expect(mixin3.dependsOn, containsAll([mixin1, mixin2, class1, class2]));
    });

    test('Test Enum Dependencies', () {
      expect(enum1.dependsOn, hasLength(2));
      expect(enum1.dependsOn, containsAll([abstract1, abstract2]));
    });

    test('Test Extension Dependencies', () {
      expect(extension.dependsOn, hasLength(1));
      expect(extension.dependsOn, contains(class1));
    });

    test('Test Extension Type Dependencies', () {
      expect(extensionType.dependsOn, hasLength(4));
      expect(
        extensionType.dependsOn,
        containsAll([class2, class1, abstract1, abstract2]),
      );
    });
  });
}
