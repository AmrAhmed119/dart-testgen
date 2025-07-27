import 'package:test/test.dart';
import 'package:testgen/src/LLM/context_generator.dart';
import 'package:testgen/src/analyzer/declaration.dart';
import 'package:path/path.dart' as path;

import '../analyzer/utils.dart';

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
      ['method4'],
    );
  });

  group('Test Context for method4', () {
    test('Test context of method4 at depth 1', () {
      final context = generateContextForDeclaration(decls['method4']!);
      final formattedContext = formatContext(context);
      expect(
        formattedContext,
        equals('''
// Code Snippet package path: package:testgen/..
int globalVar1 = 30; 

// Code Snippet package path: package:testgen/..
void globalFunc(int x) {} 

// Code Snippet package path: package:testgen/..
enum Enum { 

// rest of the code... 

value1(0) 

// rest of the code... 

} 

// Code Snippet package path: package:testgen/..
mixin Logger { 

// rest of the code... 

void log(String msg) {} 

// rest of the code... 

} 

// Code Snippet package path: package:testgen/..
class Class1 { 

// rest of the code... 

String field1 = 'test'; 

void method1() {} 

// rest of the code... 

} 

// Code Snippet package path: package:testgen/..
extension StringExtension on String { 

// rest of the code... 

void method2() {} 

// rest of the code... 

} 

// Code Snippet package path: package:testgen/..
class Class2 extends Class1 with Logger { 

// rest of the code... 

String field2 = 'name'; 

Class2? get field4 => _field4; 

set field3(int i) => _field3 = i; 

// rest of the code... 

} 

'''),
      );
    });
  });
}
