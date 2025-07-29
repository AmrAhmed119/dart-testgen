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
        'compound.dart',
      ),
      ['ExtensionType'],
    );
  });

  group('Test Context for ExtensionType', () {
    test('Test Context of ExtensionType at depth 1', () {
      final context = generateContextForDeclaration(decls['ExtensionType']!);
      final formattedContext = formatContext(context);
      expect(
        formattedContext,
        equals('''
// Code Snippet package path: package:testgen/..
class Class1 { 

// Code Snippet package path: package:testgen/..
abstract class Abstract1 { 

// Code Snippet package path: package:testgen/..
abstract class Abstract2 { 

// Code Snippet package path: package:testgen/..
class Class2 extends Class1
    with Mixin1, Mixin2
    implements Abstract1, Abstract2 { 

'''),
      );
    });

    test('Test Context of ExtensionType at depth 2', () {
      final context = generateContextForDeclaration(
        decls['ExtensionType']!,
        maxDepth: 2,
      );
      final formattedContext = formatContext(context);
      expect(
        formattedContext,
        equals('''
// Code Snippet package path: package:testgen/..
class Class1 { 

// Code Snippet package path: package:testgen/..
abstract class Abstract1 { 

// Code Snippet package path: package:testgen/..
abstract class Abstract2 { 

// Code Snippet package path: package:testgen/..
class Class2 extends Class1
    with Mixin1, Mixin2
    implements Abstract1, Abstract2 { 

// Code Snippet package path: package:testgen/..
mixin Mixin1 { 

// Code Snippet package path: package:testgen/..
mixin Mixin2 { 

'''),
      );
    });
  });
}
