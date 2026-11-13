import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LengthLimitingTextInputFormatter;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme.dart';
import '../../core/theme/web_tokens.dart';
import '../../data/models/part_payload.dart';
import '../../data/repositories/answer_queue.dart' show kMaxAnswerChars;
import '../exam/exam_controller.dart';
import '../passage/html_document.dart';
import '../passage/html_view.dart';
import '../passage/passage_pane.dart' show HighlightStore, SelectableHtml, questionDocId;
import '../passage/passage_slots.dart' show headingTexts, stripHeadingList;
import 'range.dart';

// Widgets in this file reproduce resources/js/components/practice/
// practice-section.tsx, practice-question.tsx, practice-option.tsx,
// matching-headings.tsx and the essay branch of practice-question.tsx.
// Sizes/colours come from WebTokens (lib/core/theme/web_tokens.dart).

/// Everything a question widget needs.
class QuestionContext {
  QuestionContext({
    required this.exam,
    required this.part,
    required this.palette,
    required this.keys,
    this.images,
    this.store,
    this.passageQuestionIds = const {},
    this.pickedHeading,
  });

  final ExamController exam;
  final PartPayload part;
  final ExamPalette palette;

  /// Question id → key, used by the number bar to scroll to a question.
  final Map<int, GlobalKey> keys;
  final ImageResolver? images;

  /// Highlights + notes (null: plain text, e.g. in tests or the review screen).
  final HighlightStore? store;

  /// Matching questions answered by dragging a heading into the passage (`{14}` boxes, [PassageDropBox]).
  final Set<int> passageQuestionIds;

  /// Tap-to-place: the heading picked in the list waits for a tap on a passage box.
  final ValueNotifier<String?>? pickedHeading;

  GlobalKey keyFor(int questionId) => keys.putIfAbsent(questionId, GlobalKey.new);

  bool get locked => exam.inputsLocked;

  SavedAnswer answer(int questionId) => exam.answerFor(questionId);

  void setText(int questionId, String text, {bool debounce = true}) => exam.setAnswer(
        partId: part.id,
        questionId: questionId,
        text: text,
        debounce: debounce,
      );

  void setOptions(int questionId, List<int> ids) =>
      exam.setAnswer(partId: part.id, questionId: questionId, optionIds: ids);

  /// Colour helper: component colour in the standard scheme, scheme text otherwise.
  Color c(Color standard) => palette.standard ? standard : palette.text;

  /// section.tsx prose `text-[16px]` + app.css `.prose { line-height: 1.4 }`.
  TextStyle get proseStyle =>
      inter(WebTokens.sectionFontSize, color: palette.text, height: WebTokens.proseLineHeight);

  /// question.tsx `text-sm leading-relaxed text-black`.
  TextStyle get questionStyle =>
      inter(WebTokens.questionFontSize, color: palette.text, height: WebTokens.questionLineHeight);

  /// [docId]: highlight document of this text ([questionDocId]); with a [store] the text gets the
  /// Highlight / Note toolbar like the passage.
  Widget html(String html, TextStyle style,
      {RegExp? blanks, BlankBuilder? blankBuilder, bool inline = false, int? docId}) {
    final doc = parseHtmlCached(html, blankPattern: blanks);
    final headerColor = palette.standard ? WebTokens.tableHeaderBg : null;
    final borderColor = palette.standard ? WebTokens.tableBorder : palette.text;
    final s = store;
    if (s != null && docId != null) {
      return SelectableHtml(
        store: s,
        docId: docId,
        notePartId: part.id,
        document: doc,
        style: style,
        highlightColor: palette.highlight,
        noteColor: palette.note,
        blankBuilder: blankBuilder,
        imageResolver: images,
        inlineParagraphs: inline,
        tableHeaderColor: headerColor,
        tableBorderColor: borderColor,
      );
    }
    return HtmlView(
      document: doc,
      style: style,
      imageResolver: images,
      blankBuilder: blankBuilder,
      inlineParagraphs: inline,
      blockSpacing: 6, // prose-p:my-1.5
      tableHeaderColor: headerColor,
      tableBorderColor: borderColor,
    );
  }
}

/// Badge label (question.tsx: numbers joined with '-', e.g. "15-16").
String badgeLabel(QuestionPayload q) => q.answerCount > 1
    ? List.generate(q.answerCount, (i) => q.number + i).join('-')
    : '${q.number}';

/// Number bar label (number-bar.tsx: "18–19").
String numberLabel(QuestionPayload q) =>
    q.answerCount > 1 ? '${q.number}–${q.number + q.answerCount - 1}' : '${q.number}';

/// One section (section.tsx: wrapper `p-1 mb-6`).
class SectionView extends StatelessWidget {
  const SectionView({super.key, required this.section, required this.ctx});

  final SectionPayload section;
  final QuestionContext ctx;

