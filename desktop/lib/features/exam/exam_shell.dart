import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart' show PcNumberBadge;
import '../../core/theme/web_tokens.dart';
import '../../core/time/server_clock.dart';
import '../../data/models/exam_models.dart';
import '../../data/models/part_payload.dart';
import '../../data/repositories/sync_service.dart';
import '../passage/passage_pane.dart';
import '../questions/question_widgets.dart';
import 'exam_controller.dart';
import 'listening_audio.dart';

/// The exam room — a reproduction of resources/js/pages/practice/index.tsx:
/// InsperaHeader, the module body (Listening: questions only; Reading and
/// Writing: passage | resizable divider | questions) and the footer with the
/// parts and the question number bar.
class ExamShell extends ConsumerStatefulWidget {
  const ExamShell({super.key});

  @override
  ConsumerState<ExamShell> createState() => _ExamShellState();
}

class _ExamShellState extends ConsumerState<ExamShell> {
  final Map<int, GlobalKey> _questionKeys = {};
  double _split = WebTokens.splitDefault;
  bool _dividerHover = false;
  bool _notesOpen = false;
  HighlightStore? _store;

  @override
  void dispose() {
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
    var path = files[src];
    if (path == null) {
      for (final e in files.entries) {
        if (e.key.endsWith(src)) {
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
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 0.5);
    }
  }

  /// index.tsx handleNextQuestion / handlePrevQuestion (Alt+N / Alt+P).
  void _stepQuestion(ExamController exam, int delta) {
    final qs = exam.currentPart?.allQuestions.toList() ?? const <QuestionPayload>[];
    if (qs.isEmpty) return;
    final i = qs.indexWhere((q) => q.id == exam.activeQuestionId);
    if (i < 0) {
      _goToQuestion(exam, qs.first.id);
    } else if (i + delta >= 0 && i + delta < qs.length) {
      _goToQuestion(exam, qs[i + delta].id);
    } else {
      exam.stepPart(delta);
    }
  }

  Future<void> _confirmFinish(ExamController exam) async {
    final module = exam.currentModule;
    if (module == null) return;
    var answered = 0;
    var total = 0;
    for (final p in exam.currentParts) {
      for (final q in p.allQuestions) {
        total += q.answerCount;
        if (exam.answerFor(q.id).isAnswered) answered += q.answerCount;
      }
    }
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: WebTokens.modalOverlay,
      builder: (_) => FinishConfirmationModal(
        testTypeName: module.title,
        answeredCount: answered,
        totalCount: total,
      ),
    );
    if (ok == true) await exam.confirmFinishModule();
  }

