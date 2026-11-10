import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/time/server_clock.dart';
import '../../data/models/exam_models.dart';
import '../../data/models/part_payload.dart';
import '../passage/passage_pane.dart';
import '../questions/question_widgets.dart';
import 'exam_controller.dart';
import 'listening_audio.dart';

/// Inspera-style exam room: header (timer, accessibility, finish), the
/// module body (Listening / Reading split / Writing split) and the footer
/// with part navigation and the question number bar.
class ExamShell extends ConsumerStatefulWidget {
  const ExamShell({super.key});

  @override
  ConsumerState<ExamShell> createState() => _ExamShellState();
}

class _ExamShellState extends ConsumerState<ExamShell> {
  final Map<int, GlobalKey> _questionKeys = {};
  final ScrollController _questionsScroll = ScrollController();
  double _split = 0.5;
  bool _notesOpen = false;
  HighlightStore? _store;

  @override
  void dispose() {
    _questionsScroll.dispose();
    _store?.dispose();
    super.dispose();
  }

  HighlightStore _storeFor(ExamController exam) {
    final id = exam.attemptId ?? 0;
    if (_store == null || _store!.attemptId != id) {
      _store?.dispose();
      _store = HighlightStore(ref.read(databaseProvider), id);
    }
    return _store!;
  }

  ImageProvider? _resolveImage(ExamController exam, String src) {
    final files = exam.cached?.imageFiles ?? const {};
    String? path = files[src];
    if (path == null) {
      for (final e in files.entries) {
        if (e.key.endsWith(src) || src.endsWith(Uri.tryParse(e.key)?.path ?? '\u0000')) {
          path = e.value;
          break;
        }
      }
    }
    if (path != null && File(path).existsSync()) return FileImage(File(path));
    if (src.startsWith('http')) return NetworkImage(src);
    return null;
  }

  void _goToQuestion(ExamController exam, int questionId) {
    exam.setActiveQuestion(questionId);
    final ctx = _questionKeys[questionId]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250), alignment: 0.3);
    }
  }

  Future<void> _confirmFinish(ExamController exam) async {
    final module = exam.currentModule;
    if (module == null) return;
    final stats = exam.stats(exam.currentParts);
    final isLast = exam.modules.lastOrNull?.typeId == module.typeId;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => FinishDialog(
        title: isLast ? 'Finish the exam' : 'Finish ${module.title}',
        answered: stats.answered,
        total: stats.total,
        isLast: isLast,
      ),
    );
    if (ok == true) await exam.confirmFinishModule();
  }

  @override
  Widget build(BuildContext context) {
    final exam = ref.watch(examControllerProvider);
    final settings = ref.watch(examViewSettingsProvider);
    final palette = ExamPalette.of(settings.contrast);
    return ListenableBuilder(
      listenable: exam,
      builder: (context, _) {
        final module = exam.currentModule;
        final part = exam.currentPart;
        if (module == null || part == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): () => exam.stepPart(1),
            const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): () => exam.stepPart(-1),
          },
          child: Scaffold(
            backgroundColor: palette.background,
            body: Stack(children: [
              Column(children: [
                _Header(
                  exam: exam,
                  module: module,
                  onFinish: () => _confirmFinish(exam),
                  onToggleNotes: module.isListening ? null : () => setState(() => _notesOpen = !_notesOpen),
                ),
                Expanded(
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(settings.textScale)),
                    child: DefaultTextStyle(
                      style: TextStyle(color: palette.text, fontSize: 15),
                      child: _body(exam, module, part, palette),
                    ),
                  ),
                ),
                _Footer(exam: exam, module: module, onQuestion: (id) => _goToQuestion(exam, id)),
              ]),
              if (_notesOpen && !module.isListening)
                Positioned(
                  right: 0,
                  top: 56,
                  bottom: 52,
                  child: NotesDrawer(
                    store: _storeFor(exam),
                    partId: part.id,
                    onClose: () => setState(() => _notesOpen = false),
                  ),
                ),
              if (exam.paused) const _PauseOverlay(),
            ]),
          ),
        );
      },
    );
  }

  Widget _questions(ExamController exam, PartPayload part, ExamPalette palette) {
    final ctx = QuestionContext(
      exam: exam,
      part: part,
      palette: palette,
      keys: _questionKeys,
      images: (src) => _resolveImage(exam, src),
    );
    return Container(
      color: palette.panel,
      child: SingleChildScrollView(
        key: PageStorageKey('q-${part.id}'),
        controller: _questionsScroll,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 60),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final s in part.sections) SectionView(key: ValueKey('s-${s.id}'), section: s, ctx: ctx),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _body(ExamController exam, ExamModule module, PartPayload part, ExamPalette palette) {
    if (module.isListening) {
      return Column(children: [
        if (part.html.trim().isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: PassagePane(
              key: ValueKey('passage-${part.id}'),
              partId: part.id,
              title: part.name,
              html: part.html,
              store: _storeFor(exam),
              palette: palette,
              fontSize: 15,
              imageResolver: (src) => _resolveImage(exam, src),
            ),
          ),
        Expanded(child: _questions(exam, part, palette)),
      ]);
    }
    final left = PassagePane(
      key: ValueKey('passage-${part.id}'),
      partId: part.id,
      title: part.name,
      html: part.html,
      store: _storeFor(exam),
      palette: palette,
      fontSize: 15,
      imageResolver: (src) => _resolveImage(exam, src),
    );
    return LayoutBuilder(builder: (context, c) {
      final leftWidth = c.maxWidth * _split;
      return Row(children: [
        SizedBox(width: leftWidth, child: Container(color: palette.background, child: left)),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (d) => setState(() {
            _split = ((leftWidth + d.delta.dx) / c.maxWidth).clamp(0.25, 0.75);
          }),
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: Container(
              width: 10,
              color: AppColors.border,
              alignment: Alignment.center,
              child: Container(
                width: 18,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.grey),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Icon(Icons.drag_indicator, size: 12),
              ),
            ),
          ),
        ),
        Expanded(child: _questions(exam, part, palette)),
      ]);
    });
  }
}

