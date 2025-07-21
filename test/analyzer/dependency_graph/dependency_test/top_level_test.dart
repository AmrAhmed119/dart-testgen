import 'package:test/test.dart';
import 'package:testgen/src/analyzer/declaration.dart';
import 'package:path/path.dart' as path;

import '../../utils.dart';

void main() {
  late Map<String, Declaration> decls;

  setUpAll(() async {
    decls = await extractDeclarationsForSourceFile(
      path.join(
        'test',
        'analyzer',
        'dependency_graph',
        'code',
        'top_level.dart',
      ),
      [
        'Class1',
        'field',
        'method1',
        'Enum',
        'value1',
        'Extension',
        'method2',
        'func1',
        'var1',
        'var2',
        'var3',
        'func2',
        'IntCallback',
        'var4',
        'var5',
        'ClassList',
        'var6',
        'func3',
        'fieldSetter',
      ],
    );
  });

  group('Test Top Level Declarations Dependencies', () {
    test('Test Function Dependencies', () {
      expect(decls['func2']!.dependsOn, hasLength(12));
      expect(
        decls['func2']!.dependsOn,
        containsAll([
          decls['Class1'],
          decls['Enum'],
          decls['value1'],
          decls['field'],
          decls['method1'],
          decls['method2'],
          decls['func1'],
          decls['var1'],
          decls['var2'],
          decls['var4'],
          decls['var5'],
          decls['var6'],
        ]),
      );
      expect(decls['method2']!.parent, decls['Extension']);

      expect(decls['func3']!.dependsOn, hasLength(5));
      expect(
        decls['func3']!.dependsOn,
        containsAll([
          decls['Class1'],
          decls['field'],
          decls['fieldSetter'],
          decls['var2'],
          decls['var3'],
        ]),
      );
    });

    test('Test Variable Dependencies', () {
      expect(decls['var1']!.dependsOn, hasLength(1));
      expect(decls['var1']!.dependsOn, contains(decls['Class1']));

      expect(decls['var2']!.dependsOn, hasLength(0));

      expect(decls['var3']!.dependsOn, hasLength(8));
      expect(
        decls['var3']!.dependsOn,
        containsAll([
          decls['var2'],
          decls['func1'],
          decls['var1'],
          decls['field'],
          decls['method1'],
          decls['Enum'],
          decls['value1'],
          decls['method2'],
        ]),
      );

      expect(decls['var4']!.dependsOn, hasLength(1));
      expect(decls['var4']!.dependsOn, contains(decls['IntCallback']));

      expect(decls['var5']!.dependsOn, hasLength(2));
      expect(
        decls['var5']!.dependsOn,
        containsAll([decls['var4'], decls['var2']]),
      );

      expect(decls['var6']!.dependsOn, hasLength(2));
      expect(
        decls['var6']!.dependsOn,
        containsAll([decls['ClassList'], decls['Class1']]),
      );
    });
  });
}