  @override
  Widget build(BuildContext context) {
    final exam = ref.watch(examControllerProvider);
    final settings = ref.watch(examViewSettingsProvider);
    final notifier = ref.read(examViewSettingsProvider.notifier);
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
            const SingleActivator(LogicalKeyboardKey.keyN, alt: true): () => _stepQuestion(exam, 1),
            const SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): () => _stepQuestion(exam, 1),
            const SingleActivator(LogicalKeyboardKey.keyP, alt: true): () => _stepQuestion(exam, -1),
            const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): () => _stepQuestion(exam, -1),
            const SingleActivator(LogicalKeyboardKey.keyF, alt: true): () {
              final id = exam.activeQuestionId ?? part.allQuestions.firstOrNull?.id;
              if (id != null) exam.toggleFlag(id);
            },
            const SingleActivator(LogicalKeyboardKey.keyT, alt: true): notifier.toggleTimer,
          },
          child: Focus(
            autofocus: true,
            child: Scaffold(
              backgroundColor: WebTokens.pageBackground,
              body: Stack(children: [
                Column(children: [
                  InsperaHeader(
                    exam: exam,
                    module: module,
                    onFinish: () => _confirmFinish(exam),
                    onToggleNotes: () => setState(() => _notesOpen = !_notesOpen),
                  ),
                  Expanded(
                    child: MediaQuery(
                      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(settings.textScale)),
                      child: _body(exam, module, part, palette),
                    ),
                  ),
                  ExamFooter(exam: exam, module: module, onQuestion: (id) => _goToQuestion(exam, id)),
                ]),
                if (_notesOpen)
                  Positioned(
                    right: 0,
                    top: WebTokens.drawerInset,
                    bottom: WebTokens.drawerInset,
                    child: NotesDrawer(
                      store: _storeFor(exam),
                      partId: part.id,
                      onClose: () => setState(() => _notesOpen = false),
                    ),
                  ),
                if (exam.paused) const _PauseOverlay(),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _questionsPane(ExamController exam, PartPayload part, ExamPalette palette, {required bool constrained}) {
    final ctx = QuestionContext(
      exam: exam,
      part: part,
      palette: palette,
      keys: _questionKeys,
      images: (src) => _resolveImage(exam, src),
    );
    final column = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final s in part.sections) SectionView(key: ValueKey('s-${s.id}'), section: s, ctx: ctx),
    ]);
    return Container(
      color: palette.panel,
      child: SingleChildScrollView(
        key: PageStorageKey('q-${part.id}'),
        padding: const EdgeInsets.all(WebTokens.panePadding),
        child: constrained
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: WebTokens.questionsMaxWidth),
                  child: column,
                ),
              )
            : column,
      ),
    );
  }

  Widget _body(ExamController exam, ExamModule module, PartPayload part, ExamPalette palette) {
    // Listening: the passage pane is hidden; questions centred (max-w-3xl).
    if (module.isListening) {
      return _questionsPane(exam, part, palette, constrained: true);
    }
    final left = PassagePane(
      key: ValueKey('passage-${part.id}'),
      partId: part.id,
      title: part.name,
      html: part.html,
      store: _storeFor(exam),
      palette: palette,
      onToggleNotes: () => setState(() => _notesOpen = !_notesOpen),
      imageResolver: (src) => _resolveImage(exam, src),
    );
    return LayoutBuilder(builder: (context, c) {
      final available = c.maxWidth - WebTokens.dividerWidth;
      final leftWidth = available * _split;
      return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          width: leftWidth,
          decoration: BoxDecoration(
            color: palette.background,
            border: Border(
              right: BorderSide(
                color: palette.standard ? WebTokens.paneLeftBorder : palette.text,
                width: WebTokens.paneLeftBorderWidth,
              ),
            ),
          ),
          child: left,
        ),
        _Divider(
          hover: _dividerHover,
          onHover: (v) => setState(() => _dividerHover = v),
          onDrag: (dx) => setState(() {
            _split = ((leftWidth + dx) / available).clamp(WebTokens.splitMin, WebTokens.splitMax);
          }),
        ),
        Expanded(child: _questionsPane(exam, part, palette, constrained: !module.isWriting)),
      ]);
    });
  }
}

/// Resizable divider: `w-2.5 bg-gray-300 hover:bg-blue-600 cursor-col-resize`
/// with a white handle showing "⟷".
class _Divider extends StatelessWidget {
  const _Divider({required this.hover, required this.onHover, required this.onDrag});
  final bool hover;
  final ValueChanged<bool> onHover;
  final ValueChanged<double> onDrag;

  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        onEnter: (_) => onHover(true),
        onExit: (_) => onHover(false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (d) => onDrag(d.delta.dx),
          child: Container(
            key: const Key('split-divider'),
            width: WebTokens.dividerWidth,
            color: hover ? WebTokens.dividerHover : WebTokens.dividerBg,
            alignment: Alignment.center,
            child: OverflowBox(
              maxWidth: 20,
              child: Container(
                width: 20,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: WebTokens.dividerHandleBorder),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 2, offset: Offset(0, 1))],
                ),
                child: Text('⟷', style: mono(10, weight: FontWeight.w400, color: TW.gray600)),
              ),
            ),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// Header (inspera-header.tsx)

class InsperaHeader extends ConsumerWidget {
  const InsperaHeader({
    super.key,
    required this.exam,
    required this.module,
    required this.onFinish,
    required this.onToggleNotes,
  });

  final ExamController exam;
  final ExamModule module;
  final VoidCallback onFinish;
  final VoidCallback onToggleNotes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(examViewSettingsProvider);
    final notifier = ref.read(examViewSettingsProvider.notifier);
    final clock = ref.read(serverClockProvider);
    final connection = ref.read(connectionProvider);
    final sync = ref.read(syncServiceProvider);
    final audioFile = exam.listeningAudioFile;
    final wide = MediaQuery.sizeOf(context).width >= 1024; // lg:inline

