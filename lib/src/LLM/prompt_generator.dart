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
Given the following Dart code to test:

```dart
$toBeTestedCode
```

With the following context:

```dart
$contextCode
```

Write a Dart unit test that covers **only** the lines marked with `// UNTESTED`.

- The provided code is **partial**, showing only relevant members (e.g., fields, methods).
- The context code includes required dependencies or references.
- Focus **only** on `// UNTESTED` lines — ignore already-tested ones.
- Assume default values or minimal mocks where needed.
- If the provided code is trivial, untestable, or does not require a test, set "needTesting": false and leave "code" empty.
- If any external packages are used in the test (e.g., mockito, http, async, etc.), make sure to import them in the test code.
''';
  }

  static String analysisError(String error) {
    return '''
The following Dart code you generated contains analyzer error(s):

$error

Please review and correct the code to resolve these issues and return the corrected code.
''';
  }

  static String testFailError(String error) {
    return '''
The generated test code failed during execution with the following error(s):

$error

Please fix the test code so that it passes all tests and return the corrected code.
''';
  }
}