  @override
  Widget build(BuildContext context) {
    final type = section.questionType;
    final children = <Widget>[];
    switch (type) {
      case QuestionType.completeSection:
        children.add(CompleteSectionView(section: section, ctx: ctx));
      case QuestionType.dragAndDrop:
        children.add(DragDropSectionView(section: section, ctx: ctx));
      case QuestionType.essay:
        // Writing: the task (text + picture) is already in the left pane; print it here only when that is empty.
        if (htmlToPlainText(ctx.part.html).trim().isEmpty && !ctx.part.html.contains('<img')) children.add(_instructions());
        for (final q in section.questions) {
          children.add(EssayQuestion(question: q, ctx: ctx));
        }
      case QuestionType.matching:
        children
          ..add(_instructions())
          ..add(Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16), // px-3 pb-4
            child: MatchingView(section: section, ctx: ctx),
          ));
      default:
        children
          ..add(_instructions())
          ..add(Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16), // px-3 pb-4
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final (i, q) in section.questions.indexed) ...[
                if (i > 0) const SizedBox(height: 12), // space-y-3
                QuestionView(question: q, section: section, ctx: ctx),
              ],
            ]),
          ));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4 + WebTokens.sectionGap),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }

  /// Non-gap section html: `text-base/8` (16 px / 32 px line height).
  Widget _instructions() {
    if (section.html.trim().isEmpty) return const SizedBox.shrink();
    // Headings dragged into the passage: the draggable list below replaces the static one.
    final dragMode = section.questionType == QuestionType.matching;
    return ctx.html(
      dragMode ? stripHeadingList(section.html, buildRange(section.fromOption, section.toOption)) : section.html,
      inter(16, color: ctx.palette.text, height: WebTokens.sectionInstructionLineHeight),
      docId: questionDocId(sectionId: section.id),
    );
  }
}

/// Number badge (question.tsx / matching.tsx); tap toggles the review flag.
class NumberBadge extends StatelessWidget {
  const NumberBadge({super.key, required this.label, required this.flagged, required this.onTap});

  final String label;
  final bool flagged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Flag for review',
      waitDuration: const Duration(milliseconds: 600),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Stack(clipBehavior: Clip.none, children: [
            Container(
              constraints: const BoxConstraints(minWidth: 24),
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: flagged ? WebTokens.flagBg : TW.white,
                border: Border.all(color: flagged ? WebTokens.flagBorder : TW.black),
                borderRadius: WebTokens.r2,
                boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 1)],
              ),
              child: Text(label,
                  style: inter(12,
                      weight: FontWeight.w700, color: flagged ? WebTokens.flagText : TW.black)),
            ),
            if (flagged)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  width: 12,
                  height: 12,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: TW.orange500, shape: BoxShape.circle),
                  child: Text('★', style: inter(7, color: Colors.white, height: 1)),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

/// question.tsx: badge + text (with `{}` blanks) + options.
class QuestionView extends StatelessWidget {
  const QuestionView({super.key, required this.question, required this.section, required this.ctx});

  final QuestionPayload question;
  final SectionPayload section;
  final QuestionContext ctx;

  @override
  Widget build(BuildContext context) {
    final type = section.questionType;
    final showOptions = type != QuestionType.fillBlank &&
        type != QuestionType.matching &&
        type != QuestionType.essay &&
        type != QuestionType.completeSection;
    final doc = parseHtmlCached(question.html, blankPattern: HtmlDocument.emptyBlankPattern);
    final textStyle = ctx.questionStyle;
    final Widget text = ctx.html(
      question.html,
      textStyle,
      blanks: HtmlDocument.emptyBlankPattern,
      inline: true,
      docId: questionDocId(questionId: question.id),
      blankBuilder: (_, blank) => GapInput(
        key: ValueKey('gap-${question.id}-${blank.index}'),
        initial: ctx.answer(question.id).text ?? '',
        enabled: !ctx.locked,
        fontSize: WebTokens.questionFontSize,
        palette: ctx.palette,
        onChanged: (v) => ctx.setText(question.id, v),
      ),
    );
    return Padding(
      key: ctx.keyFor(question.id),
      padding: const EdgeInsets.only(bottom: 16, top: 6), // mb-4 py-1.5
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 2), // mt-0.5
            child: NumberBadge(
              label: badgeLabel(question),
              flagged: ctx.exam.flagged.contains(question.id),
              onTap: () => ctx.exam.toggleFlag(question.id),
            ),
          ),
          const SizedBox(width: 10), // gap-2.5
          Expanded(child: text),
        ]),
        // fill_blank without a `{}` marker: the web shows no input at all; we
        // add one under the text so the question stays answerable.
        if (type == QuestionType.fillBlank && doc.blankCount == 0)
          Padding(
            padding: const EdgeInsets.only(left: 34, top: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GapInput(
                key: ValueKey('gap-${question.id}'),
                initial: ctx.answer(question.id).text ?? '',
                enabled: !ctx.locked,
                fontSize: WebTokens.questionFontSize,
                palette: ctx.palette,
                onChanged: (v) => ctx.setText(question.id, v),
              ),
            ),
          ),
        if (showOptions) ...[
          const SizedBox(height: 12), // mt-3
          for (final (i, o) in question.options.indexed) ...[
            if (i > 0) const SizedBox(height: 8), // space-y-2
            OptionRow(question: question, section: section, option: o, index: i, ctx: ctx),
          ],
        ],
      ]),
    );
  }
}

