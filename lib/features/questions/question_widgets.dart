import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models/part_payload.dart';
import '../exam/exam_controller.dart';
import '../passage/html_document.dart';
import '../passage/html_view.dart';
import 'range.dart';

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

  TextStyle get textStyle => TextStyle(color: palette.text, fontSize: 15, height: 1.6);
}

/// Display label of a question number ("7" or "15–16" for "choose TWO").
String numberLabel(QuestionPayload q) =>
    q.answerCount > 1 ? '${q.number}–${q.number + q.answerCount - 1}' : '${q.number}';

/// Renders one section according to its question type (mirrors
/// `practice-section.tsx` / `practice-question.tsx` of the web exam room).
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
      case QuestionType.matching:
        children
          ..add(_instructions())
          ..add(const SizedBox(height: 12))
          ..add(MatchingView(section: section, ctx: ctx));
      case QuestionType.essay:
        children.add(EssayView(section: section, ctx: ctx));
      default:
        children
          ..add(_instructions())
          ..add(const SizedBox(height: 8));
        for (final q in section.questions) {
          children.add(type == QuestionType.fillBlank
              ? FillBlankQuestionView(question: q, ctx: ctx)
              : ChoiceQuestionView(question: q, section: section, ctx: ctx));
        }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }

  Widget _instructions() {
    if (section.html.trim().isEmpty) return const SizedBox.shrink();
    return HtmlView(
      document: parseHtmlCached(section.html),
      style: ctx.textStyle,
      imageResolver: ctx.images,
    );
  }
}

/// Blue square with the question number; tap toggles the review flag.
class NumberBadge extends StatelessWidget {
  const NumberBadge({super.key, required this.label, required this.flagged, required this.onTap});

  final String label;
  final bool flagged;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = flagged ? AppColors.flag : AppColors.blue;
    return Tooltip(
      message: flagged ? 'Remove review flag' : 'Flag for review',
      child: InkWell(
        onTap: onTap,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            constraints: const BoxConstraints(minWidth: 26),
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: flagged ? const Color(0xFFFFF7ED) : Colors.white,
              border: Border.all(color: color),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          if (flagged)
            const Positioned(
              right: -5,
              top: -5,
              child: Icon(Icons.star, size: 12, color: AppColors.flag),
            ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Choice questions: multiple_choice, true_false, yes_no, multiple_response

class ChoiceQuestionView extends StatelessWidget {
  const ChoiceQuestionView({super.key, required this.question, required this.section, required this.ctx});

  final QuestionPayload question;
  final SectionPayload section;
  final QuestionContext ctx;

  bool get _multi =>
      section.questionType == QuestionType.multipleResponse || section.inputType == 'checkbox';

  static const _standardLabels = {'true', 'false', 'not given', 'yes', 'no'};

  @override
  Widget build(BuildContext context) {
    final selected = ctx.answer(question.id).optionIds;
    final limit = _multi ? question.answerCount : 1;
    return Padding(
      key: ctx.keyFor(question.id),
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          NumberBadge(
            label: numberLabel(question),
            flagged: ctx.exam.flagged.contains(question.id),
            onTap: () => ctx.exam.toggleFlag(question.id),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: HtmlView(
              document: parseHtmlCached(question.html),
              style: ctx.textStyle,
              imageResolver: ctx.images,
            ),
          ),
        ]),
        const SizedBox(height: 6),
        for (final (i, o) in question.options.indexed)
          _option(context, i, o, selected, limit),
      ]),
    );
  }