    return Container(
      height: WebTokens.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: WebTokens.headerPaddingX),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: WebTokens.headerBorder)),
        boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 1, offset: Offset(0, 1))], // shadow-2xs
      ),
      child: Row(children: [
        const _IeltsBadge(),
        const SizedBox(width: 12),
        if (exam.device.pcNumber case final number?) ...[
          PcNumberBadge(number: number),
          const SizedBox(width: 12),
        ],
        Text(exam.candidateName, style: inter(14, weight: FontWeight.w700, color: WebTokens.candidateText)),
        const SizedBox(width: 12),
        Text('|', style: inter(16, weight: FontWeight.w300, color: WebTokens.separator)),
        const SizedBox(width: 12),
        Text(module.title, style: inter(14, weight: FontWeight.w700, color: TW.gray900)),
        if (wide) ...[
          const SizedBox(width: 12),
          Flexible(
            child: Text('Read the text and answer questions.',
                overflow: TextOverflow.ellipsis, style: inter(14, color: WebTokens.hintText)),
          ),
        ],
        const Spacer(),
        if (module.isListening && audioFile != null && !clock.isExpired(module.finishedAt)) ...[
          ListeningAudio(
            key: ValueKey('audio-${module.typeId}'),
            file: audioFile,
            module: module,
            clock: clock,
            paused: exam.paused,
          ),
          const SizedBox(width: 4),
        ],
        _HeaderPill(
          key: const Key('text-size'),
          label: switch (settings.textSize) {
            TextSizeSetting.standard => 'Standard',
            TextSizeSetting.large => 'Large',
            TextSizeSetting.xlarge => 'Extra Large',
          },
          tooltip: 'Change Text Size (Standard / Large / Extra-Large)',
          onTap: notifier.cycleTextSize,
        ),
        const SizedBox(width: 10),
        _HeaderPill(
          key: const Key('contrast'),
          label: switch (settings.contrast) {
            ContrastSetting.standard => 'Standard',
            ContrastSetting.yellowBlack => 'Yellow / Black',
            ContrastSetting.blueWhite => 'Blue / White',
          },
          tooltip: 'Change Color Contrast Scheme',
          onTap: notifier.cycleContrast,
        ),
        const SizedBox(width: 10),
        TimerDisplay(
          finishedAt: module.finishedAt,
          clock: clock,
          hidden: settings.timerHidden,
          onToggle: notifier.toggleTimer,
        ),
        const SizedBox(width: 10),
        _FinishButton(onTap: exam.inputsLocked ? null : onFinish),
        const SizedBox(width: 10),
        Text('|', style: inter(14, weight: FontWeight.w300, color: WebTokens.separator)),
        const SizedBox(width: 10),
        _SyncButton(connection: connection, sync: sync),
        const SizedBox(width: 6),
        _IconBtn(
          icon: LucideIcons.keyboard,
          tooltip: 'Keyboard shortcuts',
          onTap: () => showHeaderModal(context, (_) => const _ShortcutsModal()),
        ),
        const SizedBox(width: 6),
        _IconBtn(
          icon: LucideIcons.bell,
          tooltip: 'Notifications',
          onTap: () => showHeaderModal(context, (_) => const _BellModal()),
        ),
        const SizedBox(width: 6),
        _IconBtn(
          icon: LucideIcons.menu,
          tooltip: 'System Options & Settings',
          onTap: () => showHeaderModal(context, (_) => const _SettingsModal()),
        ),
        const SizedBox(width: 6),
        _IconBtn(
          key: const Key('notes-toggle'),
          icon: LucideIcons.edit3,
          tooltip: 'Toggle Candidate Notes',
          onTap: onToggleNotes,
        ),
      ]),
    );
  }
}

class _IeltsBadge extends StatelessWidget {
  const _IeltsBadge();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: const BoxDecoration(color: WebTokens.ieltsBadge, borderRadius: WebTokens.r2),
        child: Text('IELTS',
            style: inter(14, weight: FontWeight.w800, color: Colors.white, height: 1, letterSpacing: -0.35)),
      );
}

