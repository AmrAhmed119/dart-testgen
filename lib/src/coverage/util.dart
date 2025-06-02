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
