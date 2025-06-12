import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

String getPubspecPath(String root) => path.join(root, 'pubspec.yaml');

List<String> getAllWorkspaceNames(String packageRoot) =>
    _getAllWorkspaceNames(packageRoot, <String>[]);

List<String> _getAllWorkspaceNames(String packageRoot, List<String> results) {
  final pubspec = _loadPubspec(packageRoot);
  results.add(pubspec['name'] as String);
  for (final workspace in pubspec['workspace'] as YamlList? ?? []) {
    _getAllWorkspaceNames(path.join(packageRoot, workspace as String), results);
  }
  return results;
}

YamlMap _loadPubspec(String packageRoot) {
  final pubspecPath = getPubspecPath(packageRoot);
  final yaml = File(pubspecPath).readAsStringSync();
  return loadYaml(yaml, sourceUrl: Uri.file(pubspecPath)) as YamlMap;
}

Uri? extractVMServiceUri(String str) {
  final listeningMessageRegExp = RegExp(
    r'(?:Observatory|The Dart VM service is) listening on ((http|//)[a-zA-Z0-9:/=_\-\.\[\]]+)',
  );
  final match = listeningMessageRegExp.firstMatch(str);
  if (match != null) {
    return Uri.parse(match[1]!);
  }
  return null;
}

extension StandardOutExtension on Stream<List<int>> {
  Stream<String> lines() =>
      transform(const SystemEncoding().decoder).transform(const LineSplitter());
}