class _HeaderPill extends StatefulWidget {
  const _HeaderPill({super.key, required this.label, required this.tooltip, required this.onTap});
  final String label;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_HeaderPill> createState() => _HeaderPillState();
}

class _HeaderPillState extends State<_HeaderPill> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: widget.tooltip,
        waitDuration: const Duration(milliseconds: 600),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _hover ? WebTokens.pillHover : WebTokens.pillBg,
                border: Border.all(color: WebTokens.pillBorder),
                borderRadius: WebTokens.r2,
              ),
              child: Text(widget.label.toUpperCase(),
                  style: inter(12, weight: FontWeight.w700, color: WebTokens.pillText)),
            ),
          ),
        ),
      );
}

class _FinishButton extends StatefulWidget {
  const _FinishButton({required this.onTap});
  final VoidCallback? onTap;

  @override
  State<_FinishButton> createState() => _FinishButtonState();
}

class _FinishButtonState extends State<_FinishButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        cursor: widget.onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          key: const Key('finish-module'),
          onTap: widget.onTap,
          child: Opacity(
            opacity: widget.onTap == null ? 0.5 : 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _hover ? WebTokens.finishHover : WebTokens.finishBg,
                borderRadius: WebTokens.r2,
                boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 2, offset: Offset(0, 1))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(LucideIcons.circleCheckBig, size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text('FINISH', style: inter(12, weight: FontWeight.w700, color: Colors.white, letterSpacing: 0.6)),
              ]),
            ),
          ),
        ),
      );
}

class _IconBtn extends StatefulWidget {
  const _IconBtn({super.key, required this.icon, required this.tooltip, required this.onTap, this.color});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: widget.tooltip,
        waitDuration: const Duration(milliseconds: 600),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _hover ? TW.gray100 : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(widget.icon, size: 16, color: widget.color ?? (_hover ? TW.black : WebTokens.systemIcon)),
            ),
          ),
        ),
      );
}

class _SyncButton extends StatelessWidget {
  const _SyncButton({required this.connection, required this.sync});
  final ConnectionStatus connection;
  final SyncService sync;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([connection, sync]),
        builder: (context, _) {
          final offline = !connection.online;
          final syncing = !offline && sync.pendingAnswers > 0;
          return _IconBtn(
            key: const Key('sync-status'),
            icon: offline ? LucideIcons.wifiOff : (syncing ? LucideIcons.loaderCircle : LucideIcons.wifi),
            color: offline ? WebTokens.syncOffline : (syncing ? WebTokens.syncBusy : WebTokens.syncOnline),
            tooltip: offline
                ? 'Offline — answers are kept on this computer'
                : syncing
                    ? 'Syncing (${sync.pendingAnswers})...'
                    : 'Online — connection is stable',
            onTap: () => showHeaderModal(context, (_) => _WifiModal(connection: connection, sync: sync)),
          );
        },
      );
}

/// Countdown (countdown-timer.tsx inside the header timer box).
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

class _TimerDisplayState extends State<TimerDisplay> with SingleTickerProviderStateMixin {
  Timer? _t;
  late final AnimationController _pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));

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
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.clock.remaining(widget.finishedAt);
    final low = left <= WebTokens.lowTimeThreshold;
    if (low && !widget.hidden && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if ((!low || widget.hidden) && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
    final value = widget.hidden
        ? Text('--:--:--', key: const Key('timer'), style: mono(14, color: WebTokens.timerHidden))
        : AnimatedBuilder(
            animation: _pulse,
            builder: (context, child) {
              // Tailwind animate-pulse: opacity 1 → .5 → 1 over 2 s.
              final t = _pulse.value;
              final o = low ? (t < 0.5 ? 1 - t : t) : 1.0;
              return Opacity(opacity: o, child: child);
            },
            child: Text(formatHms(left),
                key: const Key('timer'), style: mono(14, color: low ? WebTokens.timerLow : WebTokens.timerValue)),
          );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: WebTokens.timerBg,
        border: Border.all(color: WebTokens.timerBorder),
        borderRadius: WebTokens.r2,
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('TIME REMAINING:', style: inter(12, weight: FontWeight.w700, color: WebTokens.timerLabel)),
        const SizedBox(width: 6),
        value,
        if (widget.onToggle != null)
          Tooltip(
            message: widget.hidden ? 'Show timer' : 'Hide timer',
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                key: const Key('timer-toggle'),
                onTap: widget.onToggle,
                child: Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Icon(widget.hidden ? LucideIcons.eye : LucideIcons.eyeOff, size: 16, color: TW.gray400),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Header modals (inspera-header.tsx activeModal: wifi / shortcuts / bell / menu)

Future<void> showHeaderModal(BuildContext context, Widget Function(BuildContext) body) => showDialog<void>(
      context: context,
      barrierColor: const Color(0x66000000), // bg-black/40
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: TW.gray200)),
        child: SizedBox(
          width: WebTokens.modalMaxWidth,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Stack(children: [
              Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                body(ctx),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(color: TW.black, borderRadius: BorderRadius.circular(4)),
                      child: Text('Cancel', style: inter(12, weight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ),
              ]),
              Positioned(
                right: 0,
                top: 0,
                child: InkWell(
                  onTap: () => Navigator.pop(ctx),
                  child: const Icon(LucideIcons.x, size: 20, color: TW.gray400),
                ),
              ),
            ]),
          ),
        ),
      ),
    );

