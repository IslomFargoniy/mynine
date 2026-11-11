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
  });

  final ExamController exam;
  final PartPayload part;
  final ExamPalette palette;

  /// Question id → key, used by the number bar to scroll to a question.
  final Map<int, GlobalKey> keys;
  final ImageResolver? images;

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

  HtmlView html(String html, TextStyle style, {RegExp? blanks, BlankBuilder? blankBuilder, bool inline = false}) =>
      HtmlView(
        document: parseHtmlCached(html, blankPattern: blanks),
        style: style,
        imageResolver: images,
        blankBuilder: blankBuilder,
        inlineParagraphs: inline,
        blockSpacing: 6, // prose-p:my-1.5
        tableHeaderColor: palette.standard ? WebTokens.tableHeaderBg : null,
        tableBorderColor: palette.standard ? WebTokens.tableBorder : palette.text,
      );
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
        children.add(_instructions());
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
    return ctx.html(
      section.html,
      inter(16, color: ctx.palette.text, height: WebTokens.sectionInstructionLineHeight),
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
                border: Border.all(color: flagged ? WebTokens.flagBorder : WebTokens.badgeBlue),
                borderRadius: WebTokens.r2,
                boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 1)],
              ),
              child: Text(label,
                  style: inter(12,
                      weight: FontWeight.w700, color: flagged ? WebTokens.flagText : WebTokens.badgeBlue)),
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
            contentPadding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
            border: UnderlineInputBorder(borderSide: BorderSide(color: line, width: 2)),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: line, width: 2)),
            disabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: line.withValues(alpha: 0.5), width: 2)),
            focusedBorder: UnderlineInputBorder(
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
              weight: FontWeight.w600, color: flagged ? WebTokens.numberFlag : ctx.c(WebTokens.gapNumber)),
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
                      Text('${q.number}.', style: inter(14, weight: FontWeight.w600, color: ctx.c(TW.blue600))),
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
  const _DashedBox({required this.child, required this.color, this.fill, this.radius = 6, this.width = 1});
  final Widget child;
  final Color color;
  final Color? fill;
  final double radius;
  final double width;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _DashPainter(color, fill, radius, width),
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
  String? _selected;

  List<String> get _headings => widget.section.options.isNotEmpty
      ? widget.section.options.map((o) => htmlToPlainText(o.html)).toList()
      : buildRange(widget.section.fromOption, widget.section.toOption);

  void _place(int questionId, String value) {
    if (widget.ctx.locked) return;
    widget.ctx.setText(questionId, value, debounce: false);
    setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    final ctx = widget.ctx;
    final used = {
      for (final q in widget.section.questions)
        if (ctx.answer(q.id).text != null) ctx.answer(q.id).text!,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16), // my-4
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ctx.palette.standard ? TW.gray50 : ctx.palette.panel,
            border: Border.all(color: ctx.c(TW.gray300), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(
                child: Text('LIST OF HEADINGS',
                    style: inter(14, weight: FontWeight.w700, color: ctx.c(TW.gray800), letterSpacing: 0.7)),
              ),
              Text('(drag heading or click to place)', style: inter(12, color: ctx.c(TW.gray500))),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final h in _headings) _heading(h, used.contains(h)),
            ]),
          ]),
        ),
        const SizedBox(height: 24), // space-y-6
        for (final (i, q) in widget.section.questions.indexed) ...[
          if (i > 0) const SizedBox(height: 16), // space-y-4
          _slot(q),
        ],
      ]),
    );
  }

  Widget _heading(String h, bool isUsed) {
    final ctx = widget.ctx;
    final selected = _selected == h;
    final Color bg;
    final Color border;
    final Color fg;
    if (isUsed) {
      bg = TW.gray200;
      border = TW.gray300;
      fg = TW.gray400;
    } else if (selected) {
      bg = TW.blue600;
      border = TW.blue700;
      fg = TW.white;
    } else {
      bg = TW.white;
      border = TW.gray300;
      fg = TW.gray900;
    }
    final box = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), // px-3.5 py-2
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          if (selected) const BoxShadow(color: TW.blue400, spreadRadius: 2),
          const BoxShadow(color: Color(0x0D000000), blurRadius: 1),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (!isUsed) ...[
          Icon(LucideIcons.gripVertical, size: 16, color: selected ? TW.white : TW.gray400),
          const SizedBox(width: 8),
        ],
        Text(h,
            style: inter(14,
                weight: FontWeight.w500,
                color: fg,
                decoration: isUsed ? TextDecoration.lineThrough : null)),
      ]),
    );
    if (isUsed) return Opacity(opacity: 0.6, child: box);
    if (ctx.locked) return Opacity(opacity: 0.5, child: box);
    return Draggable<String>(
      data: h,
      feedback: Material(color: Colors.transparent, child: box),
      childWhenDragging: Opacity(opacity: 0.4, child: box),
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: GestureDetector(
          key: Key('heading-$h'),
          onTap: () => setState(() => _selected = selected ? null : h),
          child: box,
        ),
      ),
    );
  }

  Widget _slot(QuestionPayload q) {
    final ctx = widget.ctx;
    final value = ctx.answer(q.id).text;
    final title = htmlToPlainText(q.html);
    return Container(
      key: ctx.keyFor(q.id),
      padding: const EdgeInsets.all(14), // p-3.5
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
        DragTarget<String>(
          onWillAcceptWithDetails: (_) => !ctx.locked,
          onAcceptWithDetails: (d) => _place(q.id, d.data),
          builder: (context, candidates, _) {
            final Color borderColor;
            final Color fill;
            if (value != null) {
              borderColor = TW.blue500;
              fill = const Color(0x80EFF6FF); // blue-50/50
            } else if (_selected != null || candidates.isNotEmpty) {
              borderColor = TW.blue400;
              fill = const Color(0x33EFF6FF); // blue-50/20
            } else {
              borderColor = TW.gray300;
              fill = const Color(0x80F9FAFB); // gray-50/50
            }
            return GestureDetector(
              key: Key('slot-${q.id}'),
              onTap: _selected != null ? () => _place(q.id, _selected!) : null,
              child: _DashedBox(
                color: ctx.palette.standard ? borderColor : ctx.palette.text,
                fill: ctx.palette.standard ? fill : null,
                width: 2,
                child: Container(
                  width: WebTokens.matchingSlotWidth,
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.all(8),
                  alignment: Alignment.centerLeft,
                  child: value == null
                      ? Text(_selected != null ? 'Click here to place heading' : 'Drop heading here',
                          style: inter(12, weight: FontWeight.w500, color: ctx.c(TW.gray400), style: FontStyle.italic))
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: TW.white,
                            border: Border.all(color: TW.blue300),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(children: [
                            Expanded(
                              child: Text(value,
                                  overflow: TextOverflow.ellipsis,
                                  style: inter(14, weight: FontWeight.w600, color: TW.blue900)),
                            ),
                            if (!ctx.locked)
                              GestureDetector(
                                onTap: () => ctx.setText(q.id, '', debounce: false),
                                child: const Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Icon(LucideIcons.x, size: 16, color: TW.red500),
                                ),
                              ),
                          ]),
                        ),
                ),
              ),
            );
          },
        ),
      ]),
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
    final chars = _c.text.length;
    final paragraphs =
        _c.text.trim().isEmpty ? 0 : _c.text.trim().split(RegExp(r'\n+')).where((s) => s.isNotEmpty).length;
    final readMin = (words / 130).ceil() < 1 ? 1 : (words / 130).ceil();
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
          Expanded(child: ctx.html(q.html, ctx.questionStyle)),
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
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('WRITING PROGRESS:',
                      style: inter(12, weight: FontWeight.w700, color: TW.gray700, letterSpacing: 0.3)),
                  const SizedBox(width: 8),
                  Text('$words / $target words',
                      key: const Key('word-count'), style: mono(14, weight: FontWeight.w800, color: TW.gray900)),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: met ? TW.emerald100 : TW.amber100,
                    border: Border.all(color: met ? TW.emerald300 : TW.amber300),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    met ? 'Minimum target reached ✅' : 'Needed ${target - words} words',
                    style: inter(12, weight: FontWeight.w700, color: met ? TW.emerald800 : TW.amber800),
                  ),
                ),
              ],
            ),
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
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(style: inter(11, color: TW.gray500), children: [
                const TextSpan(text: 'Characters: '),
                TextSpan(text: '$chars', style: const TextStyle(fontWeight: FontWeight.w700)),
                const TextSpan(text: '   •   Paragraphs: '),
                TextSpan(text: '$paragraphs', style: const TextStyle(fontWeight: FontWeight.w700)),
                const TextSpan(text: '   •   Est. reading time: '),
                TextSpan(text: '$readMin min', style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
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
