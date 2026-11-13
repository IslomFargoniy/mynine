import '../../data/models/part_payload.dart';

/// IELTS "matching headings" inside the passage (web `utils/passageSlots.ts`): the author writes `{14}` in the passage
/// where question 14's heading goes. Only numbers of `matching` sections of the same part count; other `{…}` text in
/// a passage is shown as it is.
final RegExp passageSlotPattern = RegExp(r'\{\d{1,3}\}');

/// Question number → question, for the markers present in [part]'s passage.
Map<int, QuestionPayload> passageSlots(PartPayload part) {
  if (!passageSlotPattern.hasMatch(part.html)) return const {};
  final present = RegExp(r'\{(\d{1,3})\}').allMatches(part.html).map((m) => int.parse(m[1]!)).toSet();
  final out = <int, QuestionPayload>{};
  for (final s in part.sections) {
    if (s.questionType != QuestionType.matching) continue;
    for (final q in s.questions) {
      if (present.contains(q.number)) out[q.number] = q;
    }
  }
  return out;
}

/// Ids of the questions answered in the passage (no select for them in the questions pane).
Set<int> passageSlotQuestionIds(PartPayload part) => {for (final q in passageSlots(part).values) q.id};

/// The number of a `{14}` marker.
int? passageSlotNumber(String marker) => int.tryParse(marker.replaceAll(RegExp(r'[{}]'), ''));

/// A marker that opens a paragraph is moved to its own line above it (as in the real test); this also keeps the
/// paragraph itself selectable for highlights.
String hoistPassageMarkers(String html) => html
    .replaceAllMapped(
      RegExp(r'<p(\s[^>]*)?>(?:\s|&nbsp;)*(\{\d{1,3}\})(?:\s|&nbsp;)*', caseSensitive: false),
      (m) => '<p>${m[2]}</p><p${m[1] ?? ''}>',
    )
    .replaceAllMapped(
      RegExp(r'(<p>\{\d{1,3}\}</p>)<p(?:\s[^>]*)?>(?:\s|&nbsp;|<br\s*/?>)*</p>', caseSensitive: false),
      (m) => m[1]!,
    );
