import 'dart:convert';
import 'package:flutter/services.dart';

abstract final class Strings {
  static Map<String, dynamic> _values = {};
  static Future<void> load() async {
    _values = jsonDecode(await rootBundle.loadString('lib/l10n/app_en.arb')) as Map<String, dynamic>;
  }
  static String text(String key) => _values[key] as String? ?? key;
}
