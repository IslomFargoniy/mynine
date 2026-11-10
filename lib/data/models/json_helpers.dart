/// Small JSON conversion helpers shared by the API models.
///
/// The server is PHP/Laravel; some values may arrive as either a number or a
/// string (e.g. `from_option` is `1` in API.md but letters like `"A"` in the
/// web app). These helpers normalise them.
library;

String? stringOrNull(Object? value) {
  if (value == null) return null;
  final s = value.toString();
  return s.isEmpty ? null : s;
}

String stringOrEmpty(Object? value) => value?.toString() ?? '';

int intFrom(Object? value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

/// Reads how many question numbers a question covers ("Choose TWO letters").
/// The server sends `number_count` (API.md implementation notes); the web
/// model's `is_correct_count` / `answer_count` are accepted as fallbacks.
Object? readAnswerCount(Map<dynamic, dynamic> json, String key) =>
    json['number_count'] ?? json['answer_count'] ?? json['is_correct_count'];

DateTime? dateOrNull(Object? value) {
  if (value == null) return null;
  if (value is String && value.isEmpty) return null;
  return DateTime.tryParse(value.toString());
}

String? dateToJson(DateTime? value) => value?.toUtc().toIso8601String();

DateTime dateRequired(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now().toUtc();

String dateRequiredToJson(DateTime value) => value.toUtc().toIso8601String();
