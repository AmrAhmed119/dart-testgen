class CoverageOptions {
  const CoverageOptions({
    required this.package,
    required this.vmServicePort,
    required this.branchCoverage,
    required this.functionCoverage,
    required this.scopeOutput,
  });

  final String package;
  final String vmServicePort;
  final bool branchCoverage;
  final bool functionCoverage;
  final List<String> scopeOutput;

  static final defaultOptions = CoverageOptions(
    package: '.',
    vmServicePort: '0',
    branchCoverage: false,
    functionCoverage: false,
    scopeOutput: [],
  );
}
