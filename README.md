TestGen AI is an LLM-based test generation tool that generates Dart test cases for uncovered code using Google Gemini to improve code coverage.

[![pub package](https://img.shields.io/pub/v/test_gen_ai.svg)](https://pub.dev/packages/test_gen_ai)
[![CI](https://github.com/AmrAhmed119/dart-testgen/actions/workflows/testgen.yaml/badge.svg)](https://github.com/AmrAhmed119/dart-testgen/actions/workflows/testgen.yaml)
[![Coverage](https://img.shields.io/badge/coverage-95.7%25-blue.svg)](.)


## Features

- **Coverage-Driven Test Generation**: Automatically identifies untested code lines and generates tests to improve coverage.
- **Dependency-Aware Context**: Builds a dependency graph across code declarations by analyzing code dependencies to create dependency-aware context for prompting when testing any declaration. See how dependencies are included in prompts in the [example/prompt_example.md](example/prompt_example.md).
- **LLM Integration**: Uses Google's Gemini models (Pro, Flash, Flash-Lite) for automated test generation with context-aware prompting.
- **Iterative Validation**: Validates generated tests through static analysis, execution, formatting, and optional coverage improvement checks with backoff propagation for API errors and rate limits.
- **Smart Filtering**: Skips trivial code (getters/setters, simple constructors) that doesn't require testing.

## Getting Started

### Install test_gen_ai

```dart
dart pub global activate test_gen_ai
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

By default, this script assumes it's being run from the root directory of a package, and outputs test files to the `test/testgen/` folder with the naming convention: `{declaration_name}_{declaration_id}_{num_uncovered_lines}_test.dart`

```bash
dart pub global run test_gen_ai:testgen
```

Advanced usage with custom configuration
```bash
dart pub global run test_gen_ai:testgen --package '/home/user/code' --model gemini-3-flash-preview --api-key your_key --max-depth 5 --max-attempts 10 --effective-tests-only -v
```

It’s recommended to run the package on a **specific set of files** rather than the entire codebase using `target-files` flag, This reduces execution time, and make results easier to analyze & review.
```bash
dart pub global run test_gen_ai:testgen --package '/home/user/code' --target-files 'lib/src/foo.dart,lib/src/temp.dart'
```


### Command Line Options

| Option | Short | Default | Description |
|--------|-------|---------|-------------|
| `--package` | | `.` (current directory) | Root directory of the package to test |
| `--target-files` | | `[]` | Limit test generation to specific dart files inside the package (paths relative to package root, e.g. `lib/foo.dart`) |
| `--model` | | `gemini-3-flash-preview` | Gemini model to use (`gemini-3-flash-preview`, `gemini-2.5-flash`, `gemini-2.5-flash-lite`) |
| `--api-key` | | `$GEMINI_API_KEY` | Gemini API key for authentication |
| `--effective-tests-only` | `-e` | `false` | Only generate tests that actually improve coverage |
| `--scope-output` | | `[]` | Restrict coverage to specific package paths |
| `--max-depth` | | `10` | Maximum dependency depth for context generation |
| `--max-attempts` | | `5` | Maximum number of attempts for test generation per declaration |
| `--verbose` | `-v` | `false` | Enable verbose logging (logs LLM prompts to a file) |
| `--help` | `-h` | | Show usage information |

## ⏰ Fair Warning

 TestGen AI takes time - sometimes a lot of it. Depending on your codebase size, this might be a perfect time to:

- Grab a coffee ☕
- Take a power nap 😴
- Learn a new language 🗣️ (we recommend Dart!)
- Question your life choices that led to having so much untested code 🤔

The good news? You'll come back to beautifully generated tests.
