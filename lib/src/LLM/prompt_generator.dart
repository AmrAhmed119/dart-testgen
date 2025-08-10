/// A utility for generating different LLM prompt templates for code
/// generation and analysis.
///
/// Provides static methods to create prompts for test case generation, Dart
/// error analysis, and test execution issues.
///
/// Returns formatted strings for LLM use.
///
/// Extend this class to add new prompt types as needed for your workflow.
abstract class PromptGenerator {
  static String testCode(String toBeTestedCode, String contextCode) {
    return '''
Generate a Dart unit test for the following code:

```dart
$toBeTestedCode
```

With the following context:

```dart
$contextCode
```

Requirements:
- Test ONLY the lines marked with `// UNTESTED` - ignore already tested code.
- The provided code is partial, showing only relevant members.
- Use appropriate mocking for external dependencies.
- If the code is trivial or untestable, set "needTesting": false and leave "code" empty (don't generate any code).
- Skip generating tests for private members (those starting with `_`).
- Import all required packages (test (dart package), mockito (dart package), async, etc.)
- Follow Dart testing best practices with descriptive test names.

Return the complete test file with proper imports and test structure.
''';
  }

  static String analysisError(String error) {
    return '''
The generated Dart code contains the following analyzer error(s):

$error

Fix these issues and return only the corrected, complete test code that will pass dart analyze.
''';
  }

  static String testFailError(String error) {
    return '''
The generated test failed with the following error(s):

$error

Fix the test code and return only the corrected, complete test code that will pass all tests.
''';
  }

  static String fixError(String error) {
    return '''
An error occurred during test generation:

$error

Fix these issues and return only the corrected, complete test code.
''';
  }
}
