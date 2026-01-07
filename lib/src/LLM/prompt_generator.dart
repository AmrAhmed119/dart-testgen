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
Generate a Dart unit test for the following code:

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
Requirements:
- Test ONLY the lines marked with `// UNTESTED` - ignore already tested code.
- The provided code is partial, showing only relevant members.
- Use appropriate mocking for external dependencies (use dart:mockito package).
- If the code is trivial or untestable, set "needTesting": false and leave "code" empty (don't generate any code).
- Skip generating tests for private members (those starting with `_`).
- Primarily use the `dart:test` package for writing tests, avoiding using `dart:mockito` package only it's needed.
- For mocking, use the 'dart:mockito' package and try to extend mock classes from `Mock` class provided by the package, don't rely on build-run code generation.
- Use the actual classes and methods from the codebase - import the necessary packages instead of creating mock or temporary classes.
- Ignore any logs or print statements in the code and prevent asserting on them in tests.
- Import any other required Dart packages (e.g., `async`, `test`, etc.) as needed.
- Follow Dart testing best practices with descriptive test names.

Return the complete test file with proper imports and test structure.
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