/// option.tsx: `label` with a native radio/checkbox (accent-black).
class OptionRow extends StatefulWidget {
  const OptionRow({
    super.key,
    required this.question,
    required this.section,
    required this.option,
    required this.index,
    required this.ctx,
  });

  final QuestionPayload question;
  final SectionPayload section;
  final OptionPayload option;
  final int index;
  final QuestionContext ctx;

  static const standardLabels = {'true', 'false', 'not given', 'yes', 'no'};

  @override
  State<OptionRow> createState() => _OptionRowState();
}

class _OptionRowState extends State<OptionRow> {
  bool _hover = false;

  bool get _multi =>
      widget.section.questionType == QuestionType.multipleResponse || widget.section.inputType == 'checkbox';

  @override
  Widget build(BuildContext context) {
    final ctx = widget.ctx;
    final q = widget.question;
    final o = widget.option;
    final selected = ctx.answer(q.id).optionIds;
    final checked = selected.contains(o.id);
    final limit = _multi ? q.answerCount : 1;
    final disabled = ctx.locked || (_multi && !checked && selected.length >= limit);
    final text = htmlToPlainText(o.html);
    final standard = OptionRow.standardLabels.contains(text.toLowerCase());

    void toggle() {
      if (ctx.locked) return;
      if (_multi) {
        if (checked) {
          ctx.setOptions(q.id, selected.where((id) => id != o.id).toList());
        } else if (selected.length < limit) {
          ctx.setOptions(q.id, [...selected, o.id]);
        }
      } else {
        ctx.setOptions(q.id, [o.id]);
      }
    }

    final p = ctx.palette;
    final textColor = p.standard ? (checked ? TW.black : TW.gray900) : p.text;
    final style = inter(14,
        weight: checked ? FontWeight.w600 : FontWeight.w400,
        color: textColor,
        height: WebTokens.questionLineHeight,
        letterSpacing: -0.35); // tracking-tight
    return MouseRegion(
      cursor: disabled && !checked ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        key: Key('opt-${o.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: disabled && !checked ? null : toggle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // px-3 py-1.5
          decoration: BoxDecoration(
            color: !p.standard
                ? (checked ? p.text.withValues(alpha: 0.2) : Colors.transparent)
                : checked
                    ? WebTokens.optionChecked
                    : (_hover ? WebTokens.optionHover : Colors.transparent),
            borderRadius: WebTokens.r2,
          ),
          child: Row(children: [
            Opacity(
              opacity: disabled && !checked ? 0.5 : 1,
              child: _multi
                  ? NativeCheckbox(checked: checked, color: p.standard ? TW.black : p.text)
                  : NativeRadio(checked: checked, color: p.standard ? TW.black : p.text),
            ),
            const SizedBox(width: 12), // gap-3
            Expanded(
              child: Text.rich(
                TextSpan(children: [
                  if (!standard)
                    TextSpan(
                      text: '${String.fromCharCode(65 + widget.index)}) ',
                      style: style.copyWith(fontWeight: FontWeight.w700),
                    ),
                  TextSpan(text: text.toUpperCase(), style: style),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// `<input type="radio" class="w-4 h-4 accent-black">` look.
class NativeRadio extends StatelessWidget {
  const NativeRadio({super.key, required this.checked, this.color = TW.black});
  final bool checked;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: checked ? color : Colors.white,
          border: Border.all(color: checked ? color : const Color(0xFF767676), width: 1),
        ),
        alignment: Alignment.center,
        child: checked
            ? Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))
            : null,
      );
}

/// `<input type="checkbox" class="w-4 h-4 accent-black">` look.
class NativeCheckbox extends StatelessWidget {
  const NativeCheckbox({super.key, required this.checked, this.color = TW.black});
  final bool checked;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: checked ? color : Colors.white,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: checked ? color : const Color(0xFF767676)),
        ),
        child: checked ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
      );
}

/// app.css `.ielts-gap-input`: underline-only input, 10em wide, 2 px black
/// bottom border, #2563eb on focus.
class GapInput extends StatefulWidget {
  const GapInput({
    super.key,
    required this.initial,
    required this.onChanged,
    required this.palette,
    required this.fontSize,
    this.enabled = true,
  });

  final String initial;
  final ValueChanged<String> onChanged;
  final ExamPalette palette;
  final double fontSize;
  final bool enabled;

  @override
  State<GapInput> createState() => _GapInputState();
}

class _GapInputState extends State<GapInput> {
  late final TextEditingController _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    final line = p.standard ? WebTokens.gapBorder : p.text;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4), // margin 0 4px
      child: SizedBox(
        width: widget.fontSize * WebTokens.gapWidthEm,
        child: TextField(
          controller: _c,
          enabled: widget.enabled,
          onChanged: widget.onChanged,
          // Also cuts long pastes (one oversized answer must never block sync).
          inputFormatters: [LengthLimitingTextInputFormatter(kMaxAnswerChars)],
          autocorrect: false,
          enableSuggestions: false,
          cursorColor: p.standard ? TW.black : p.text,
          style: inter(widget.fontSize, color: p.inputText, height: 1.4),
          decoration: InputDecoration(
            isDense: true,
            // IELTS computer-delivered style: a square-cornered box (app.css .ielts-gap-input).
            contentPadding: const EdgeInsets.fromLTRB(6, 3, 6, 3),
            filled: p.standard,
            fillColor: TW.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: line)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: line)),
            disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero, borderSide: BorderSide(color: line.withValues(alpha: 0.5))),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: p.standard ? WebTokens.gapFocus : p.text, width: 2),
            ),
          ),
        ),
      ),
    );
  }
}

