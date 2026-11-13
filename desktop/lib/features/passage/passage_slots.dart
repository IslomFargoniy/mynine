import '../../data/models/part_payload.dart';
import 'html_document.dart' show htmlToPlainText;

/// IELTS "matching headings" inside the passage (web `utils/passageSlots.ts`): the author writes `{14}` in the passage
/// where question 14's heading goes. Only numbers of `matching` sections of the same part count; other `{…}` text in
/// a passage is shown as it is.
final RegExp passageSlotPattern = RegExp(r'\{\d{1,3}\}');

/// "Section A" / "Paragraph B" / "C" → the paragraph letter.
String? paragraphLetter(String? questionHtml) {
  final m = RegExp(r'^(?:section|paragraph)?\s*([A-Za-z])\.?$', caseSensitive: false)
      .firstMatch(htmlToPlainText(questionHtml));
  return m?.group(1)!.toUpperCase();
}

/// Without `{n}` markers: a matching section whose questions are "Section A" … "Section F" gets a box above each
/// passage paragraph that opens with that letter (bold "A", or a plain "A " when every letter is found in order).
/// Web `insertAutoMarkers`.
String insertAutoMarkers(String html, PartPayload part) {
  if (html.isEmpty || passageSlotPattern.hasMatch(html)) return html;
  var out = html;
  for (final section in part.sections) {
    if (section.questionType != QuestionType.matching) continue;
    final wanted = [
      for (final q in section.questions)
        if (paragraphLetter(q.html) case final l?) (letter: l, number: q.number),
    ];
    if (wanted.isEmpty) continue;

    int find(String letter, bool bold, int from) {
      final re = bold
          ? RegExp('<p(?:\\s[^>]*)?>(?:\\s|&nbsp;)*<(strong|b)>(?:\\s|&nbsp;)*$letter[.:)]?(?:\\s|&nbsp;)*</\\1>')
          : RegExp('<p(?:\\s[^>]*)?>(?:\\s|&nbsp;)*$letter[.:)]?(?:\\s|&nbsp;)+');
      final m = re.allMatches(out, from).firstOrNull;
      return m?.start ?? -1;
    }

    for (final bold in [true, false]) {
      final at = <int>[];
      var from = 0;
      for (final w in wanted) {
        final i = find(w.letter, bold, from);
        if (i < 0) break;
        at.add(i);
        from = i + 1;
      }
      // Bold letters may be partial; plain letters only count when all are found in order.
      if (at.isEmpty || (!bold && at.length < wanted.length)) continue;
      for (var k = at.length - 1; k >= 0; k--) {
        out = '${out.substring(0, at[k])}<p>{${wanted[k].number}}</p>${out.substring(at[k])}';
      }
      break;
    }
  }
  return out;
}

/// The passage HTML with the heading boxes' markers (written by the author, or found from "Section A"…).
String passageHtml(PartPayload part) => insertAutoMarkers(part.html, part);

/// Question number → question, for the markers present in [part]'s passage.
Map<int, QuestionPayload> passageSlots(PartPayload part) {
  final html = passageHtml(part);
  if (!passageSlotPattern.hasMatch(html)) return const {};
  final present = RegExp(r'\{(\d{1,3})\}').allMatches(html).map((m) => int.parse(m[1]!)).toSet();
  final out = <int, QuestionPayload>{};
  for (final s in part.sections) {
    if (s.questionType != QuestionType.matching) continue;
    for (final q in s.questions) {
      if (present.contains(q.number)) out[q.number] = q;
    }
  }
  return out;
}

bool _startsWithValue(String text, String value) {
  final t = text.toLowerCase();
  final v = value.toLowerCase();
  return t.startsWith('$v ') || t.startsWith('$v.');
}

Iterable<String> _listItems(String html) =>
    RegExp(r'<li[^>]*>([\s\S]*?)</li>', caseSensitive: false).allMatches(html).map((m) => htmlToPlainText(m[1]));

/// Headings given only as a range (i–vii) with their texts in the section's instructions: value → full text.
Map<String, String> headingTexts(String sectionHtml, List<String> values) {
  final items = _listItems(sectionHtml).toList();
  final out = <String, String>{};
  for (final v in values) {
    final hit = items.where((t) => _startsWithValue(t, v)).firstOrNull;
    if (hit != null) out[v] = hit;
  }
  return out;
}

/// In drag mode the list of headings becomes the draggable list: the static copy in the instructions goes.
String stripHeadingList(String sectionHtml, List<String> values) {
  final texts = headingTexts(sectionHtml, values);
  if (texts.length < (values.length - 1).clamp(2, 1 << 30)) return sectionHtml;
  return sectionHtml
      .replaceAllMapped(RegExp(r'<(ul|ol)[^>]*>([\s\S]*?)</\1>', caseSensitive: false), (m) {
        final lis = _listItems(m[2]!).toList();
        final isHeadings = lis.isNotEmpty && lis.every((t) => values.any((v) => _startsWithValue(t, v)));
        return isHeadings ? '' : m[0]!;
      })
      .replaceAll(
          RegExp(r'<(p|h[1-6])[^>]*>(?:\s|&nbsp;|</?(?:strong|b|em)>)*list of headings(?:\s|&nbsp;|</?(?:strong|b|em)>)*</\1>',
              caseSensitive: false),
          '');
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