Widget _modalTitle(IconData icon, Color color, String title) => Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 24),
      child: Row(children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: inter(18, weight: FontWeight.w700, color: TW.gray900))),
      ]),
    );

Widget _modalRow(String label, Widget value) => Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: TW.gray100))),
      child: Row(children: [
        Expanded(child: Text(label, style: inter(14, weight: FontWeight.w600, color: TW.gray700))),
        value,
      ]),
    );

class _WifiModal extends StatelessWidget {
  const _WifiModal({required this.connection, required this.sync});
  final ConnectionStatus connection;
  final SyncService sync;

  @override
  Widget build(BuildContext context) {
    final online = connection.online;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _modalTitle(online ? LucideIcons.circleCheckBig : LucideIcons.wifiOff, online ? TW.emerald600 : TW.red500,
          'Network & Sync Status'),
      _modalRow(
          'Status:',
          Text(online ? 'Online (Stable)' : 'Offline (Disconnected)',
              style: inter(14, weight: FontWeight.w700, color: online ? TW.emerald600 : TW.red600))),
      _modalRow('Pending Answers:',
          Text('${sync.pendingAnswers}', style: inter(14, weight: FontWeight.w700, color: TW.gray900))),
      _modalRow('Offline Protection:', Text('Active', style: inter(14, weight: FontWeight.w600, color: TW.emerald600))),
      if (!online)
        Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: TW.amber50,
            border: Border.all(color: TW.amber200),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Your answers are not lost when the internet is down. They are sent automatically when the connection returns.',
            style: inter(12, color: TW.amber700),
          ),
        ),
    ]);
  }
}

class _ShortcutsModal extends StatelessWidget {
  const _ShortcutsModal();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Alt + N / →', 'Navigate to next question'),
      ('Alt + P / ←', 'Navigate to previous question'),
      ('Alt + F', 'Flag question for review'),
      ('Alt + T', 'Toggle timer display'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _modalTitle(LucideIcons.keyboard, TW.indigo600, 'Keyboard shortcuts'),
      for (final (key, label) in items)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: TW.gray50,
            border: Border.all(color: TW.gray100),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(children: [
            Expanded(child: Text(label, style: inter(12, weight: FontWeight.w500, color: TW.gray700))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: TW.gray300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(key, style: mono(12, color: TW.gray900)),
            ),
          ]),
        ),
    ]);
  }
}

class _BellModal extends StatelessWidget {
  const _BellModal();

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _modalTitle(LucideIcons.bell, TW.blue600, 'Test Notifications'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: TW.blue50,
            border: Border.all(color: TW.blue200),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text.rich(TextSpan(style: inter(12, color: TW.blue900), children: [
            TextSpan(text: 'Official Notice: ', style: inter(12, weight: FontWeight.w700, color: TW.blue900)),
            const TextSpan(text: 'Your answers are automatically saved as you navigate through questions.'),
          ])),
        ),
      ]);
}

