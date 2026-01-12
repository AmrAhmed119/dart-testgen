/// A utility for generating different LLM prompt templates for code
/// generation and analysis.
///
/// Provides static methods to create prompts for test case generation, Dart
/// error analysis, and test execution issues.
///
/// Returns formatted strings for LLM use.
///
/// Extend this class to add new prompt types as needed for your workflow.
class PromptGenerator {
  const PromptGenerator();

  String testCode(String toBeTestedCode, String contextCode) {
    final buffer = StringBuffer();

    buffer.writeln('''
Generate a Dart test cases for the following code:

```dart
$toBeTestedCode
```
''');

    if (contextCode.trim().isNotEmpty) {
      buffer.writeln('''
With the following context:
```dart
$contextCode
```
''');
    }

    buffer.writeln('''
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
''');

    return buffer.toString();
  }

  String analysisError(String error) {
    return '''
The generated Dart code contains the following analyzer error(s):

$error

Fix these issues and return only the corrected, complete test code that will pass dart analyze.
''';
  }

  String testFailError(String error) {
    return '''
The generated test failed with the following error(s):

$error

Fix the test code and return only the corrected, complete test code that will pass all tests.
''';
  }

  String formatError(String error) {
    return '''
The generated Dart code has formatting issues:

$error

Fix these issues and return only the correctly formatted, complete test code.
''';
  }

  String fixError(String error) {
    return '''
An error occurred during test generation:

$error

Fix these issues and return only the corrected, complete test code.
''';
  }
}
