import 'package:testgen/src/LLM/prompt_generator.dart';
import 'package:testgen/src/LLM/test_file.dart';
import 'package:testgen/src/analyzer/declaration.dart';
import 'package:testgen/src/coverage/coverage_collection.dart';

/// List of standard validators that are run on generated test files.
/// These validators must be passed before a test file is considered valid.
final validators = List.unmodifiable([
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
final class AnalysisValidator implements Validator {
  @override
  Future<ValidationResult> validate(
    TestFile testFile,
    PromptGenerator promptGen,
  ) async {
    final errors = await testFile.runAnalyzer();
    final hasErrors = errors != null;

    return ValidationResult(
      isPassed: !hasErrors,
      recoveryPrompt: hasErrors ? promptGen.analysisError(errors) : null,
    );
  }
}

/// Validates that the generated tests executed successfully without failures.
final class TestExecutionValidator implements Validator {
  @override
  Future<ValidationResult> validate(
    TestFile testFile,
    PromptGenerator promptGen,
  ) async {
    final errors = await testFile.runTest();
    final hasErrors = errors != null;

    return ValidationResult(
      isPassed: !hasErrors,
      recoveryPrompt: hasErrors ? promptGen.testFailError(errors) : null,
    );
  }
}

/// Validates that the generated test file follows Dart formatting conventions.
final class FormatValidator implements Validator {
  @override
  Future<ValidationResult> validate(
    TestFile testFile,
    PromptGenerator promptGen,
  ) async {
    final errors = await testFile.runFormat();
    final hasErrors = errors != null;

    return ValidationResult(
      isPassed: !hasErrors,
      recoveryPrompt: hasErrors ? promptGen.formatError(errors) : null,
    );
  }
}

/// Validates that the generated tests improve code coverage for the target
/// declaration.
final class CoverageValidator implements Validator {
  final String packagePath;
  final Declaration declaration;
  final int untestedLines;
  final String scopeOutput;

  CoverageValidator(
    this.declaration,
    this.untestedLines,
    this.packagePath,
    this.scopeOutput,
  );

  @override
  Future<ValidationResult> validate(_, _) async {
    final isImproved = await validateTestCoverageImprovement(
      declaration: declaration,
      baselineUncoveredLines: untestedLines,
      packageDir: packagePath,
      scopeOutput: {scopeOutput},
    );
    return ValidationResult(isPassed: isImproved);
  }
}
