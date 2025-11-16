import 'package:test/test.dart';
import 'package:testgen/src/LLM/context_generator.dart';
import 'package:testgen/src/analyzer/declaration.dart';

import '../utils.dart';

void main() {
  final List<Declaration> decls = List.generate(10, (i) => sampleDecl(i));

  void verifyContext({
    required int from,
    required int depth,
    required List<int> expectedIds,
  }) {
    final contextMap = buildDependencyContext(decls[from], maxDepth: depth);

    expect(contextMap.length, equals(1));
    expect(contextMap[null], containsAll(expectedIds.map((i) => decls[i])));
  }

  group('Test Context Generation for linear chain graph', () {
    // 0 -> 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 -> 8 -> 9
    setUpAll(() {
      for (int i = 0; i < decls.length - 1; i++) {
        decls[i].addDependency(decls[i + 1]);
      }
    });

    tearDownAll(() {
      for (final decl in decls) {
        decl.dependsOn.clear();
      }
    });

    test('Test at depth = 1 from node 0', () {
      verifyContext(from: 0, depth: 1, expectedIds: [1]);
    });

    test('Test at depth = 2 from node 0', () {
      verifyContext(from: 0, depth: 2, expectedIds: [1, 2]);
    });

    test('Test at depth = 5 from node 4', () {
      verifyContext(from: 4, depth: 5, expectedIds: [5, 6, 7, 8, 9]);
    });

    test('Test at depth = 5 from node 7', () {
      verifyContext(from: 7, depth: 5, expectedIds: [8, 9]);
    });

    test('Test at depth = 0 from node 0', () {
      final contextMap = buildDependencyContext(decls[0], maxDepth: 0);

      expect(contextMap, isNotNull);
      expect(contextMap, isEmpty);
    });
  });

  group('Test Context Generation from a node having multiple branches', () {
    //     1 - 2 - 3
    //   /
    // 0 - 4 - 5 - 6
    //   \
    //     7 - 8 - 9
    setUpAll(() {
      for (final start in [1, 4, 7]) {
        decls[start].addDependency(decls[start + 1]);
        decls[start + 1].addDependency(decls[start + 2]);
      }
      decls[0].addDependency(decls[1]);
      decls[0].addDependency(decls[4]);
      decls[0].addDependency(decls[7]);
    });

    tearDownAll(() {
      for (final decl in decls) {
        decl.dependsOn.clear();
      }
    });

    test('Test at depth = 1 from node 0', () {
      verifyContext(from: 0, depth: 1, expectedIds: [1, 4, 7]);
    });

    test('Test at depth = 2 from node 0', () {
      verifyContext(from: 0, depth: 2, expectedIds: [1, 2, 4, 5, 7, 8]);
    });

    test('Test at depth = 3 from node 0', () {
      verifyContext(
        from: 0,
        depth: 3,
        expectedIds: [1, 2, 3, 4, 5, 6, 7, 8, 9],
      );
    });
  });

  group('Test Context Generation for circular dependencies', () {
    //     1
    //   /   \
    // 0       2
    //   \   /
    //     3
    setUpAll(() {
      decls[0].addDependency(decls[1]);
      decls[1].addDependency(decls[2]);
      decls[2].addDependency(decls[3]);
      decls[3].addDependency(decls[0]);
    });

    tearDownAll(() {
      for (final decl in decls) {
        decl.dependsOn.clear();
      }
    });

    test('Test at depth = 1 from node 0', () {
      verifyContext(from: 0, depth: 1, expectedIds: [1]);
    });

    test('Test at depth = 3 from node 0', () {
      verifyContext(from: 0, depth: 3, expectedIds: [1, 2, 3]);
    });

    test('Test at depth = 10 from node 0', () {
      verifyContext(from: 0, depth: 10, expectedIds: [1, 2, 3]);
    });

    test('Test at depth = 1 from node 2', () {
      verifyContext(from: 2, depth: 1, expectedIds: [3]);
    });

    test('Test at depth = 3 from node 2', () {
      verifyContext(from: 2, depth: 3, expectedIds: [3, 0, 1]);
    });

    test('Test at depth = 10 from node 2', () {
      verifyContext(from: 2, depth: 10, expectedIds: [3, 0, 1]);
    });
  });

  group('Test Context Generation for disconnected subgraphs', () {
    // 0 -> 1 -> 2
    // 3 -> 4 (disconnected from above)
    setUpAll(() {
      decls[0].addDependency(decls[1]);
      decls[1].addDependency(decls[2]);
      decls[3].addDependency(decls[4]);
    });

    tearDownAll(() {
      for (final decl in decls) {
        decl.dependsOn.clear();
      }
    });

    test('Test at depth = 2 from node 0', () {
      verifyContext(from: 0, depth: 2, expectedIds: [1, 2]);
    });

    test('Test at depth = 5 from node 3', () {
      verifyContext(from: 3, depth: 5, expectedIds: [4]);
    });
  });

  group('Test Context Generation for complex cycle with branches', () {
    //     1 - 2          8
    //   /       \      /
    // 0           3 - 7 - 0 (cycle)
    //   \       /      \
    //     4 - 5 - 6      9
    setUpAll(() {
      decls[0].addDependency(decls[1]);
      decls[0].addDependency(decls[4]);
      decls[1].addDependency(decls[2]);
      decls[2].addDependency(decls[3]);
      decls[3].addDependency(decls[7]);
      decls[4].addDependency(decls[5]);
      decls[5].addDependency(decls[3]);
      decls[5].addDependency(decls[6]);
      decls[7].addDependency(decls[8]);
      decls[7].addDependency(decls[9]);
      decls[7].addDependency(decls[0]);
    });

    tearDownAll(() {
      for (final decl in decls) {
        decl.dependsOn.clear();
      }
    });

    test('Test at depth = 1 from node 0', () {
      verifyContext(from: 0, depth: 1, expectedIds: [1, 4]);
    });

    test('Test at depth = 2 from node 0', () {
      verifyContext(from: 0, depth: 2, expectedIds: [1, 2, 4, 5]);
    });

    test('Test at depth = 3 from node 0', () {
      verifyContext(from: 0, depth: 3, expectedIds: [1, 2, 3, 4, 5, 6]);
    });

    test('Test at depth = 4 from node 0', () {
      verifyContext(from: 0, depth: 4, expectedIds: [1, 2, 3, 4, 5, 6, 7]);
    });

    test('Test at depth = 5 from node 0', () {
      verifyContext(
        from: 0,
        depth: 5,
        expectedIds: [1, 2, 3, 4, 5, 6, 7, 8, 9],
      );
    });

    test('Test at depth = 2 from node 3', () {
      verifyContext(from: 3, depth: 2, expectedIds: [7, 8, 9, 0]);
    });

    test('Test at depth = 5 from node 3', () {
      verifyContext(from: 3, depth: 5, expectedIds: [7, 8, 9, 0, 1, 4, 2, 5]);
    });
  });

  group('Test Context Generation for node with no dependencies', () {
    setUpAll(() {
      for (final decl in decls) {
        decl.dependsOn.clear();
      }
    });

    test('Test at depth = 2 from all nodes', () {
      for (int i = 0; i < decls.length; i++) {
        final contextMap = buildDependencyContext(decls[i], maxDepth: 2);

        expect(contextMap, isNotNull);
        expect(contextMap, isEmpty);
      }
    });
  });

  group('Early visitation of shared node will not block deeper context', () {
    //                       5
    //                      /
    //         1 - 2 - 3 - 4
    //       /            /
    //     0  - - - 6 - -
    setUpAll(() {
      decls[0].addDependency(decls[1]);
      decls[0].addDependency(decls[6]);
      decls[1].addDependency(decls[2]);
      decls[2].addDependency(decls[3]);
      decls[3].addDependency(decls[4]);
      decls[4].addDependency(decls[5]);
      decls[6].addDependency(decls[4]);
    });

    tearDownAll(() {
      for (final decl in decls) {
        decl.dependsOn.clear();
      }
    });

    test('Test at depth = 2 from node 0', () {
      verifyContext(from: 0, depth: 2, expectedIds: [1, 2, 6, 4]);
    });

    test('Test at depth = 4 from node 0', () {
      verifyContext(from: 0, depth: 4, expectedIds: [1, 2, 3, 4, 5, 6]);
    });
  });

  group('Test Context Generation for nested cycles', () {
    //     1 - 2
    //   /   \ |
    // 0       3
    //   \     |
    //     4 - 5
    setUpAll(() {
      decls[0].addDependency(decls[1]);
      decls[0].addDependency(decls[4]);
      decls[1].addDependency(decls[2]);
      decls[2].addDependency(decls[3]);
      decls[3].addDependency(decls[1]); // inner cycle
      decls[4].addDependency(decls[5]);
      decls[5].addDependency(decls[3]); // outer cycle
    });

    tearDownAll(() {
      for (final decl in decls) {
        decl.dependsOn.clear();
      }
    });

    test('Test at depth = 2 from node 0', () {
      verifyContext(from: 0, depth: 2, expectedIds: [1, 2, 4, 5]);
    });

    test('Test at depth = 3 from node 0', () {
      verifyContext(from: 0, depth: 3, expectedIds: [1, 2, 3, 4, 5]);
    });

    test('Test at depth = 5 from node 4', () {
      verifyContext(from: 4, depth: 5, expectedIds: [1, 2, 3, 5]);
    });
  });

  group('Test Context Map structured correctly', () {
    //   (p:8)  (p:9)
    //     1 - - 2
    //   /
    // 0 - - 4 - - 5 - - 6
    //     (p:7)  (p:6)
    late Declaration p6, p7, p8, p9;
    late Declaration n0, n1, n2, n4, n5;

    setUpAll(() {
      p6 = sampleDecl(6);
      p7 = sampleDecl(7);
      p8 = sampleDecl(8);
      p9 = sampleDecl(9);

      n0 = sampleDecl(0);
      n1 = sampleDecl(1, parent: p8);
      n2 = sampleDecl(2, parent: p9);
      n4 = sampleDecl(4, parent: p7);
      n5 = sampleDecl(5, parent: p6);

      n0.addDependency(n1);
      n0.addDependency(n4);
      n1.addDependency(n2);
      n4.addDependency(n5);
      n5.addDependency(p6);
    });

    tearDownAll(() {
      for (final decl in decls) {
        decl.dependsOn.clear();
      }
    });

    test('Grouping by parent preserves parent relationship and keys', () {
      final contextMap = buildDependencyContext(n0, maxDepth: 3);

      // All non-null keys should be one of the parent declarations we created
      final allowedParents = {p8, p9, p7, p6};
      for (final key in contextMap.keys) {
        if (key == null) continue;
        expect(allowedParents, contains(key));
      }

      // Every child listed under a non-null key must actually have that key
      // as its `.parent`.
      for (final entry in contextMap.entries) {
        final parent = entry.key;
        for (final child in entry.value) {
          if (parent != null) {
            expect(child.parent, equals(parent));
          }
        }
      }
    });

    test('No duplicates and unique membership across groups', () {
      final contextMap = buildDependencyContext(n0, maxDepth: 3);

      // No duplicates within each list
      for (final children in contextMap.values) {
        final asSet = children.toSet();
        expect(asSet.length, equals(children.length));
      }

      // No element appears under multiple keys
      final seen = <Declaration, int>{};
      for (final entry in contextMap.entries) {
        for (final child in entry.value) {
          seen[child] = (seen[child] ?? 0) + 1;
        }
      }
      for (final count in seen.values) {
        expect(count, equals(1));
      }

      // Ensure that no parent (key) is present in any list (value)
      final keys = contextMap.keys.toSet();
      for (final entry in contextMap.entries) {
        for (final child in entry.value) {
          expect(keys, isNot(contains(child)));
        }
      }
    });
  });
}