// ---------------------------------------------------------------------------

class _Header extends ConsumerWidget {
  const _Header({required this.exam, required this.module, required this.onFinish, this.onToggleNotes});

  final ExamController exam;
  final ExamModule module;
  final VoidCallback onFinish;
  final VoidCallback? onToggleNotes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(examViewSettingsProvider);
    final notifier = ref.read(examViewSettingsProvider.notifier);
    final clock = ref.read(serverClockProvider);
    final audioFile = exam.listeningAudioFile;
    Widget pill(String text, VoidCallback onTap, String tip) => Tooltip(
          message: tip,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
        );
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        const IeltsBadge(),
        const SizedBox(width: 12),
        Text(exam.candidateName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const Text('  |  ', style: TextStyle(color: AppColors.border)),
        Text(module.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const Spacer(),
        if (module.isListening && audioFile != null) ...[
          ListeningAudio(
            key: ValueKey('audio-${module.typeId}'),
            file: audioFile,
            module: module,
            clock: clock,
            paused: exam.paused,
          ),
          const SizedBox(width: 12),
        ],
        pill(switch (settings.textSize) {
          TextSizeSetting.standard => 'TEXT: STANDARD',
          TextSizeSetting.large => 'TEXT: LARGE',
          TextSizeSetting.xlarge => 'TEXT: X-LARGE',
        }, notifier.cycleTextSize, 'Change text size'),
        const SizedBox(width: 8),
        pill(switch (settings.contrast) {
          ContrastSetting.standard => 'COLOURS: STANDARD',
          ContrastSetting.yellowBlack => 'COLOURS: YELLOW/BLACK',
          ContrastSetting.blueWhite => 'COLOURS: WHITE/BLUE',
        }, notifier.cycleContrast, 'Change colour contrast'),
        const SizedBox(width: 12),
        TimerDisplay(
          finishedAt: module.finishedAt,
          clock: clock,
          hidden: settings.timerHidden,
          onToggle: notifier.toggleTimer,
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          key: const Key('finish-module'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE11D48),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          onPressed: exam.inputsLocked ? null : onFinish,
          icon: const Icon(Icons.check_circle_outline, size: 16),
          label: const Text('FINISH', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 12),
        ConnectionIndicator(
          connection: ref.read(connectionProvider),
          sync: ref.read(syncServiceProvider),
          compact: true,
        ),
        if (onToggleNotes != null)
          IconButton(
            tooltip: 'Candidate notes',
            onPressed: onToggleNotes,
            icon: const Icon(Icons.edit_note),
          ),
      ]),
    );
  }
}

/// Countdown from the server `finished_at` + clock offset; repaints itself.
class TimerDisplay extends StatefulWidget {
  const TimerDisplay({
    super.key,
    required this.finishedAt,
    required this.clock,
    this.hidden = false,
    this.onToggle,
  });

  final DateTime? finishedAt;
  final ServerClock clock;
  final bool hidden;
  final VoidCallback? onToggle;

  @override
  State<TimerDisplay> createState() => _TimerDisplayState();
}

