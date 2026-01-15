import 'package:test/test.dart';
import 'package:testgen/src/LLM/context_generator.dart';
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
        'class_members.dart',
      ),
      ['method4'],
    );
  });

  group('Test Context for method4', () {
    test('Test context of method4 at depth 1', () {
      final context = buildDependencyContext(decls['method4']!, maxDepth: 1);
      final formattedContext = formatContext(context);
      expect(
        formattedContext,
        equals('''
// Code Snippet package path: package:test_package/dependency_graph/class_members.dart
void globalFunc(int x) {}

// Code Snippet package path: package:test_package/dependency_graph/class_members.dart
int globalVar1 = 30;

// Code Snippet package path: package:test_package/dependency_graph/class_members.dart
enum Enum {
  // rest of the code...

value1(0)

  // rest of the code...
}

// Code Snippet package path: package:test_package/dependency_graph/class_members.dart
mixin Logger {
  // rest of the code...

void log(String msg) {}

  // rest of the code...
}

// Code Snippet package path: package:test_package/dependency_graph/class_members.dart
class Class1 {
  // rest of the code...

String field1 = 'test';

void method1() {}

  // rest of the code...
}

// Code Snippet package path: package:test_package/dependency_graph/class_members.dart
extension StringExtension on String {
  // rest of the code...

void method2() {}

  // rest of the code...
}

// Code Snippet package path: package:test_package/dependency_graph/class_members.dart
class Class2 extends Class1 with Logger {
  // rest of the code...

String field2 = 'name';

set field3(int i) => _field3 = i;

Class2? get field4 => _field4;

  // rest of the code...
}
'''),
      );
    });

    test('Test untested code of method4', () {
      final code = formatUntestedCode(decls['method4']!, <int>[2, 3, 10, 11]);
      expect(
        code,
        equals('''
// Code Snippet package path: package:test_package/dependency_graph/class_members.dart
class Class2 extends Class1 with Logger {
  // rest of the code...

void method4() {
    print(globalVar1);
    globalFunc(1);  // UNTESTED
    log('test');  // UNTESTED
    print(field1);
    method1();
    'test'.method2();
    print(Enum.value1);
    print(field2);
    print(field4);
    field3 = 3;  // UNTESTED
    method4();  // UNTESTED
  }

  // rest of the code...
}
'''),
      );
    });
  });
}