/// complete_section (section.tsx): `{…}` markers become `N.` + gap input;
/// the n-th blank maps to the n-th question.
class CompleteSectionView extends StatelessWidget {
  const CompleteSectionView({super.key, required this.section, required this.ctx});

  final SectionPayload section;
  final QuestionContext ctx;

  @override
  Widget build(BuildContext context) {
    return ctx.html(
      section.html,
      ctx.proseStyle,
      blanks: HtmlDocument.sectionBlankPattern,
      inline: true,
      docId: questionDocId(sectionId: section.id),
      blankBuilder: (context, blank) {
        if (blank.index >= section.questions.length) return const SizedBox.shrink();
        final q = section.questions[blank.index];
        return Row(key: ctx.keyFor(q.id), mainAxisSize: MainAxisSize.min, children: [
          _BlankNumber(q: q, ctx: ctx),
          GapInput(
            key: ValueKey('gap-${q.id}'),
            initial: ctx.answer(q.id).text ?? '',
            enabled: !ctx.locked,
            fontSize: WebTokens.sectionFontSize,
            palette: ctx.palette,
            onChanged: (v) => ctx.setText(q.id, v),
          ),
        ]);
      },
    );
  }
}

/// `<span class="text-blue-600 font-semibold mr-1">{n}.</span>`; click flags.
class _BlankNumber extends StatelessWidget {
  const _BlankNumber({required this.q, required this.ctx});
  final QuestionPayload q;
  final QuestionContext ctx;

  @override
  Widget build(BuildContext context) {
    final flagged = ctx.exam.flagged.contains(q.id);
    return GestureDetector(
      onTap: () => ctx.exam.toggleFlag(q.id),
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Text(
          '${q.number}.${flagged ? '★' : ''}',
          style: inter(16,
              weight: FontWeight.w700, color: flagged ? WebTokens.numberFlag : ctx.c(WebTokens.gapNumber)),
        ),
      ),
    );
  }
}

/// drag_and_drop (section.tsx DraggableOption / DroppablePlaceholder).
class DragDropSectionView extends StatefulWidget {
  const DragDropSectionView({super.key, required this.section, required this.ctx});

  final SectionPayload section;
  final QuestionContext ctx;

  @override
  State<DragDropSectionView> createState() => _DragDropSectionViewState();
}

class _DragDropSectionViewState extends State<DragDropSectionView> {
  /// Click-to-place alternative to dragging (desktop accessibility).
  String? _picked;

  static String _norm(String s) => s.trim().toLowerCase();

  void _place(int questionId, String label) {
    if (widget.ctx.locked) return;
    widget.ctx.setText(questionId, label, debounce: false);
    setState(() => _picked = null);
  }

