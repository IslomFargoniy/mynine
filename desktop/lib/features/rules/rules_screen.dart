import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../../core/theme/web_tokens.dart';
import '../../data/models/exam_models.dart';
import '../../platform/lockdown/banned_apps_gate.dart';

const _rules = [
  'The exam has three parts in this order: Listening, Reading and Writing. Speaking takes place separately.',
  'Each part has its own timer. When the time is over, your answers are saved; the next part starts when you press Start.',
  'In Listening the recording plays once. It cannot be paused, rewound or replayed.',
  'Your answers are saved automatically, even if the internet connection is lost.',
  'Do not leave the exam window or use other programs. Switching windows is recorded and reported.',
  'When you finish, the screen shows "Completed". Results are given at the reception.',
];

/// Layout of the web module-selection card (index.tsx, `!testType` branch):
/// heading, candidate details box, module list and the black "Start ➔" action.
///
/// "Start" stays disabled while banned programs (browsers, messengers, remote
/// desktop, Task Manager, …) are running; they are listed with a button that
/// closes them.
class RulesScreen extends ConsumerStatefulWidget {
  const RulesScreen({super.key});

  @override
  ConsumerState<RulesScreen> createState() => _RulesScreenState();
}

class _RulesScreenState extends ConsumerState<RulesScreen> {
  late final BannedAppsGate _gate = BannedAppsGate(
    lockdown: ref.read(lockdownProvider),
    bannedProcesses: () => ref.read(deviceRepositoryProvider).config.bannedProcesses,
    autoClose: true,
  );

  @override
  void initState() {
    super.initState();
    _gate.start();
  }

  @override
  void dispose() {
    _gate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exam = ref.watch(examControllerProvider);
    final current = exam.currentModule;
    return Scaffold(
      body: CenterCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CardHeading(
              title: 'IELTS Mock Test',
              subtitle: 'Please confirm your details and read the instructions before you begin.',
            ),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 32),
              decoration: BoxDecoration(
                color: TW.gray50,
                border: Border.all(color: TW.gray200),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Table(
                columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(2)},
                children: [
                  _row('Candidate Name:', exam.candidateName),
                  _row('Candidate Code:', exam.candidateCode),
                ],
              ),
            ),
            Text('Instructions', style: inter(20, weight: FontWeight.w700, color: TW.gray900)),
            const SizedBox(height: 12),
            for (final (i, r) in _rules.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 24, child: Text('${i + 1}.', style: inter(14, weight: FontWeight.w700, color: TW.gray700))),
                  Expanded(child: Text(r, style: inter(14, color: TW.gray700, height: 1.5))),
                ]),
              ),
            const SizedBox(height: 20),
            Text('Modules', style: inter(20, weight: FontWeight.w700, color: TW.gray900)),
            const SizedBox(height: 16),
            for (final m in exam.modules) ...[
              _ModuleRow(module: m, current: current?.typeId == m.typeId),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
            ListenableBuilder(
              listenable: Listenable.merge([_gate, exam]),
              builder: (context, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BannedAppsPanel(gate: _gate),
                  // A module start the server refused (not a connection problem).
                  if (exam.error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(exam.error!,
                          key: const Key('rules-error'),
                          textAlign: TextAlign.right,
                          style: inter(14, weight: FontWeight.w600, color: TW.red700)),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: BlackButton(
                      key: const Key('rules-accept'),
                      label: current == null ? 'Start' : current.isInProgress ? 'Continue' : 'Start ${current.title}',
                      onTap: _gate.canStart ? _start : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _starting = false;

  /// Start / Continue. Programs that could not be closed are recorded as a
  /// violation (the invigilator sees them in the monitor).
  Future<void> _start() async {
    if (_starting) return;
    _starting = true;
    try {
      final exam = ref.read(examControllerProvider);
      if (_gate.overridden) {
        for (final name in _gate.unkillableRunning) {
          await exam.reportViolation(ViolationType.bannedProcess, {
            'process': name,
            'terminated': false,
            'note': 'could_not_close_before_start',
          });
        }
      }
      exam.acceptRules();
    } finally {
      _starting = false;
    }
  }

  TableRow _row(String k, String v) => TableRow(children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(k, style: inter(16, weight: FontWeight.w600, color: TW.gray600)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(v, style: inter(16, weight: FontWeight.w500, color: TW.gray900)),
        ),
      ]);
}

/// Banned programs still running (rules screen). Empty when none.
class BannedAppsPanel extends StatelessWidget {
  const BannedAppsPanel({super.key, required this.gate});

  final BannedAppsGate gate;

  @override
  Widget build(BuildContext context) {
    // With autoClose the programs are closed silently: the panel (which made
    // the page jump) shows only for a program that could not be closed.
    if (!gate.checked || gate.running.isEmpty) return const SizedBox.shrink();
    if (gate.autoClose && !gate.needsAttention) return const SizedBox.shrink();
    return Container(
      key: const Key('banned-apps'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TW.red50,
        border: Border.all(color: TW.red200),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Close these programs before you start',
            style: inter(15, weight: FontWeight.w700, color: TW.red700)),
        const SizedBox(height: 6),
        Text('Other programs are not allowed during the exam.', style: inter(13, color: TW.gray700)),
        const SizedBox(height: 8),
        for (final name in gate.running)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text('•  ${displayProcessName(name)}',
                key: Key('banned-$name'), style: inter(14, weight: FontWeight.w600, color: TW.gray900)),
          ),
        if (gate.notClosed.isNotEmpty || gate.overridden) ...[
          const SizedBox(height: 6),
          Text(
              gate.overridden
                  ? 'Some programs could not be closed. You may start; this is recorded. '
                      'Please tell the invigilator.'
                  : 'Some programs could not be closed. Please ask the invigilator.',
              key: const Key('banned-not-closed'),
              style: inter(13, color: TW.red700)),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('banned-close-all'),
          onPressed: gate.busy ? null : gate.closeAll,
          icon: const Icon(Icons.close, size: 16),
          label: Text(gate.busy ? 'Closing…' : 'Close these programs'),
        ),
      ]),
    );
  }
}