class _SettingsModal extends ConsumerWidget {
  const _SettingsModal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(examViewSettingsProvider);
    final n = ref.read(examViewSettingsProvider.notifier);
    Widget choice(String label, bool active, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: active ? TW.black : Colors.white,
                border: Border.all(color: active ? TW.black : TW.gray300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(label, style: inter(12, weight: FontWeight.w600, color: active ? Colors.white : TW.gray700)),
            ),
          ),
        );
    Widget box(String title, List<Widget> children) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: TW.gray50,
            border: Border.all(color: TW.gray200),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title.toUpperCase(), style: inter(12, weight: FontWeight.w700, color: TW.gray700)),
            const SizedBox(height: 4),
            Row(children: children),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _modalTitle(LucideIcons.settings, TW.gray800, 'Test Options & Settings'),
      box('Text Size', [
        choice('Standard', s.textSize == TextSizeSetting.standard, () => n.setTextSize(TextSizeSetting.standard)),
        choice('Large', s.textSize == TextSizeSetting.large, () => n.setTextSize(TextSizeSetting.large)),
        choice('Extra Large', s.textSize == TextSizeSetting.xlarge, () => n.setTextSize(TextSizeSetting.xlarge)),
      ]),
      box('Color Contrast', [
        choice('Standard', s.contrast == ContrastSetting.standard, () => n.setContrast(ContrastSetting.standard)),
        choice('Yellow / Black', s.contrast == ContrastSetting.yellowBlack,
            () => n.setContrast(ContrastSetting.yellowBlack)),
        choice('Blue / White', s.contrast == ContrastSetting.blueWhite, () => n.setContrast(ContrastSetting.blueWhite)),
      ]),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TW.gray50,
          border: Border.all(color: TW.gray200),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(children: [
          Expanded(
            child: Text((s.timerHidden ? 'Show Timer' : 'Hide Timer').toUpperCase(),
                style: inter(12, weight: FontWeight.w700, color: TW.gray700)),
          ),
          choice(s.timerHidden ? 'Show Timer' : 'Hide Timer', false, n.toggleTimer),
        ]),
      ),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Footer (index.tsx bottom bar + practice-number-bar.tsx)

class ExamFooter extends StatelessWidget {
  const ExamFooter({super.key, required this.exam, required this.module, required this.onQuestion});

  final ExamController exam;
  final ExamModule module;
  final ValueChanged<int> onQuestion;

  @override
  Widget build(BuildContext context) {
    final parts = exam.partsOf(module);
    final index = parts.indexWhere((p) => p.id == exam.currentPartId);
    return Container(
      height: WebTokens.footerHeight,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: WebTokens.footerBorder)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (final p in parts)
              Expanded(child: p.id == exam.currentPartId ? _activePart(p) : _InactivePart(exam: exam, part: p)),
          ]),
        ),
        _Arrow(
          key: const Key('prev-part'),
          glyph: '◄',
          color: WebTokens.arrowPrev,
          enabled: index > 0,
          tooltip: 'Previous Part',
          border: true,
          onTap: () => exam.stepPart(-1),
        ),
        _Arrow(
          key: const Key('next-part'),
          glyph: '►',
          color: WebTokens.arrowNext,
          enabled: index >= 0 && index < parts.length - 1,
          tooltip: 'Next Part',
          onTap: () => exam.stepPart(1),
        ),
      ]),
    );
  }

  Widget _activePart(PartPayload p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: WebTokens.activePartAccent, width: 3),
          right: BorderSide(color: TW.gray300),
        ),
      ),
      child: Row(children: [
        Text(p.name.toUpperCase(),
            style: inter(14, weight: FontWeight.w800, color: WebTokens.activePartAccent, letterSpacing: -0.35)),
        const SizedBox(width: 8),
        Expanded(
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(scrollbars: false), // hide-scrollbar
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  for (final (i, q) in p.allQuestions.indexed) ...[
                    if (i > 0) const SizedBox(width: 8), // gap-2
                    NumberBarButton(
                      question: q,
                      answered: exam.answerFor(q.id).isAnswered,
                      flagged: exam.flagged.contains(q.id),
                      active: exam.activeQuestionId == q.id,
                      onTap: () => onQuestion(q.id),
                    ),
                  ],
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Number bar button: current / answered / flagged / unanswered states.
class NumberBarButton extends StatelessWidget {
  const NumberBarButton({
    super.key,
    required this.question,
    required this.answered,
    required this.flagged,
    required this.active,
    required this.onTap,
  });

  final QuestionPayload question;
  final bool answered;
  final bool flagged;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = active
        ? inter(12, weight: FontWeight.w700, color: WebTokens.numberCurrent)
        : answered
            ? inter(12, weight: FontWeight.w700, color: TW.black, decoration: TextDecoration.underline)
            : inter(12, color: WebTokens.numberUnanswered);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: Key('nb-${question.id}'),
        onTap: onTap,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), // px-1.5 py-0.5
            decoration: BoxDecoration(
              color: active ? WebTokens.numberCurrentBg : Colors.transparent,
              border: Border.all(color: active ? WebTokens.numberCurrent : Colors.transparent),
              borderRadius: WebTokens.r2,
            ),
            child: Text(numberLabel(question), style: style),
          ),
          if (flagged)
            Positioned(
              right: -4,
              top: -4,
              child: Text('★', style: inter(9, weight: FontWeight.w800, color: WebTokens.numberFlag, height: 1)),
            ),
        ]),
      ),
    );
  }
}

