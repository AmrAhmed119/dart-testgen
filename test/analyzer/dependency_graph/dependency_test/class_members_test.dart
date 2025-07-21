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
        'class_members.dart',
      ),
      [
        'globalVar1',
        'globalFunc',
        'Logger',
        'log',
        'Class1',
        'field1',
        'method1',
        'StringExtension',
        'method2',
        'Enum',
        'value1',
        'code',
        'Class2',
        'field2',
        '_field3',
        '_field4',
        'conditionalVar',
        'Class2.named',
        'method3',
        'field4',
        'field3',
        'method4',
      ],
    );
  });

  group('Test Class Members Declarations Dependencies', () {
    test('Test Constructor Dependencies', () {
      expect(decls['Class2.named']!.dependsOn, hasLength(4));
      expect(
        decls['Class2.named']!.dependsOn,
        containsAll([
          decls['Class2'],
          decls['_field3'],
          decls['_field4'],
          decls['method3'],
        ]),
      );
    });

    test('Test Method Dependencies', () {
      expect(decls['method4']!.dependsOn, hasLength(11));
      expect(
        decls['method4']!.dependsOn,
        containsAll([
          decls['globalVar1'],
          decls['globalFunc'],
          decls['log'],
          decls['field1'],
          decls['method1'],
          decls['method2'],
          decls['Enum'],
          decls['value1'],
          decls['field2'],
          decls['field4'],
          decls['field3'],
        ]),
      );
    });

    test('Test Field Dependencies', () {
      expect(decls['field1']!.dependsOn, isEmpty);

      expect(decls['_field4']!.dependsOn, hasLength(1));
      expect(decls['_field4']!.dependsOn, contains(decls['Class2']));

      expect(decls['field4']!.dependsOn, hasLength(2));
      expect(
        decls['field4']!.dependsOn,
        containsAll([decls['_field4'], decls['Class2']]),
      );

      expect(decls['conditionalVar']!.dependsOn, hasLength(4));
      expect(
        decls['conditionalVar']!.dependsOn,
        containsAll([
          decls['globalVar1'],
          decls['Enum'],
          decls['value1'],
          decls['code'],
        ]),
      );
    });
  });
}
