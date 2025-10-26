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
        'enum_constants.dart',
      ),
      ['MyClass', 'MyClass.forEnum', 'MyEnum', 'value1', 'value2'],
    );
  });

  test('Test Enum Constants Dependencies', () {
    expect(decls['MyEnum']!.dependsOn, isEmpty);

    expect(decls['value1']!.dependsOn, hasLength(2));
    expect(
      decls['value1']!.dependsOn,
      containsAll([decls['MyClass']!, decls['MyClass.forEnum']!]),
    );

    expect(decls['value2']!.dependsOn, hasLength(2));
    expect(
      decls['value2']!.dependsOn,
      containsAll([decls['MyClass']!, decls['MyClass.forEnum']!]),
    );
  });
}
