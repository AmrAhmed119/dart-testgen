// LLM-Generated test file created by testgen

import 'package:test/test.dart';
import 'package:test_gen_ai/src/coverage/coverage_collection.dart';

void main() {
  group('formatCoverage', () {
    test('should return unhit lines for files with coverage gaps', () async {
      // Explicitly type the list to avoid 'List<dynamic>' is not a subtype of 'List<Map<String, dynamic>>'
      final Map<String, dynamic> coverageResults = {
        'coverage': <Map<String, dynamic>>[
          {
            'source': 'package:test_gen_ai/file1.dart',
            'hits': [
              1,
              1,
              2,
              0,
              3,
              5,
            ], // Line 1: 1 hit, Line 2: 0 hits, Line 3: 5 hits
          },
        ],
      };
      final packageDir = '.';

      final result = await formatCoverage(coverageResults, packageDir);

      expect(result, isA<CoverageData>());
      expect(result, hasLength(1));
      expect(result[0].$1, contains('file1.dart'));
      expect(result[0].$2, contains(2));
      expect(result[0].$2, isNot(contains(1)));
      expect(result[0].$2, isNot(contains(3)));
    });

    test('should filter out files where all lines are hit', () async {
      final Map<String, dynamic> coverageResults = {
        'coverage': <Map<String, dynamic>>[
          {
            'source': 'package:test_gen_ai/file2.dart',
            'hits': [1, 10, 2, 5],
          },
        ],
      };
      final result = await formatCoverage(coverageResults, '.');
      expect(result, isEmpty);
    });

    test('should return empty list when coverage results are empty', () async {
      final Map<String, dynamic> coverageResults = {
        'coverage': <Map<String, dynamic>>[],
      };
      final result = await formatCoverage(coverageResults, '.');
      expect(result, isEmpty);
    });

    test('should handle multiple files with unhit lines', () async {
      final Map<String, dynamic> coverageResults = {
        'coverage': <Map<String, dynamic>>[
          {
            'source': 'f1.dart',
            'hits': [10, 0],
          },
          {
            'source': 'f2.dart',
            'hits': [20, 0],
          },
        ],
      };
      final result = await formatCoverage(coverageResults, '.');
      expect(result.length, 2);
      expect(
        result.any((e) => e.$1.contains('f1.dart') && e.$2.contains(10)),
        isTrue,
      );
      expect(
        result.any((e) => e.$1.contains('f2.dart') && e.$2.contains(20)),
        isTrue,
      );
    });
  });
}
