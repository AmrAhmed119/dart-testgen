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
        'type_alias.dart',
      ),
      ['Class1', 'Class2', 'alias1', 'alias2', 'alias3', 'alias4'],
    );
  });

  test('Test Type Alias Dependencies', () {
    expect(decls['alias1']!.dependsOn, hasLength(2));
    expect(
      decls['alias1']!.dependsOn,
      containsAll([decls['Class1'], decls['Class2']]),
    );

    expect(decls['alias2']!.dependsOn, hasLength(1));
    expect(decls['alias1']!.dependsOn, contains(decls['Class1']));

    expect(decls['alias3']!.dependsOn, hasLength(1));
    expect(decls['alias3']!.dependsOn, contains(decls['Class2']));

    expect(decls['alias4']!.dependsOn, hasLength(2));
    expect(
      decls['alias4']!.dependsOn,
      containsAll([decls['Class1'], decls['Class2']]),
    );
  });
}
