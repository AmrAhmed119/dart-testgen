// LLM-Generated test file created by testgen

import 'package:test/test.dart';
import 'package:test_gen_ai/src/coverage/util.dart';

void main() {
  group('extractVMServiceUri', () {
    test('extracts URI from Observatory listening message', () {
      const message =
          'Observatory listening on http://127.0.0.1:8181/auth-token/';
      final uri = extractVMServiceUri(message);
      expect(uri, isNotNull);
      expect(uri.toString(), 'http://127.0.0.1:8181/auth-token/');
    });

    test('extracts URI from Dart VM service listening message', () {
      const message =
          'The Dart VM service is listening on http://127.0.0.1:8181/auth-token/';
      final uri = extractVMServiceUri(message);
      expect(uri, isNotNull);
      expect(uri.toString(), 'http://127.0.0.1:8181/auth-token/');
    });

    test('returns null when no match is found', () {
      const message = 'Hello World';
      final uri = extractVMServiceUri(message);
      expect(uri, isNull);
    });

    test('extracts URI with IPv6 address', () {
      const message = 'The Dart VM service is listening on http://[::1]:8181/';
      final uri = extractVMServiceUri(message);
      expect(uri, isNotNull);
      expect(uri.toString(), 'http://[::1]:8181/');
    });

    test('extracts URI with // protocol', () {
      const message = 'Observatory listening on //127.0.0.1:8181/';
      final uri = extractVMServiceUri(message);
      expect(uri, isNotNull);
      expect(uri.toString(), '//127.0.0.1:8181/');
    });
  });
}