  @override
  Widget build(BuildContext context) {
    final ctx = widget.ctx;
    final section = widget.section;
    final available = section.dragOptions.map((o) => o.label.trim()).toList();
    for (final q in section.questions) {
      final t = ctx.answer(q.id).text;
      if (t == null) continue;
      final idx = available.indexWhere((l) => _norm(l) == _norm(t));
      if (idx >= 0) available.removeAt(idx);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ctx.html(
        section.html,
        ctx.proseStyle,
        blanks: HtmlDocument.sectionBlankPattern,
        inline: true,
        docId: questionDocId(sectionId: section.id),
        blankBuilder: (context, blank) {
          if (blank.index >= section.questions.length) return const SizedBox.shrink();
          final q = section.questions[blank.index];
          final value = ctx.answer(q.id).text;
          return DragTarget<String>(
            key: ctx.keyFor(q.id),
            onWillAcceptWithDetails: (_) => !ctx.locked,
            onAcceptWithDetails: (d) => _place(q.id, d.data),
            builder: (context, candidates, _) {
              final over = candidates.isNotEmpty || _picked != null;
              return GestureDetector(
                key: Key('drop-${q.id}'),
                onTap: _picked != null ? () => _place(q.id, _picked!) : null,
                child: _DashedBox(
                  color: over && ctx.palette.standard ? WebTokens.dropOverBorder : ctx.c(WebTokens.dropBorder),
                  fill: candidates.isNotEmpty && ctx.palette.standard ? WebTokens.dropOverBg : null,
                  radius: 6,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 120),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('${q.number}.', style: inter(14, weight: FontWeight.w700, color: ctx.c(WebTokens.gapNumber))),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(value ?? '_____',
                            overflow: TextOverflow.ellipsis, style: inter(14, color: ctx.palette.text)),
                      ),
                      if (value != null && !ctx.locked) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => ctx.setText(q.id, '', debounce: false),
                          child: Text('❌', style: inter(10, color: TW.red500)),
                        ),
                      ],
                    ]),
                  ),
                ),
              );
            },
          );
        },
      ),
      const SizedBox(height: 16), // mt-4
      Wrap(spacing: 8, runSpacing: 8, children: [for (final l in available) _chip(l)]),
    ]);
  }

  Widget _chip(String label) {
    final picked = _picked == label;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // px-3 py-1
      decoration: BoxDecoration(
        color: picked ? TW.blue50 : TW.white,
        border: Border.all(color: WebTokens.chipBorder, width: 2),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Text(label, style: inter(14, color: TW.gray900)),
    );
    if (widget.ctx.locked) return Opacity(opacity: 0.5, child: chip);
    return Draggable<String>(
      key: Key('chip-$label'),
      data: label,
      feedback: Material(color: Colors.transparent, child: chip),
      childWhenDragging: Opacity(opacity: 0.5, child: chip), // isDragging opacity-50
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: GestureDetector(onTap: () => setState(() => _picked = picked ? null : label), child: chip),
      ),
    );
  }
}

/// Dashed border box (CSS `border-dashed`).
class _DashedBox extends StatelessWidget {
  const _DashedBox({required this.child, required this.color, this.fill, this.radius = 6});
  final Widget child;
  final Color color;
  final Color? fill;
  final double radius;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _DashPainter(color, fill, radius, 1),
        child: child,
      );
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color, this.fill, this.radius, this.width);
  final Color color;
  final Color? fill;
  final double radius;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(width / 2), Radius.circular(radius));
    if (fill != null) canvas.drawRRect(rrect, Paint()..color = fill!);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 3 * width), paint);
        d += 6 * width;
      }
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) =>
      old.color != color || old.fill != fill || old.radius != radius || old.width != width;
}

/// matching-headings.tsx.
class MatchingView extends StatefulWidget {
  const MatchingView({super.key, required this.section, required this.ctx});

  final SectionPayload section;
  final QuestionContext ctx;

  @override
  State<MatchingView> createState() => _MatchingViewState();
}

class _MatchingViewState extends State<MatchingView> {
  /// Headings with their own text (i … x) are listed above the questions; a bare letter range (A–H) is not.
  bool get _hasTexts => widget.section.options.isNotEmpty;

  List<String> get _headings => _hasTexts
      ? widget.section.options.map((o) => htmlToPlainText(o.html)).toList()
      : buildRange(widget.section.fromOption, widget.section.toOption);