class _TimerDisplayState extends State<TimerDisplay> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.clock.remaining(widget.finishedAt);
    final low = left <= const Duration(minutes: 3);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Text('TIME LEFT ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.grey)),
        Text(
          widget.hidden ? '--:--:--' : formatHms(left),
          key: const Key('timer'),
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: widget.hidden ? AppColors.grey : (low ? Colors.red : AppColors.ink),
          ),
        ),
        if (widget.onToggle != null)
          InkWell(
            onTap: widget.onToggle,
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Icon(widget.hidden ? Icons.visibility : Icons.visibility_off, size: 16, color: AppColors.grey),
            ),
          ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------

class _Footer extends StatelessWidget {
  const _Footer({required this.exam, required this.module, required this.onQuestion});

  final ExamController exam;
  final ExamModule module;
  final ValueChanged<int> onQuestion;

  @override
  Widget build(BuildContext context) {
    final parts = exam.partsOf(module);
    final index = parts.indexWhere((p) => p.id == exam.currentPartId);
    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        for (final p in parts)
          Expanded(
            child: p.id == exam.currentPartId ? _activePart(p) : _inactivePart(p),
          ),
        _arrow(Icons.arrow_left, index > 0, () => exam.stepPart(-1), const Color(0xFF4B5563), 'Previous part'),
        _arrow(Icons.arrow_right, index >= 0 && index < parts.length - 1, () => exam.stepPart(1), Colors.black,
            'Next part'),
      ]),
    );
  }

  Widget _arrow(IconData icon, bool enabled, VoidCallback onTap, Color color, String tip) => Tooltip(
        message: tip,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Container(
            width: 46,
            height: 52,
            color: enabled ? color : color.withValues(alpha: 0.4),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
      );

  Widget _activePart(PartPayload p) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.blue, width: 3), right: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(children: [
        Text(p.name.toUpperCase(),
            style: const TextStyle(color: AppColors.blue, fontWeight: FontWeight.w900, fontSize: 13)),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final q in p.allQuestions) _numberButton(q),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _numberButton(QuestionPayload q) {
    final answered = exam.answerFor(q.id).isAnswered;
    final flagged = exam.flagged.contains(q.id);
    final active = exam.activeQuestionId == q.id;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        key: Key('nb-${q.id}'),
        onTap: () => onQuestion(q.id),
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(color: active ? AppColors.blue : Colors.transparent),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              numberLabel(q),
              style: TextStyle(
                fontSize: 12,
                fontWeight: answered || active ? FontWeight.bold : FontWeight.normal,
                decoration: answered ? TextDecoration.underline : null,
                color: active ? AppColors.blue : AppColors.ink,
              ),
            ),
          ),
          if (flagged)
            const Positioned(right: -3, top: -4, child: Icon(Icons.star, size: 10, color: AppColors.flag)),
        ]),
      ),
    );
  }

  Widget _inactivePart(PartPayload p) {
    final s = exam.stats([p]);
    return InkWell(
      onTap: () => exam.selectPart(p.id),
      child: Container(
        color: const Color(0xFFF3F4F6),
        alignment: Alignment.center,
        decoration: null,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.grey)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            color: const Color(0xFFE5E7EB),
            child: Text('${s.answered} / ${s.total}', style: const TextStyle(fontSize: 11, color: AppColors.grey)),
          ),
        ]),
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay();

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: Container(
          color: Colors.black.withValues(alpha: 0.75),
          alignment: Alignment.center,
          child: Container(
            padding: const EdgeInsets.all(32),
            color: Colors.white,
            child: const Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.pause_circle_filled, size: 64, color: AppColors.blue),
              SizedBox(height: 12),
              Text('The exam is paused', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text('Please wait for the invigilator. Your time is stopped.'),
            ]),
          ),
        ),
      );
}

/// Early finish confirmation (web: FinishConfirmationModal).
class FinishDialog extends StatelessWidget {
  const FinishDialog({super.key, required this.title, required this.answered, required this.total, required this.isLast});

  final String title;
  final int answered;
  final int total;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final unanswered = (total - answered).clamp(0, total);
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 440,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (total > 0) ...[
            Text('Answered: $answered of $total', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: answered / total, minHeight: 8),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.all(10),
            color: unanswered > 0 ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
            child: Text(
              unanswered > 0
                  ? 'You have $unanswered unanswered question(s). If you finish now you cannot return to this section.'
                  : 'All questions are answered. You cannot return to this section after finishing.',
            ),
          ),
          if (isLast) ...[
            const SizedBox(height: 8),
            const Text('This is the last section. Finishing it ends your exam.',
                style: TextStyle(color: AppColors.grey, fontSize: 12)),
          ],
        ]),
      ),
      actions: [
        TextButton(
          key: const Key('finish-cancel'),
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Continue the test'),
        ),
        FilledButton(
          key: const Key('finish-confirm'),
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE11D48)),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Yes, finish'),
        ),
      ],
    );
  }
}