/// `chrome.exe` → `Chrome`; unknown names keep the exe name.
String displayProcessName(String exe) => switch (exe) {
      'chrome.exe' => 'Google Chrome',
      'msedge.exe' => 'Microsoft Edge',
      'firefox.exe' => 'Firefox',
      'opera.exe' => 'Opera',
      'brave.exe' => 'Brave',
      'yandex.exe' || 'browser.exe' => 'Yandex Browser',
      'telegram.exe' => 'Telegram',
      'whatsapp.exe' => 'WhatsApp',
      'discord.exe' => 'Discord',
      'teams.exe' || 'ms-teams.exe' => 'Microsoft Teams',
      'zoom.exe' => 'Zoom',
      'skype.exe' => 'Skype',
      'slack.exe' => 'Slack',
      'anydesk.exe' => 'AnyDesk',
      'teamviewer.exe' => 'TeamViewer',
      'rustdesk.exe' => 'RustDesk',
      'taskmgr.exe' => 'Task Manager',
      'cmd.exe' => 'Command Prompt',
      'powershell.exe' || 'pwsh.exe' => 'PowerShell',
      'windowsterminal.exe' => 'Windows Terminal',
      'notepad.exe' => 'Notepad',
      'winword.exe' => 'Microsoft Word',
      _ => exe,
    };

/// Module row (`p-4 border` button of the web list; here informational).
class _ModuleRow extends StatelessWidget {
  const _ModuleRow({required this.module, required this.current});
  final ExamModule module;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final done = module.isSubmitted;
    return Opacity(
      opacity: done || !current ? 0.6 : 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: done ? TW.gray50 : Colors.white,
          border: Border.all(color: current ? TW.gray400 : TW.gray200),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(module.title, style: inter(18, weight: FontWeight.w700, color: TW.gray900)),
              if (done)
                Text('TEST FINISHED',
                    style: inter(10, weight: FontWeight.w700, color: TW.red500, letterSpacing: 1)),
            ]),
          ),
          Text('${(module.durationSeconds / 60).round()} min', style: inter(14, weight: FontWeight.w600, color: TW.gray500)),
        ]),
      ),
    );
  }
}