  @override
  Widget build(BuildContext context) {
    final ctx = widget.ctx;
    final headings = _headings;
    final rows = widget.section.questions.where((q) => !ctx.passageQuestionIds.contains(q.id)).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16), // my-4
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // IELTS computer test: every matching task is answered by dragging an option into a box (in the passage
        // or next to the question). No options at all: the old select stays.
        if (headings.isNotEmpty) ...[
          _dragList(headings, widget.section.questions),
          if (rows.isNotEmpty) const SizedBox(height: 24),
        ] else if (_hasTexts) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ctx.palette.standard ? TW.gray50 : ctx.palette.panel,
              border: Border.all(color: ctx.c(TW.gray300), width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('LIST OF HEADINGS',
                  style: inter(14, weight: FontWeight.w700, color: ctx.c(TW.gray800), letterSpacing: 0.7)),
              const SizedBox(height: 10),
              for (final h in headings)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text(h, style: inter(14, color: ctx.c(TW.gray900), height: 1.4)),
                ),
            ]),
          ),
          const SizedBox(height: 24),
        ],
        for (final (i, q) in rows.indexed) ...[
          if (i > 0) const SizedBox(height: 12),
          _row(q, headings),
        ],
      ]),
    );
  }

  /// Headings given as a range (i–vii) with their texts in the instructions: value → text.
  Map<String, String> get _rangeTexts =>
      _hasTexts ? const {} : headingTexts(widget.section.html, _headings);

  /// Headings to drag into the passage boxes. A heading in use leaves the list (letters A–H may repeat).
  Widget _dragList(List<String> headings, List<QuestionPayload> inPassage) {
    final ctx = widget.ctx;
    final texts = _rangeTexts;
    final isHeadings = _hasTexts || texts.isNotEmpty;
    final available = [...headings];
    if (isHeadings) {
      for (final q in inPassage) {
        final t = ctx.answer(q.id).text;
        if (t != null) available.remove(t);
      }
    }
    final picked = ctx.pickedHeading;
    Widget list(String? pickedValue) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ctx.palette.standard ? TW.gray50 : ctx.palette.panel,
            border: Border.all(color: ctx.c(TW.gray300), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isHeadings ? 'LIST OF HEADINGS' : 'OPTIONS',
                style: inter(14, weight: FontWeight.w700, color: ctx.c(TW.gray800), letterSpacing: 0.7)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final h in available)
                  if (isHeadings)
                    SizedBox(
                      width: double.infinity,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: HeadingChip(
                          key: Key('heading-$h'),
                          label: h,
                          display: texts[h],
                          ctx: ctx,
                          picked: pickedValue == h,
                          onTap: picked == null ? null : () => picked.value = pickedValue == h ? null : h,
                        ),
                      ),
                    )
                  else
                  HeadingChip(
                    key: Key('heading-$h'),
                    label: h,
                    ctx: ctx,
                    picked: pickedValue == h,
                    onTap: picked == null ? null : () => picked.value = pickedValue == h ? null : h,
                  ),
              ],
            ),
          ]),
        );
    if (picked == null) return list(null);
    return ValueListenableBuilder<String?>(valueListenable: picked, builder: (_, v, _) => list(v));
  }

  Widget _row(QuestionPayload q, List<String> headings) {
    final ctx = widget.ctx;
    final title = htmlToPlainText(q.html);
    return Container(
      key: ctx.keyFor(q.id),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: ctx.palette.standard ? TW.white : ctx.palette.background,
        border: Border.all(color: ctx.c(TW.gray200)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(children: [
        NumberBadge(
          label: '${q.number}',
          flagged: ctx.exam.flagged.contains(q.id),
          onTap: () => ctx.exam.toggleFlag(q.id),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title.isEmpty ? 'Section / Paragraph ${q.number}' : title,
              style: inter(14, weight: FontWeight.w600, color: ctx.c(TW.gray800), height: 1.375)),
        ),
        const SizedBox(width: 12),
        if (headings.isNotEmpty)
          PassageDropBox(
            question: q,
            ctx: ctx,
            inRow: true,
            compact: !(_hasTexts || _rangeTexts.isNotEmpty),
          )
        else
        AnswerSelect(
          key: Key('select-${q.id}'),
          value: ctx.answer(q.id).text,
          options: headings,
          // Letters fit a narrow box; heading texts need the room.
          width: _hasTexts ? WebTokens.matchingSlotWidth : 96,
          palette: ctx.palette,
          enabled: !ctx.locked,
          onChanged: (v) => ctx.setText(q.id, v, debounce: false),
        ),
      ]),
    );
  }
}

/// A heading to drag into a passage box ([PassageDropBox]); tap picks it for tap-to-place.
class HeadingChip extends StatelessWidget {
  const HeadingChip({
    super.key,
    required this.label,
    required this.ctx,
    this.display,
    this.picked = false,
    this.onTap,
    this.fromQuestionId,
  });

  /// The answer value (heading text, or its number i–vii).
  final String label;

  /// Shown instead of [label] (the full heading when the value is its number).
  final String? display;
  final QuestionContext ctx;
  final bool picked;
  final VoidCallback? onTap;

  /// Set when the chip is the content of a box (dragging it moves the heading).
  final int? fromQuestionId;

  Widget _box({bool dragging = false}) => Container(
        constraints: const BoxConstraints(maxWidth: WebTokens.matchingSlotWidth + 40),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: picked && ctx.palette.standard ? TW.blue50 : (ctx.palette.standard ? TW.white : ctx.palette.background),
          border: Border.all(color: picked ? WebTokens.dropOverBorder : ctx.c(TW.gray400)),
          boxShadow: dragging ? const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))] : null,
        ),
        child: Text(display ?? label, style: inter(14, color: ctx.c(TW.gray900), height: 1.375)),
      );

  @override
  Widget build(BuildContext context) {
    if (ctx.locked) return Opacity(opacity: 0.5, child: _box());
    return Draggable<HeadingDrag>(
      data: HeadingDrag(label, fromQuestionId),
      feedback: Material(color: Colors.transparent, child: _box(dragging: true)),
      childWhenDragging: Opacity(opacity: 0.4, child: _box()),
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: GestureDetector(onTap: onTap, child: _box()),
      ),
    );
  }
}

/// Payload of a heading drag.
class HeadingDrag {
  const HeadingDrag(this.label, [this.fromQuestionId]);
  final String label;
  final int? fromQuestionId;
}

