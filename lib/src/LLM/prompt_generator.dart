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
- Return **only** the Dart test code — no comments, explanations, or extra output.
''';
  }

  static String analysisError(String error) {
    return 'to be added';
  }

  static String testFailError(String error) {
    return 'to be added';
  }
}
