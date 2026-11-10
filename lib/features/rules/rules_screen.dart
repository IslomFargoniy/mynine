import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../../core/theme/web_tokens.dart';
import '../../data/models/exam_models.dart';

const _rules = [
  'The exam has three parts in this order: Listening, Reading and Writing. Speaking takes place separately.',
  'Each part has its own timer. When the time is over, your answers are saved and the next part starts automatically.',
  'In Listening the recording plays once. It cannot be paused, rewound or replayed.',
  'Your answers are saved automatically, even if the internet connection is lost.',
  'Do not leave the exam window or use other programs. Switching windows is recorded and reported.',
  'When you finish, the screen shows "Completed". Results are given at the reception.',
];

/// Layout of the web module-selection card (index.tsx, `!testType` branch):
/// heading, candidate details box, module list and the black "Start ➔" action.
class RulesScreen extends ConsumerWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            Align(
              alignment: Alignment.centerRight,
              child: BlackButton(
                key: const Key('rules-accept'),
                label: current != null && current.isInProgress ? 'Continue' : 'Start',
                onTap: exam.acceptRules,
              ),
            ),
          ],
        ),
      ),
    );
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
