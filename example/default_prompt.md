Generate a Dart unit test for the following code:

```dart
// Code Snippet package path: package:testing/src/globals.dart
void function(int x) {  // UNTESTED
  if (x == 1) {  // UNTESTED
    Person person = Person();  // UNTESTED
    person.greet();  // UNTESTED
  } else {
    globalFunction(globalVar);  // UNTESTED
    Animal animal = Animal('Dog', 4);  // UNTESTED
    animal.makeSound();  // UNTESTED
    animal.walk();  // UNTESTED
  }
}

```

With the following context:
```dart
// Code Snippet package path: package:testing/src/testing_base.dart
int add(int a, int b) {
  int res = a + b;
  int x = a - b;
  return res;
}

// Code Snippet package path: package:testing/src/globals.dart
int globalFunction(int x) {
  return add(x, x);
}

// Code Snippet package path: package:testing/src/globals.dart
int globalVar = 42;

// Code Snippet package path: package:testing/src/person.dart
class Person {
  // rest of the code...

int age = 1;

void greet() {
    print('Hello, my name is $name and I am $age years old.');
  }

String name = 'John Doe';

  // rest of the code...
}

// Code Snippet package path: package:testing/src/animal.dart
class Animal extends ParentClass {
  // rest of the code...

int legs;

void makeSound() {
    print('The $type makes a sound.');
    parentMethod();
  }

String type;

void walk() {
    print('The $type walks on its $legs legs.');
  }

  // rest of the code...
}

// Code Snippet package path: package:testing/src/animal.dart
class ParentClass {
  // rest of the code...

/// protected method
  void parentMethod() {
    print('This is a method from the ParentClass.');
  }

  // rest of the code...
}

```

Requirements:
- Test ONLY the lines marked with `// UNTESTED` - ignore already tested code.
- The provided code is partial, showing only relevant members.
- Use appropriate mocking for external dependencies.
- If the code is trivial or untestable, set "needTesting": false and leave "code" empty (don't generate any code).
- Skip generating tests for private members (those starting with `_`).
- Primarily use the `test` package for writing tests, avoiding using `mockito` package.
- Use the actual classes and methods from the codebase - import the necessary packages instead of creating mock or temporary classes.
- Import any other required Dart packages (e.g., `async`, `test`, etc.) as needed.
- Follow Dart testing best practices with descriptive test names.

Return the complete test file with proper imports and test structure.
