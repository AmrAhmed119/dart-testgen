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
        'type_alias.dart',
      ),
      ['Class1', 'Class2', 'Alias1', 'Alias2', 'Alias3', 'Alias4'],
    );
  });

  test('Test Type Alias Dependencies', () {
    expect(decls['Alias1']!.dependsOn, hasLength(2));
    expect(
      decls['Alias1']!.dependsOn,
      containsAll([decls['Class1'], decls['Class2']]),
    );

    expect(decls['Alias2']!.dependsOn, hasLength(1));
    expect(decls['Alias1']!.dependsOn, contains(decls['Class1']));

    expect(decls['Alias3']!.dependsOn, hasLength(1));
    expect(decls['Alias3']!.dependsOn, contains(decls['Class2']));

    expect(decls['Alias4']!.dependsOn, hasLength(2));
    expect(
      decls['Alias4']!.dependsOn,
      containsAll([decls['Class1'], decls['Class2']]),
    );
  });
}