  Widget _option(BuildContext context, int index, OptionPayload o, List<int> selected, int limit) {
    final checked = selected.contains(o.id);
    final text = htmlToPlainText(o.html);
    final standard = _standardLabels.contains(text.toLowerCase());
    final disabled = ctx.locked || (_multi && !checked && selected.length >= limit);
    void toggle() {
      if (ctx.locked) return;
      if (_multi) {
        if (checked) {
          ctx.setOptions(question.id, selected.where((id) => id != o.id).toList());
        } else if (selected.length < limit) {
          ctx.setOptions(question.id, [...selected, o.id]);
        }
      } else {
        ctx.setOptions(question.id, [o.id]);
      }
    }

    final p = ctx.palette;
    return Padding(
      padding: const EdgeInsets.only(left: 36, bottom: 2),
      child: Material(
        color: checked ? p.accent.withValues(alpha: 0.14) : Colors.transparent,
        child: InkWell(
          key: Key('opt-${o.id}'),
          onTap: disabled && !checked ? null : toggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Row(children: [
              _multi
                  ? Checkbox(value: checked, onChanged: disabled && !checked ? null : (_) => toggle())
                  : Radio<int>(value: o.id),
              const SizedBox(width: 4),
              if (!standard)
                Text('${String.fromCharCode(65 + index)}  ',
                    style: TextStyle(fontWeight: FontWeight.bold, color: p.text)),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: p.text,
                    fontSize: 15,
                    fontWeight: checked ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    ).wrapRadioGroup(_multi, selected.isEmpty ? null : selected.first, (v) {
      if (v != null && !ctx.locked) ctx.setOptions(question.id, [v]);
    });
  }
}

extension on Widget {
  /// Flutter 3.32+ radios read their selection from an enclosing RadioGroup.
  Widget wrapRadioGroup(bool multi, int? groupValue, ValueChanged<int?> onChanged) =>
      multi ? this : RadioGroup<int>(groupValue: groupValue, onChanged: onChanged, child: this);
}

// ---------------------------------------------------------------------------
// Text input used for blanks (keeps its own controller across rebuilds).

class GapField extends StatefulWidget {
  const GapField({
    super.key,
    required this.initial,
    required this.onChanged,
    required this.palette,
    this.enabled = true,
    this.width = 150,
    this.hint,
  });

  final String initial;
  final ValueChanged<String> onChanged;
  final ExamPalette palette;
  final bool enabled;
  final double width;
  final String? hint;

  @override
  State<GapField> createState() => _GapFieldState();
}

class _GapFieldState extends State<GapField> {
  late final TextEditingController _c = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return SizedBox(
      width: widget.width,
      height: 30,
      child: TextField(
        controller: _c,
        enabled: widget.enabled,
        onChanged: widget.onChanged,
        autocorrect: false,
        enableSuggestions: false,
        style: TextStyle(fontSize: 14, color: p.inputText),
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isDense: true,
          hintText: widget.hint,
          filled: true,
          fillColor: p.inputFill,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: BorderSide(color: p.muted)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(2), borderSide: BorderSide(color: p.muted)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(2), borderSide: BorderSide(color: p.accent, width: 2)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// fill_blank: `{}` inside the question text becomes an input.

class FillBlankQuestionView extends StatelessWidget {
  const FillBlankQuestionView({super.key, required this.question, required this.ctx});

  final QuestionPayload question;
  final QuestionContext ctx;

  @override
  Widget build(BuildContext context) {
    final doc = parseHtmlCached(question.html, blankPattern: HtmlDocument.emptyBlankPattern);
    final initial = ctx.answer(question.id).text ?? '';
    Widget field() => GapField(
          key: ValueKey('gap-${question.id}'),
          initial: initial,
          enabled: !ctx.locked,
          palette: ctx.palette,
          onChanged: (v) => ctx.setText(question.id, v),
        );
    return Padding(
      key: ctx.keyFor(question.id),
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        NumberBadge(
          label: numberLabel(question),
          flagged: ctx.exam.flagged.contains(question.id),
          onTap: () => ctx.exam.toggleFlag(question.id),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: doc.blankCount > 0
              ? HtmlView(
                  document: doc,
                  style: ctx.textStyle,
                  imageResolver: ctx.images,
                  // All blanks of one question share the same answer (web behaviour).
                  blankBuilder: (_, blank) => blank.index == 0 ? field() : const Text('____'),
                )
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  HtmlView(document: doc, style: ctx.textStyle, imageResolver: ctx.images),
                  const SizedBox(height: 6),
                  field(),
                ]),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// complete_section: `{…}` markers in the section HTML, n-th blank → n-th question.

class CompleteSectionView extends StatelessWidget {
  const CompleteSectionView({super.key, required this.section, required this.ctx});

  final SectionPayload section;
  final QuestionContext ctx;

  @override
  Widget build(BuildContext context) {
    final doc = parseHtmlCached(section.html, blankPattern: HtmlDocument.sectionBlankPattern);
    return HtmlView(
      document: doc,
      style: ctx.textStyle,
      imageResolver: ctx.images,
      blankBuilder: (context, blank) {
        if (blank.index >= section.questions.length) return const SizedBox.shrink();
        final q = section.questions[blank.index];
        return Padding(
          key: ctx.keyFor(q.id),
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            _InlineNumber(q: q, ctx: ctx),
            const SizedBox(width: 4),
            GapField(
              key: ValueKey('gap-${q.id}'),
              initial: ctx.answer(q.id).text ?? '',
              enabled: !ctx.locked,
              palette: ctx.palette,
              onChanged: (v) => ctx.setText(q.id, v),
            ),
          ]),
        );
      },
    );
  }
}

class _InlineNumber extends StatelessWidget {
  const _InlineNumber({required this.q, required this.ctx});
  final QuestionPayload q;
  final QuestionContext ctx;

  @override
  Widget build(BuildContext context) {
    final flagged = ctx.exam.flagged.contains(q.id);
    return InkWell(
      onTap: () => ctx.exam.toggleFlag(q.id),
      child: Text(
        '${numberLabel(q)}${flagged ? '★' : ''}',
        style: TextStyle(
          color: flagged ? AppColors.flag : ctx.palette.accent,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// drag_and_drop: drop a drag_options label onto a blank; saved as text.

class DragDropSectionView extends StatefulWidget {
  const DragDropSectionView({super.key, required this.section, required this.ctx});

  final SectionPayload section;
  final QuestionContext ctx;

  @override
  State<DragDropSectionView> createState() => _DragDropSectionViewState();
}

class _DragDropSectionViewState extends State<DragDropSectionView> {
  /// Label picked by click (click-to-place alternative to dragging).
  String? _picked;

  static String _norm(String s) => s.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    final ctx = widget.ctx;
    final section = widget.section;
    final labels = section.dragOptions.map((o) => o.label.trim()).toList();

    // Each label can be used once: remove labels assigned to any blank.
    final available = List.of(labels);
    for (final q in section.questions) {
      final t = ctx.answer(q.id).text;
      if (t == null) continue;
      final idx = available.indexWhere((l) => _norm(l) == _norm(t));
      if (idx >= 0) available.removeAt(idx);
    }

    void place(int questionId, String label) {
      if (ctx.locked) return;
      ctx.setText(questionId, label, debounce: false);
      setState(() => _picked = null);
    }

    final doc = parseHtmlCached(section.html, blankPattern: HtmlDocument.sectionBlankPattern);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      HtmlView(
        document: doc,
        style: ctx.textStyle,
        imageResolver: ctx.images,
        blankBuilder: (context, blank) {
          if (blank.index >= section.questions.length) return const SizedBox.shrink();
          final q = section.questions[blank.index];
          final value = ctx.answer(q.id).text;
          return DragTarget<String>(
            key: ctx.keyFor(q.id),
            onWillAcceptWithDetails: (_) => !ctx.locked,
            onAcceptWithDetails: (d) => place(q.id, d.data),
            builder: (context, candidates, _) {
              final hovering = candidates.isNotEmpty;
              return GestureDetector(
                onTap: _picked != null ? () => place(q.id, _picked!) : null,
                child: Container(
                  key: Key('drop-${q.id}'),
                  constraints: const BoxConstraints(minWidth: 120),
                  margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: hovering ? AppColors.blue.withValues(alpha: 0.12) : ctx.palette.inputFill,
                    border: Border.all(
                      color: hovering || _picked != null ? AppColors.blue : ctx.palette.muted,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _InlineNumber(q: q, ctx: ctx),
                    const SizedBox(width: 6),
                    Text(value ?? '_____', style: TextStyle(color: ctx.palette.inputText, fontSize: 14)),
                    if (value != null && !ctx.locked) ...[
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => ctx.setText(q.id, '', debounce: false),
                        child: const Icon(Icons.close, size: 14, color: Colors.red),
                      ),
                    ],
                  ]),
                ),
              );
            },
          );
        },
      ),
      const SizedBox(height: 16),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final label in available) _chip(label),
      ]),
    ]);
  }

  Widget _chip(String label) {
    final picked = _picked == label;
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: picked ? AppColors.blue : Colors.white,
        border: Border.all(color: AppColors.blue, width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: picked ? Colors.white : AppColors.ink, fontSize: 14)),
    );
    if (widget.ctx.locked) return Opacity(opacity: 0.5, child: chip);
    return Draggable<String>(
      key: Key('chip-$label'),
      data: label,
      feedback: Material(color: Colors.transparent, child: chip),
      childWhenDragging: Opacity(opacity: 0.4, child: chip),
      child: GestureDetector(
        onTap: () => setState(() => _picked = picked ? null : label),
        child: MouseRegion(cursor: SystemMouseCursors.grab, child: chip),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// matching / matching headings (web: MatchingHeadings). Saved as text.

class MatchingView extends StatefulWidget {
  const MatchingView({super.key, required this.section, required this.ctx});

  final SectionPayload section;
  final QuestionContext ctx;

  @override
  State<MatchingView> createState() => _MatchingViewState();
}

class _MatchingViewState extends State<MatchingView> {
  String? _picked;

  List<String> get _headings => widget.section.options.isNotEmpty
      ? widget.section.options.map((o) => htmlToPlainText(o.html)).toList()
      : buildRange(widget.section.fromOption, widget.section.toOption);

  void _place(int questionId, String value) {
    if (widget.ctx.locked) return;
    widget.ctx.setText(questionId, value, debounce: false);
    setState(() => _picked = null);
  }

  @override
  Widget build(BuildContext context) {
    final ctx = widget.ctx;
    final p = ctx.palette;
    final headings = _headings;
    final used = {
      for (final q in widget.section.questions)
        if (ctx.answer(q.id).text != null) ctx.answer(q.id).text!,
    };
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: p.panel, border: Border.all(color: p.muted, width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.section.options.isNotEmpty ? 'LIST OF HEADINGS' : 'OPTIONS',
              style: TextStyle(fontWeight: FontWeight.bold, color: p.text, letterSpacing: 0.8, fontSize: 12)),
          const SizedBox(height: 4),
          Text('Drag an item onto a question, or click an item and then click a question.',
              style: TextStyle(fontSize: 11, color: p.muted)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final h in headings) _heading(h, used.contains(h)),
          ]),
        ]),
      ),
      const SizedBox(height: 14),
      for (final q in widget.section.questions) _slot(q),
    ]);
  }

  Widget _heading(String h, bool isUsed) {
    final p = widget.ctx.palette;
    final picked = _picked == h;
    final box = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isUsed ? const Color(0xFFE5E7EB) : (picked ? AppColors.blue : p.inputFill),
        border: Border.all(color: picked ? AppColors.blue : p.muted),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        h,
        style: TextStyle(
          fontSize: 14,
          color: isUsed ? Colors.grey : (picked ? Colors.white : p.inputText),
          decoration: isUsed ? TextDecoration.lineThrough : null,
        ),
      ),
    );
    if (isUsed || widget.ctx.locked) return Opacity(opacity: isUsed ? 0.6 : 0.5, child: box);
    return Draggable<String>(
      data: h,
      feedback: Material(color: Colors.transparent, child: box),
      childWhenDragging: Opacity(opacity: 0.4, child: box),
      child: GestureDetector(
        key: Key('heading-$h'),
        onTap: () => setState(() => _picked = picked ? null : h),
        child: MouseRegion(cursor: SystemMouseCursors.grab, child: box),
      ),
    );
  }

  Widget _slot(QuestionPayload q) {
    final ctx = widget.ctx;
    final p = ctx.palette;
    final value = ctx.answer(q.id).text;
    final title = htmlToPlainText(q.html);
    return Container(
      key: ctx.keyFor(q.id),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: p.background, border: Border.all(color: p.muted.withValues(alpha: 0.4))),
      child: Row(children: [
        NumberBadge(
          label: numberLabel(q),
          flagged: ctx.exam.flagged.contains(q.id),
          onTap: () => ctx.exam.toggleFlag(q.id),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title.isEmpty ? 'Question ${q.number}' : title,
              style: TextStyle(fontWeight: FontWeight.w600, color: p.text, fontSize: 14)),
        ),
        const SizedBox(width: 10),
        DragTarget<String>(
          onWillAcceptWithDetails: (_) => !ctx.locked,
          onAcceptWithDetails: (d) => _place(q.id, d.data),
          builder: (context, candidates, _) => GestureDetector(
            key: Key('slot-${q.id}'),
            onTap: _picked != null ? () => _place(q.id, _picked!) : null,
            child: Container(
              width: 340,
              constraints: const BoxConstraints(minHeight: 40),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: candidates.isNotEmpty
                    ? AppColors.blue.withValues(alpha: 0.1)
                    : (value != null ? AppColors.blue.withValues(alpha: 0.05) : p.panel),
                border: Border.all(
                  color: value != null || _picked != null || candidates.isNotEmpty ? AppColors.blue : p.muted,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: value == null
                  ? Text(_picked != null ? 'Click here to place' : 'Drop here',
                      style: TextStyle(fontSize: 12, color: p.muted, fontStyle: FontStyle.italic))
                  : Row(children: [
                      Expanded(
                        child: Text(value,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w600, color: p.inputText, fontSize: 14)),
                      ),
                      if (!ctx.locked)
                        InkWell(
                          onTap: () => ctx.setText(q.id, '', debounce: false),
                          child: const Icon(Icons.close, size: 16, color: Colors.red),
                        ),
                    ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// essay (Writing) with word count.

int countWords(String text) {
  final t = text.trim();
  return t.isEmpty ? 0 : t.split(RegExp(r'\s+')).length;
}

class EssayView extends StatelessWidget {
  const EssayView({super.key, required this.section, required this.ctx});

  final SectionPayload section;
  final QuestionContext ctx;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final q in section.questions) EssayEditor(question: q, ctx: ctx),
    ]);
  }
}

class EssayEditor extends StatefulWidget {
  const EssayEditor({super.key, required this.question, required this.ctx});

  final QuestionPayload question;
  final QuestionContext ctx;

  @override
  State<EssayEditor> createState() => _EssayEditorState();
}

class _EssayEditorState extends State<EssayEditor> {
  late final TextEditingController _c =
      TextEditingController(text: widget.ctx.answer(widget.question.id).text ?? '');

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  int get _target {
    final text = htmlToPlainText(widget.question.html).toLowerCase();
    final partText = htmlToPlainText(widget.ctx.part.html).toLowerCase();
    if (widget.ctx.part.order == 1 || text.contains('task 1') || partText.contains('task 1')) return 150;
    return 250;
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.ctx.palette;
    final words = countWords(_c.text);
    final target = _target;
    final met = words >= target;
    final paragraphs = _c.text.trim().isEmpty
        ? 0
        : _c.text.trim().split(RegExp(r'\n+')).where((s) => s.trim().isNotEmpty).length;
    return Column(
      key: widget.ctx.keyFor(widget.question.id),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: p.panel, border: Border.all(color: p.muted.withValues(alpha: 0.4))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Text('Words: ', style: TextStyle(fontWeight: FontWeight.bold, color: p.text)),
              Text('$words / $target',
                  key: const Key('word-count'),
                  style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w800, color: p.text)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: met ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  met ? 'Minimum reached' : '${target - words} more words needed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: met ? const Color(0xFF065F46) : const Color(0xFF92400E),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (words / target).clamp(0.0, 1.0),
              color: met ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
              backgroundColor: const Color(0xFFE5E7EB),
            ),
            const SizedBox(height: 6),
            Text('Characters: ${_c.text.length}   •   Paragraphs: $paragraphs',
                style: TextStyle(fontSize: 11, color: p.muted)),
          ]),
        ),
        const SizedBox(height: 10),
        TextField(
          key: Key('essay-${widget.question.id}'),
          controller: _c,
          enabled: !widget.ctx.locked,
          minLines: 18,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          autocorrect: false,
          enableSuggestions: false,
          style: TextStyle(fontSize: 16, height: 1.6, color: p.inputText),
          decoration: InputDecoration(
            hintText: 'Type your answer here…',
            filled: true,
            fillColor: p.inputFill,
            contentPadding: const EdgeInsets.all(14),
          ),
          onChanged: (v) {
            setState(() {});
            widget.ctx.setText(widget.question.id, v);
          },
        ),
      ],
    );
  }
}