/// A heading box inside the passage (IELTS computer test, web `passage-drop-zone.tsx`): empty it shows the question
/// number; a heading is dropped in from the list (or tapped in after picking it), can be dragged on to another box,
/// and × sends it back.
class PassageDropBox extends StatelessWidget {
  const PassageDropBox({super.key, required this.question, required this.ctx, this.inRow = false, this.compact = false});

  final QuestionPayload question;
  final QuestionContext ctx;

  /// Next to a question in the questions pane: the row has the number badge and the scroll key.
  final bool inRow;

  /// Narrow box (letters A–H).
  final bool compact;

  void _place(HeadingDrag d) {
    if (ctx.locked) return;
    final from = d.fromQuestionId;
    if (from == question.id) return;
    if (from != null) ctx.setText(from, '', debounce: false);
    ctx.setText(question.id, d.label, debounce: false);
  }

  /// The full heading of an answer given as its number (i–vii with the texts in the instructions).
  String _display(String value) {
    final section = ctx.part.sections.where((s) => s.questions.any((q) => q.id == question.id)).firstOrNull;
    if (section == null || section.options.isNotEmpty) return value;
    return headingTexts(section.html, buildRange(section.fromOption, section.toOption))[value] ?? value;
  }

  @override
  Widget build(BuildContext context) {
    final value = ctx.answer(question.id).text;
    final filled = value != null && value.isNotEmpty;
    final picked = ctx.pickedHeading;
    Widget box(String? pickedValue) => DragTarget<HeadingDrag>(
          onWillAcceptWithDetails: (_) => !ctx.locked,
          onAcceptWithDetails: (d) => _place(d.data),
          builder: (context, candidates, _) {
            final over = candidates.isNotEmpty || pickedValue != null;
            final border = over && ctx.palette.standard
                ? WebTokens.dropOverBorder
                : (filled ? ctx.c(TW.black) : ctx.c(TW.gray500));
            final content = Container(
              constraints: BoxConstraints(minWidth: compact ? 110 : 260, minHeight: 36, maxWidth: compact ? 200 : 420),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (!inRow) ...[
                  Text('${question.number}',
                      style: inter(14, weight: FontWeight.w700, color: ctx.c(WebTokens.gapNumber))),
                  const SizedBox(width: 8),
                ],
                if (filled) ...[
                  Flexible(
                    child: Draggable<HeadingDrag>(
                      data: HeadingDrag(value, question.id),
                      maxSimultaneousDrags: ctx.locked ? 0 : 1,
                      feedback: Material(
                        color: Colors.transparent,
                        child: HeadingChip(label: value, display: _display(value), ctx: ctx),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.4,
                        child: Text(_display(value), style: inter(14, weight: FontWeight.w600, color: ctx.palette.text)),
                      ),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        child: Text(_display(value), style: inter(14, weight: FontWeight.w600, color: ctx.palette.text)),
                      ),
                    ),
                  ),
                  if (!ctx.locked) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      key: Key('clear-${question.id}'),
                      onTap: () => ctx.setText(question.id, '', debounce: false),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Text('×', style: inter(16, color: ctx.c(TW.gray500))),
                      ),
                    ),
                  ],
                ],
              ]),
            );
            final decorated = filled && !over
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      color: ctx.palette.standard ? TW.white : ctx.palette.background,
                      border: Border.all(color: border, width: 2),
                    ),
                    child: content,
                  )
                : _DashedBox(
                    color: border,
                    fill: over && ctx.palette.standard ? WebTokens.dropOverBg : (ctx.palette.standard ? TW.white : null),
                    radius: 0,
                    child: content,
                  );
            return GestureDetector(
              key: Key('passage-drop-${question.number}'),
              onTap: pickedValue == null || ctx.locked
                  ? null
                  : () {
                      _place(HeadingDrag(pickedValue));
                      picked?.value = null;
                    },
              child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: decorated),
            );
          },
        );
    final child = picked == null ? box(null) : ValueListenableBuilder<String?>(valueListenable: picked, builder: (_, v, _) => box(v));
    return inRow ? child : KeyedSubtree(key: ctx.keyFor(question.id), child: child);
  }
}

/// IELTS-style answer select: a square black box with the choice and an arrow; "–" clears it.
class AnswerSelect extends StatelessWidget {
  const AnswerSelect({
    super.key,
    required this.value,
    required this.options,
    required this.width,
    required this.palette,
    required this.enabled,
    required this.onChanged,
  });

