TestGen is an LLM-based test generation tool that creates comprehensive Dart unit tests for uncovered code using Google's Gemini AI models.

[![CI](https://github.com/AmrAhmed119/dart-testgen/actions/workflows/testgen.yaml/badge.svg)](https://github.com/AmrAhmed119/dart-testgen/actions/workflows/testgen.yaml)

## Features

- **Coverage-Driven Test Generation**: Automatically identifies untested code lines and generates tests to improve coverage.
- **Dependency-Aware Context**: Builds a dependency graph across code declarations by analyzing code dependencies to create dependency-aware context for prompting when testing any declaration.
- **LLM Integration**: Uses Google's Gemini models (Pro, Flash, Flash-Lite) for automated test generation with context-aware prompting.
- **Iterative Validation**: Validates generated tests through static analysis, execution, formatting, and optional coverage improvement checks with backoff propagation for API errors and rate limits.
- **Smart Filtering**: Skips trivial code (getters/setters, simple constructors) that doesn't require testing.

## Getting Started

### Install testgen

```dart
dart pub global activate testgen
```

### Gemini API key

Running the package requires a Gemini API key.
- Configure your key using either method:
  - Set as environment variable:
    ```bash
    export GEMINI_API_KEY=your_api_key
    ```
  - Pass as command-line argument: `--api-key your_api_key`
- Obtain an API key at https://ai.google.dev/gemini-api/docs/api-key.

## Usage

Generate tests for your entire package.

By default, this script assumes it's being run from the root directory of a package, and outputs test files to the `test/testgen/` folder with the naming convention: `{declaration_name}_{declaration_id}_test.dart`

```bash
dart pub global run testgen:testgen
```

Advanced usage with custom configuration
```bash
dart pub global run testgen:testgen --package '/home/user/code' --model gemini-2.5-flash --api-key your_key --max-depth 5 --max-attempts 10 --effective-tests-only
```

### Command Line Options

| Option | Short | Default | Description |
|--------|-------|---------|-------------|
| `--package` | | `.` (current directory) | Root directory of the package to test |
| `--model` | | `gemini-2.5-pro` | Gemini model to use (`gemini-2.5-pro`, `gemini-2.5-flash`, `gemini-2.5-flash-lite`) |
| `--api-key` | | `$GEMINI_API_KEY` | Gemini API key for authentication |
| `--effective-tests-only` | | `false` | Only generate tests that actually improve coverage |
| `--scope-output` | | `[]` | Restrict coverage to specific package paths |
| `--max-depth` | | `2` | Maximum dependency depth for context generation |
| `--max-attempts` | | `5` | Maximum number of attempts for test generation per declaration |
| `--help` | `-h` | | Show usage information |

## ⏰ Fair Warning

 TestGen takes time - sometimes a lot of it. Depending on your codebase size, this might be a perfect time to:

- Grab a coffee ☕
- Take a power nap 😴
- Learn a new language 🗣️ (we recommend Dart!)
- Question your life choices that led to having so much untested code 🤔

The good news? You'll come back to beautifully generated tests.
