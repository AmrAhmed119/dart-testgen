<!-- 
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages). 

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages). 
-->

TODO: Put a short description of the package here that helps potential users
know whether this package might be useful for them.

## Features

- **Automated Test Generation**: Leverages Google's Gemini AI to generate comprehensive unit tests for Dart code
- **Coverage-Driven Analysis**: Integrates with `package:coverage` to identify untested code paths
- **Dependency-Aware Context**: Builds dependency graphs to provide relevant context for test generation
- **Enhanced Workflow Logging**: Structured logging with component prefixes (`[testgen]`, `[LLM]`, `[Coverage]`, `[Validator]`) for better debugging and progress tracking
- **Iterative Test Refinement**: Uses static analysis and test execution feedback to improve generated tests
- **Configurable AI Models**: Supports multiple Gemini model variants (pro, flash, flash-lite)
- **Effective Test Validation**: Optional coverage validation ensures generated tests actually improve code coverage

## Getting started

### Prerequisites
- Dart SDK 3.7.3 or later
- Google Gemini API key

### Installation
1. Clone the repository
2. Install dependencies: `dart pub get`
3. Set your Gemini API key: `export GEMINI_API_KEY="your_api_key_here"`

### Basic Usage
```bash
# Generate tests for the current package
dart run bin/testgen.dart

# Use a specific model and enable coverage validation
dart run bin/testgen.dart --model=gemini-2.5-flash --effective-tests-only

# Enable verbose logging and branch coverage
dart run bin/testgen.dart --branch-coverage --function-coverage
```

### Example Output
The enhanced logging provides clear visibility into the process:
```
[testgen] Generating tests for UserService, remaining: 3
[Coverage] Running tests and collecting coverage...
[LLM] Generating test code for UserService...
[Validator] Validating generated test code...
[testgen] Test generation ended with created and used 1247 tokens.
```

## Usage

### Command Line Options

```bash
dart run bin/testgen.dart [options]
```

**Options:**
- `--package`: Root directory of the package to test (default: current directory)
- `--model`: Gemini model to use (default: gemini-2.5-pro)
- `--api-key`: Gemini API key (or set GEMINI_API_KEY environment variable)
- `--effective-tests-only`: Only generate tests that improve coverage
- `--branch-coverage`: Collect branch coverage information
- `--function-coverage`: Collect function coverage information
- `--scope-output`: Restrict coverage to specific package paths

### Logging Features

The enhanced logging system provides structured output with clear component identification:

- **`[testgen]`**: Main workflow progress and completion status
- **`[Coverage]`**: Test execution and coverage analysis
- **`[LLM]`**: AI model interactions and responses  
- **`[Validator]`**: Test validation and verification

### Example Workflow

```dart
// See example/logging_demo.dart for a complete demonstration
// Run: dart run example/logging_demo.dart
```

This will show you exactly how the logging system works during test generation.

## Additional information

TODO: Tell users more about the package: where to find more information, how to 
contribute to the package, how to file issues, what response they can expect 
from the package authors, and more.
