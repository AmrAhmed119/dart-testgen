Generate a Dart test cases for the following code:

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
// Code Snippet package path: package:testing/src/globals.dart
int globalFunction(int x) {
  return add(x, x);
}

// Code Snippet package path: package:testing/src/globals.dart
int globalVar = 42;

// Code Snippet package path: package:testing/src/person.dart
class Person {
  // rest of the code...

void greet() {
    print('Hello, my name is $name and I am $age years old.');
  }

  // rest of the code...
}

// Code Snippet package path: package:testing/src/animal.dart
class Animal extends ParentClass {
  // rest of the code...

void makeSound() {
    log.info("makeSound is called");
    parentMethod();
  }

void walk() {
    log.info("walk is called");
  }

  // rest of the code...
}

```

You must first decide the most appropriate test type for the code:
- "unit": when the logic can be tested in isolation using mocks.
- "integration": when the logic orchestrates multiple components, interacts with the filesystem, runs processes, or is not suitable for unit testing.
- "none": when the code is trivial or not meaningfully testable.

Integration tests MUST:
- Be deterministic and runnable in CI.
- NOT call any external APIs.
- NOT require API keys or environment variables.
- Avoid network access.
- Prefer real implementations over mocks.

Unit tests SHOULD:
- Test behavior in isolation.
- Use mocks only when necessary.

Requirements:
- Test ONLY the lines marked with `// UNTESTED`; ignore already tested code.
- The provided code is partial and shows only relevant members.
- Skip generating tests for private members (those starting with `_`).
- If the code is trivial or untestable, set "needTesting": false and leave "code" empty.
- For unit tests:
  - Primarily use the `dart:test` package.
  - Use mocking only if required using `dart:mockito` package.
  - Extend mock classes from `Mock` directly; do NOT rely on code generation or build_runner.
- For integration tests:
  - Avoid mocking unless strictly unavoidable.
  - Exercise real code paths where possible.
  - Use temp directories or in-memory filesystems for file operations.
- Use actual classes and methods from the codebase.
- Import required packages instead of creating fake or temporary classes.
- Ignore logs or print statements and do not assert on them.
- Follow Dart testing best practices with clear, descriptive test names.