const titleMaxLength = 200;
const descriptionMaxLength = 10000;

/// The same limits as the OpenAPI contract, so most mistakes are caught before queueing.
String? validateTitle(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) {
    return 'Enter a title';
  }
  if (text.length > titleMaxLength) {
    return 'Use at most $titleMaxLength characters';
  }
  return null;
}

String? validateDescription(String? value) {
  if ((value ?? '').length > descriptionMaxLength) {
    return 'Use at most $descriptionMaxLength characters';
  }
  return null;
}

/// An empty text means "no due date". Otherwise a real calendar date as yyyy-MM-dd.
String? validateDueDate(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) {
    return null;
  }
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text);
  if (match == null) {
    return 'Write the date like 2026-12-31';
  }
  final year = int.parse(match[1]!);
  final month = int.parse(match[2]!);
  final day = int.parse(match[3]!);
  final date = DateTime.utc(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    return 'That date does not exist';
  }
  return null;
}
