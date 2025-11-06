import 'package:test/test.dart';
import 'package:testgen/src/analyzer/declaration.dart';
import 'package:testgen/src/analyzer/extractor.dart';

void main() {
  const fileA = 'package:test_package/lib/a.dart';
  const fileB = 'package:test_package/lib/b.dart';
  const sourceCode = <String>[
    'line 1',
    'line 2',
    'line 3',
    'line 4',
    'line 5',
    'line 6',
  ];

  Declaration sampleDecl(
    int id, {
    required String name,
    required String path,
    required int startLine,
    int? endLine,
  }) {
    return Declaration(
      id,
      name: name,
      sourceCode: sourceCode,
      startLine: startLine,
      endLine: endLine ?? startLine + sourceCode.length - 1,
      path: path,
    );
  }

  group('Test untested declarations extraction', () {
    test('Empty file', () {
      final result = extractUntestedDeclarations({}, []);

      expect(result, isEmpty);
    });

    test('Fully covered code', () {
      final declarations = <String, List<Declaration>>{
        fileA: [sampleDecl(1, name: 'a1', path: fileA, startLine: 1)],
      };
      final result = extractUntestedDeclarations(declarations, []);

      expect(result, isEmpty);
    });

    test('path mismatch between coverage & declarations yields no results', () {
      final declarations = <String, List<Declaration>>{
        fileA: [sampleDecl(1, name: 'a1', path: fileA, startLine: 1)],
      };
      final coverage = <(String, List<int>)>[
        (fileB, [3, 4]),
      ];
      final result = extractUntestedDeclarations(declarations, coverage);

      expect(result, isEmpty);
    });

    test('extracts untested declarations from mock coverage', () {
      final declarations = <String, List<Declaration>>{
        fileA: [
          sampleDecl(1, name: 'a1', path: fileA, startLine: 1),
          sampleDecl(2, name: 'a2', path: fileA, startLine: 15),
          sampleDecl(3, name: 'a3', path: fileA, startLine: 100),
        ],
        fileB: [
          sampleDecl(4, name: 'b1', path: fileB, startLine: 40),
          sampleDecl(5, name: 'b2', path: fileB, startLine: 50),
          sampleDecl(6, name: 'b3', path: fileB, startLine: 80),
        ],
      };
      final coverage = <(String, List<int>)>[
        (fileA, [3, 4, 5, 6, 100, 105]),
        (fileB, [41, 42, 43, 54, 55]),
      ];
      final result = extractUntestedDeclarations(declarations, coverage);

      // Expect 4 declarations (2 per file) that need testing (a1, a3, b1, b2)
      expect(result, hasLength(4));

      final idToLines = <int, List<int>>{};
      for (final (decl, lines) in result) {
        idToLines[decl.id] = lines;
      }

      // fileA
      expect(idToLines[1], equals([2, 3, 4, 5])); // a1
      expect(idToLines.containsKey(2), isFalse); // no entry for a2
      expect(idToLines[3], equals([0, 5])); // a3

      // fileB
      expect(idToLines[4], equals([1, 2, 3])); // b1
      expect(idToLines[5], equals([4, 5])); // b2
      expect(idToLines.containsKey(6), isFalse); // no entry for b3
    });

    test('boundary inclusion (start and end lines included)', () {
      final declarations = <String, List<Declaration>>{
        fileA: [sampleDecl(1, name: 'a1', path: fileA, startLine: 1)],
      };
      final coverage = <(String, List<int>)>[
        (fileA, [1, 6]),
      ];
      final result = extractUntestedDeclarations(declarations, coverage);

      expect(result, hasLength(1));

      final (decl, lines) = result.first;
      expect(decl.id, equals(1));
      expect(lines, equals([0, 5]));
    });

    test(
      'handles nested declarations: inner + outer share uncovered lines',
      () {
        final declarations = <String, List<Declaration>>{
          fileA: [
            sampleDecl(1, name: 'a1', path: fileA, startLine: 1, endLine: 6),
            sampleDecl(2, name: 'a2', path: fileA, startLine: 3, endLine: 5),
          ],
        };
        final coverage = <(String, List<int>)>[
          (fileA, [3, 4]),
        ];

        final result = extractUntestedDeclarations(declarations, coverage);

        expect(result, hasLength(2));

        final idToLines = <int, List<int>>{};
        for (final (decl, lines) in result) {
          idToLines[decl.id] = lines;
        }

        expect(idToLines[1], equals([2, 3]));
        expect(idToLines[2], equals([0, 1]));
      },
    );

    test('invalid declaration ranges are ignored', () {
      final declarations = {
        fileA: [
          sampleDecl(1, name: 'a1', path: fileA, startLine: 10, endLine: 5),
        ],
      };
      final coverage = <(String, List<int>)>[
        (fileA, [15, 20]),
      ];
      final result = extractUntestedDeclarations(declarations, coverage);

      expect(result, isEmpty);
    });
  });
}
