import 'dart:convert';
import 'dart:io';
import 'package:tasks_flutter/core/url_policy.dart';

void main(List<String> args) {
  final release = args.contains('--release');
  final paths = args.where((value) => value != '--release').toList();
  final file = paths.isEmpty ? 'config/dev.json' : paths.single;
  final config = jsonDecode(File(file).readAsStringSync()) as Map;
  final uri = UrlPolicy.validate(config['API_BASE_URL'] as String,debug:!release);
  stdout.writeln('URL allowed: ${uri.host}');
}
