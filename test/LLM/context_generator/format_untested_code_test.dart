import 'package:test/test.dart';
import 'package:testgen/src/LLM/context_generator.dart';

import '../../utils.dart';

void main() {
  group('Untested code formatter output', () {
    test(
      'marks specified lines and omits parent context when parent is null',
      () {
        final decl = sampleDecl(
          1,
          path: 'package:test_pkg/src/foo.dart',
          sourceCode: [
            'bool process(int value) {',
            '  int a = value * 2;',
            '  int b = a + 3;',
            '  if (b > 10) {',
            '    print("Large value");',
            '  } else {',
            '    print("Small value");',
            '  }',
            '',
            '  for (int i = 0; i < b; i++) {',
            '    if (i % 2 == 0) {',
            '      print("even");',
            '    } else {',
            '      print("odd");',
            '    }',
            '  }',
            '',
            '  return b;',
            '}',
          ],
        );
        final formattedCode = formatUntestedCode(decl, [3, 4, 5, 10, 11, 12]);

        expect(
          formattedCode,
          equals('''
// Code Snippet package path: package:test_pkg/src/foo.dart
bool process(int value) {
  int a = value * 2;
  int b = a + 3;
  if (b > 10) {  // UNTESTED
    print("Large value");  // UNTESTED
  } else {  // UNTESTED
    print("Small value");
  }

  for (int i = 0; i < b; i++) {
    if (i % 2 == 0) {  // UNTESTED
      print("even");  // UNTESTED
    } else {  // UNTESTED
      print("odd");
    }
  }

  return b;
}
'''),
        );
      },
    );

    test(
      'includes parent context and wraps formatted code when parent is present',
      () {
        final parent = sampleDecl(
          2,
          path: 'package:test_pkg/src/parent.dart',
          sourceCode: ['class Parent extends Person {'],
        );
        final decl = sampleDecl(
          1,
          path: 'package:test_pkg/src/foo.dart',
          sourceCode: [
            '  bool process(int value) {',
            '    int a = value * 2;',
            '    int b = a + 3;',
            '    if (b > 10) {',
            '      print("Large value");',
            '    } else {',
            '      print("Small value");',
            '    }',
            '',
            '    return true;',
            '  }',
          ],
          parent: parent,
        );
        final formattedCode = formatUntestedCode(decl, [3, 4, 5]);

        expect(
          formattedCode,
          equals('''
// Code Snippet package path: package:test_pkg/src/foo.dart
class Parent extends Person {
  // rest of the code...

  bool process(int value) {
    int a = value * 2;
    int b = a + 3;
    if (b > 10) {  // UNTESTED
      print("Large value");  // UNTESTED
    } else {  // UNTESTED
      print("Small value");
    }

    return true;
  }

  // rest of the code...
}
'''),
        );
      },
    );
  });
}