  final String? value;
  final List<String> options;
  final double width;
  final ExamPalette palette;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final v = (value == null || value!.isEmpty) ? null : value;
    // An answer saved from an older list still shows (the dropdown needs it among the items).
    final items = [...options, if (v != null && !options.contains(v)) v];
    final text = palette.standard ? TW.black : palette.text;
    return Container(
      width: width,
      height: 34,
      padding: const EdgeInsets.only(left: 8, right: 4),
      decoration: BoxDecoration(
        color: palette.standard ? TW.white : palette.background,
        border: Border.all(color: palette.standard ? TW.black : palette.text),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: v,
          isExpanded: true,
          isDense: true,
          hint: Text('', style: inter(14, color: text)),
          icon: Icon(LucideIcons.chevronDown, size: 16, color: text),
          dropdownColor: palette.standard ? TW.white : palette.background,
          borderRadius: BorderRadius.zero,
          style: inter(14, weight: FontWeight.w600, color: text),
          onChanged: enabled ? (s) => onChanged(s ?? '') : null,
          selectedItemBuilder: (context) => [
            Text('', style: inter(14, color: text)),
            for (final o in items) Text(o, overflow: TextOverflow.ellipsis, style: inter(14, weight: FontWeight.w600, color: text)),
          ],
          items: [
            DropdownMenuItem<String>(value: '', child: Text('–', style: inter(14, color: TW.gray500))),
            for (final o in items)
              DropdownMenuItem<String>(
                value: o,
                child: Text(o, overflow: TextOverflow.ellipsis, style: inter(14, color: text)),
              ),
          ],
        ),
      ),
    );
  }
}

int countWords(String text) {
  final t = text.trim();
  return t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length;
}

/// Essay question (question.tsx essay branch): badge + task text, writing
/// progress box and the textarea.
class EssayQuestion extends StatefulWidget {
  const EssayQuestion({super.key, required this.question, required this.ctx});

  final QuestionPayload question;
  final QuestionContext ctx;

  @override
  State<EssayQuestion> createState() => _EssayQuestionState();
}

class _EssayQuestionState extends State<EssayQuestion> {
  late final TextEditingController _c =
      TextEditingController(text: widget.ctx.answer(widget.question.id).text ?? '');
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _c.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// `order === 1 || text includes 'task 1' ? 150 : 250`.
  int get _target {
    final text = htmlToPlainText(widget.question.html).toLowerCase();
    return widget.ctx.part.order == 1 || text.contains('task 1') ? 150 : 250;
  }

  @override
  Widget build(BuildContext context) {
    final ctx = widget.ctx;
    final q = widget.question;
    final words = countWords(_c.text);
    final target = _target;
    final met = words >= target;
    final percent = ((words / target) * 100).round().clamp(0, 100);
    final barColor = met ? TW.emerald500 : (percent > 60 ? TW.blue500 : TW.amber500);

    return Padding(
      key: ctx.keyFor(q.id),
      padding: const EdgeInsets.only(bottom: 16, top: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: NumberBadge(
              label: badgeLabel(q),
              flagged: ctx.exam.flagged.contains(q.id),
              onTap: () => ctx.exam.toggleFlag(q.id),
            ),
          ),
          const SizedBox(width: 10),
          // The task is already in the left pane (part text): do not print it twice.
          if (htmlToPlainText(ctx.part.html).trim().isEmpty && !ctx.part.html.contains('<img'))
            Expanded(child: ctx.html(q.html, ctx.questionStyle, docId: questionDocId(questionId: q.id)))
          else
            const Spacer(),
        ]),
        const SizedBox(height: 16), // mt-4
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: TW.gray50,
            border: Border.all(color: TW.gray200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Only the word count: characters, paragraphs, reading time and "Needed N words" were noise.
            Row(children: [
              Text('WRITING PROGRESS:', style: inter(12, weight: FontWeight.w700, color: TW.gray700, letterSpacing: 0.3)),
              const SizedBox(width: 8),
              Text('$words / $target words',
                  key: const Key('word-count'), style: mono(14, weight: FontWeight.w800, color: TW.gray900)),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: SizedBox(
                height: 8,
                child: Stack(children: [
                  Container(color: TW.gray200),
                  FractionallySizedBox(widthFactor: percent / 100, child: Container(color: barColor)),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: WebTokens.essayMinHeight),
          child: TextField(
            key: Key('essay-${q.id}'),
            controller: _c,
            focusNode: _focus,
            enabled: !ctx.locked,
            inputFormatters: [LengthLimitingTextInputFormatter(kMaxAnswerChars)],
            minLines: 16,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            autocorrect: false,
            enableSuggestions: false,
            cursorColor: TW.gray900,
            style: inter(16, color: TW.gray900, height: 1.65),
            decoration: InputDecoration(
              hintText: 'Type your essay here...',
              hintStyle: inter(16, color: TW.gray400, height: 1.65),
              filled: true,
              fillColor: TW.white,
              contentPadding: const EdgeInsets.all(16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: WebTokens.essayBorder, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: WebTokens.essayBorder, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: WebTokens.essayFocus, width: 2),
              ),
            ),
            onChanged: (v) {
              setState(() {});
              ctx.setText(q.id, v);
            },
          ),
        ),
      ]),
    );
  }
}
