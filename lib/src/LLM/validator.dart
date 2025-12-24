import 'package:testgen/src/LLM/prompt_generator.dart';
import 'package:testgen/src/LLM/test_file.dart';

/// List of standard validators that are run on generated test files.
/// These validators must be passed before a test file is considered valid.
final defaultValidators = List<Validator>.unmodifiable([
  AnalysisValidator(),
  TestExecutionValidator(),
  FormatValidator(),
]);

class ValidationResult {
  ValidationResult({required this.isPassed, this.recoveryPrompt});

  bool isPassed;

  /// Optional prompt containing instructions to fix the issue if validation
  /// failed, This will be `null` if [isPassed] is `true`.
  String? recoveryPrompt;
}

/// Interface for all validation checks that can be run on test files.
abstract class Validator {
  /// Validates a specific check on the given test file
  ///
  /// Returns a [ValidationResult] indicating success/failure and recovery
  /// prompt built using [promptGen] if validation failed.
  Future<ValidationResult> validate(
    TestFile testFile,
    PromptGenerator promptGen,
  );
}

/// Validates that the generated test file has no Dart analysis errors.
class AnalysisValidator implements Validator {
  @override
  Future<ValidationResult> validate(
    TestFile testFile,
    PromptGenerator promptGen,
  ) async {
    print('[Validator] Running static analysis...');
    final errors = await testFile.runAnalyzer();
    final hasErrors = errors != null;

    return ValidationResult(
      isPassed: !hasErrors,
      recoveryPrompt: hasErrors ? promptGen.analysisError(errors) : null,
    );
  }
}

/// Validates that the generated tests executed successfully without failures.
class TestExecutionValidator implements Validator {
  @override
  Future<ValidationResult> validate(
    TestFile testFile,
    PromptGenerator promptGen,
  ) async {
    print('[Validator] Running test execution...');
    final errors = await testFile.runTest();
    final hasErrors = errors != null;

    return ValidationResult(
      isPassed: !hasErrors,
      recoveryPrompt: hasErrors ? promptGen.testFailError(errors) : null,
    );
  }
}

/// Validates that the generated test file follows Dart formatting conventions.
class FormatValidator implements Validator {
  @override
  Future<ValidationResult> validate(
    TestFile testFile,
    PromptGenerator promptGen,
  ) async {
    print('[Validator] Running code formatter...');
    final errors = await testFile.runFormat();
    final hasErrors = errors != null;

    return ValidationResult(
      isPassed: !hasErrors,
      recoveryPrompt: hasErrors ? promptGen.formatError(errors) : null,
    );
  }
}