class _InactivePart extends StatefulWidget {
  const _InactivePart({required this.exam, required this.part});
  final ExamController exam;
  final PartPayload part;

  @override
  State<_InactivePart> createState() => _InactivePartState();
}

class _InactivePartState extends State<_InactivePart> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final qs = widget.part.allQuestions.toList();
    final answered = qs.where((q) => widget.exam.answerFor(q.id).isAnswered).length;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        key: Key('part-${widget.part.id}'),
        onTap: () => widget.exam.selectPart(widget.part.id),
        child: Container(
          decoration: BoxDecoration(
            color: _hover ? const Color(0xCCE5E7EB) : WebTokens.inactivePartBg,
            border: const Border(
              right: BorderSide(color: TW.gray300),
              top: BorderSide(color: Colors.transparent, width: 3),
            ),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(widget.part.name,
                style: inter(14, weight: FontWeight.w700, color: _hover ? TW.gray900 : WebTokens.inactivePartName)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: const BoxDecoration(color: WebTokens.inactivePartCountBg, borderRadius: WebTokens.r2),
              child: Text('$answered of ${qs.length}',
                  style: inter(12, weight: FontWeight.w600, color: _hover ? TW.gray600 : WebTokens.inactivePartCount)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  const _Arrow({
    super.key,
    required this.glyph,
    required this.color,
    required this.enabled,
    required this.tooltip,
    required this.onTap,
    this.border = false,
  });

  final String glyph;
  final Color color;
  final bool enabled;
  final String tooltip;
  final VoidCallback onTap;
  final bool border;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
          child: GestureDetector(
            onTap: enabled ? onTap : null,
            child: Opacity(
              opacity: enabled ? 1 : 0.4,
              child: Container(
                width: WebTokens.arrowWidth,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  border: border ? const Border(right: BorderSide(color: TW.gray700)) : null,
                ),
                child: Text(glyph, style: inter(16, weight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ),
        ),
      );
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay();

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: Container(
          color: WebTokens.modalOverlay,
          alignment: Alignment.center,
          child: Container(
            width: WebTokens.modalMaxWidth,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(LucideIcons.pause, size: 40, color: TW.blue600),
              const SizedBox(height: 12),
              Text('The exam is paused', style: inter(18, weight: FontWeight.w700, color: TW.gray900)),
              const SizedBox(height: 8),
              Text('Please wait for the invigilator. Your time is stopped.',
                  textAlign: TextAlign.center, style: inter(12, color: TW.gray600)),
            ]),
          ),
        ),
      );
}

// ---------------------------------------------------------------------------
// finish-confirmation-modal.tsx

class FinishConfirmationModal extends StatelessWidget {
  const FinishConfirmationModal({
    super.key,
    required this.testTypeName,
    required this.answeredCount,
    required this.totalCount,
  });

  final String testTypeName;
  final int answeredCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final total = totalCount;
    final answered = answeredCount;
    final unanswered = (total - answered).clamp(0, total);
    final hasUnanswered = total > 0 && unanswered > 0;
    final percent = total > 0 ? (answered / total * 100).round() : 0;

    Widget tile(String label, int value, Color bg, Color border, Color labelColor, Color valueColor) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(children: [
              Text(label.toUpperCase(),
                  style: inter(10, weight: FontWeight.w600, color: labelColor, letterSpacing: 0.5)),
              Text('$value', style: inter(16, weight: FontWeight.w700, color: valueColor)),
            ]),
          ),
        );

    return Dialog(
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: TW.gray200)),
      child: SizedBox(
        width: WebTokens.modalMaxWidth,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0x80F9FAFB),
              border: Border(bottom: BorderSide(color: TW.gray100)),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasUnanswered ? TW.amber100 : TW.emerald100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(hasUnanswered ? LucideIcons.triangleAlert : LucideIcons.circleCheckBig,
                    size: 20, color: hasUnanswered ? TW.amber600 : TW.emerald600),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Finish $testTypeName', style: inter(16, weight: FontWeight.w700, color: TW.gray900, height: 1.25)),
                  Text('Confirm early submission of this section', style: inter(12, color: TW.gray500)),
                ]),
              ),
              InkWell(
                onTap: () => Navigator.pop(context, false),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(LucideIcons.x, size: 20, color: TW.gray400),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (total > 0) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TW.gray50,
                    border: Border.all(color: const Color(0xCCE5E7EB)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [
                      Expanded(child: Text('Test Progress', style: inter(12, weight: FontWeight.w600, color: TW.gray600))),
                      Text('$percent%', style: mono(12, color: TW.gray900)),
                    ]),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: SizedBox(
                        height: 8,
                        child: Stack(children: [
                          Container(color: TW.gray200),
                          FractionallySizedBox(
                            widthFactor: percent / 100,
                            child: Container(color: hasUnanswered ? TW.amber500 : TW.emerald500),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      tile('Total Questions', total, Colors.white, TW.gray200, TW.gray500, TW.gray800),
                      const SizedBox(width: 8),
                      tile('Answered', answered, TW.emerald50, TW.emerald200, TW.emerald600, TW.emerald700),
                      const SizedBox(width: 8),
                      tile(
                          'Unanswered',
                          unanswered,
                          hasUnanswered ? TW.amber50 : TW.gray50,
                          hasUnanswered ? TW.amber200 : TW.gray200,
                          hasUnanswered ? TW.amber600 : TW.gray500,
                          hasUnanswered ? TW.amber700 : TW.gray700),
                    ]),
                  ]),
                ),
                const SizedBox(height: 16),
              ],
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: hasUnanswered ? TW.amber50 : TW.emerald50,
                  border: Border.all(color: hasUnanswered ? TW.amber200 : TW.emerald200),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(hasUnanswered ? LucideIcons.triangleAlert : LucideIcons.circleCheckBig,
                        size: 20, color: hasUnanswered ? TW.amber600 : TW.emerald600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: hasUnanswered
                        ? Text.rich(TextSpan(style: inter(12, color: TW.amber900, height: 1.625), children: [
                            TextSpan(text: 'Attention!: ', style: inter(12, weight: FontWeight.w700, color: TW.amber900)),
                            TextSpan(
                                text: 'You have $unanswered unanswered question(s). If you submit early, '
                                    'unanswered questions will receive zero marks.'),
                          ]))
                        : Text('Great job! You have answered all questions. Click below to submit.',
                            style: inter(12, color: TW.emerald900, height: 1.625)),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              Text('* Once submitted, your responses will be saved and you cannot return to this section.',
                  style: inter(11, color: TW.gray500, style: FontStyle.italic)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xCCF9FAFB),
              border: Border(top: BorderSide(color: TW.gray100)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              InkWell(
                key: const Key('finish-cancel'),
                onTap: () => Navigator.pop(context, false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: TW.gray300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Continue Test', style: inter(12, weight: FontWeight.w600, color: TW.gray700)),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                key: const Key('finish-confirm'),
                onTap: () => Navigator.pop(context, true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: TW.rose600,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Color(0x1A000000), blurRadius: 3, offset: Offset(0, 1))],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Yes, Finish', style: inter(12, weight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(width: 6),
                    const Icon(LucideIcons.arrowRight, size: 16, color: Colors.white),
                  ]),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
