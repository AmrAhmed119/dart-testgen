// LLM-Generated test file created by testgen

import 'dart:async';
import 'dart:convert';
import 'package:test/test.dart';
import 'package:test_gen_ai/src/coverage/util.dart';

void main() {
  group('StandardOutExtension', () {
    group('lines', () {
      test('should correctly split a stream of bytes into lines', () async {
        final List<int> bytes = utf8.encode('Hello\nWorld\nDart');
        final Stream<List<int>> byteStream = Stream.fromIterable([bytes]);

        final Stream<String> lineStream = byteStream.lines();

        final List<String> lines = await lineStream.toList();

        expect(lines, ['Hello', 'World', 'Dart']);
      });

      test('should handle an empty stream', () async {
        final Stream<List<int>> byteStream = Stream.fromIterable([]);

        final Stream<String> lineStream = byteStream.lines();

        final List<String> lines = await lineStream.toList();

        expect(lines, isEmpty);
      });

      test(
        'should handle a stream with a single line without a trailing newline',
        () async {
          final List<int> bytes = utf8.encode('SingleLine');
          final Stream<List<int>> byteStream = Stream.fromIterable([bytes]);

          final Stream<String> lineStream = byteStream.lines();

          final List<String> lines = await lineStream.toList();

          expect(lines, ['SingleLine']);
        },
      );

      test(
        'should handle a stream with multiple chunks and newlines',
        () async {
          final List<int> bytes1 = utf8.encode('First line\nSecond');
          final List<int> bytes2 = utf8.encode(' line\nThird line');
          final Stream<List<int>> byteStream = Stream.fromIterable([
            bytes1,
            bytes2,
          ]);

          final Stream<String> lineStream = byteStream.lines();

          final List<String> lines = await lineStream.toList();

          expect(lines, ['First line', 'Second line', 'Third line']);
        },
      );

      test('should handle a stream ending with a newline', () async {
        final List<int> bytes = utf8.encode('Line1\nLine2\n');
        final Stream<List<int>> byteStream = Stream.fromIterable([bytes]);

        final Stream<String> lineStream = byteStream.lines();

        final List<String> lines = await lineStream.toList();

        expect(lines, ['Line1', 'Line2']);
      });

      test('should handle a stream with only newlines', () async {
        final List<int> bytes = utf8.encode('\n\n');
        final Stream<List<int>> byteStream = Stream.fromIterable([bytes]);

        final Stream<String> lineStream = byteStream.lines();

        final List<String> lines = await lineStream.toList();

        expect(lines, ['', '']);
      });
    });
  });
}
