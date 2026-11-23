import 'dart:ui';
import 'package:intl/intl.dart';
import '../l10n/strings.dart';

String formatValue(String key,Object? value) {
  if (value == null || value == '') return Strings.text('nullValue');
  final locale = PlatformDispatcher.instance.locale.toLanguageTag();
  if (value is num) return NumberFormat.decimalPattern(locale).format(value);
  if (key.endsWith('At') || key == 'dueDate') {
    final date = DateTime.tryParse(value.toString());
    if (date != null) return DateFormat.yMMMd(locale).format(date.toLocal());
  }
  return value.toString();
}
