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
        'top_level.dart',
      ),
      ['func2', 'func3'],
    );
  });

  group('Test Context for func2 and func3', () {
    test('Test Context of func2 at depth 1', () {
      final context = generateContextForDeclaration(decls['func2']!);
      final formattedContext = formatContext(context);
      expect(
        formattedContext,
        equals('''
// Code Snippet package path: package:testgen/..
class Class1 { 

// rest of the code... 

int field = 1; 

int method1() => 1; 

// rest of the code... 

} 

// Code Snippet package path: package:testgen/..
int var2 = 1; 

// Code Snippet package path: package:testgen/..
int func1() => 1; 

// Code Snippet package path: package:testgen/..
final var1 = Class1(); 

// Code Snippet package path: package:testgen/..
IntCallback var4 = (int x) => x * x; 

// Code Snippet package path: package:testgen/..
int var5 = var4(var2); 

// Code Snippet package path: package:testgen/..
final ClassList var6 = [Class1(), Class1()]; 

// Code Snippet package path: package:testgen/..
enum Enum { 

// rest of the code... 

value1 

// rest of the code... 

} 

// Code Snippet package path: package:testgen/..
extension Extension on int { 

// rest of the code... 

int method2() => 3; 

// rest of the code... 

} 

'''),
      );
    });

    test('Test Context of func3', () {
      final context = generateContextForDeclaration(decls['func3']!);
      final formattedContext = formatContext(context);
      expect(
        formattedContext,
        equals('''
// Code Snippet package path: package:testgen/..
class Class1 { 

// rest of the code... 

int field = 1; 

set fieldSetter(int value) {
    field = value;
  } 

// rest of the code... 

} 

// Code Snippet package path: package:testgen/..
int var2 = 1; 

// Code Snippet package path: package:testgen/..
int var3 =
    var2 +
    func1() +
    var1.field +
    var1.method1() +
    Enum.value1.index +
    3.method2(); 

'''),
      );
    });

    test('Test untested code of func2', () {
      final code = formatUntestedCode(decls['func2']!, <int>[6, 7, 8, 9, 10]);
      expect(
        code,
        equals('''
// Code Snippet package path: package:testgen/..


void func2(Class1 c1, Enum e) {
  print(Enum.value1.index);
  print(Class1().field);
  print(Class1().method1());
  print(1.method2());
  print(func1());
  print(var1); // UNTESTED
  print(var2); // UNTESTED
  print(var4(3)); // UNTESTED
  print(var5); // UNTESTED
  print(var6); // UNTESTED
}


'''),
      );
    });
  });
}
