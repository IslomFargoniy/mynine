import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';

const _rules = [
  'The exam has three parts in this order: Listening, Reading and Writing. Speaking takes place separately.',
  'Each part has its own timer. When the time is over, your answers are saved and the next part starts automatically.',
  'In Listening the recording plays once. It cannot be paused, rewound or replayed.',
  'Your answers are saved automatically, even if the internet connection is lost.',
  'Do not leave the exam window or use other programs. Switching windows is recorded and reported.',
  'Phones, notes and other devices are not allowed. Raise your hand if you need help.',
  'When you finish, the screen shows "Completed". Results are given at the reception.',
];

class RulesScreen extends ConsumerWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exam = ref.watch(examControllerProvider);
    return Scaffold(
      body: CenterCard(
        maxWidth: 820,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [IeltsBadge(), SizedBox(width: 12), Text('Instructions to candidates',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))]),
            const Divider(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.panel,
              child: Table(
                columnWidths: const {0: IntrinsicColumnWidth()},
                children: [
                  _row('Candidate', exam.candidateName),
                  _row('Code', exam.candidateCode),
                  _row('Sections', exam.modules
                      .map((m) => '${m.title} (${(m.durationSeconds / 60).round()} min)')
                      .join('  ·  ')),
                ],
              ),
            ),
            const SizedBox(height: 20),
            for (final (i, r) in _rules.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 28, child: Text('${i + 1}.', style: const TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text(r, style: const TextStyle(fontSize: 15, height: 1.4))),
                ]),
              ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                key: const Key('rules-accept'),
                onPressed: exam.acceptRules,
                child: const Text('I UNDERSTAND – CONTINUE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TableRow _row(String k, String v) => TableRow(children: [
        Padding(
          padding: const EdgeInsets.only(right: 24, bottom: 6),
          child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.grey)),
        ),
        Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(v)),
      ]);
}
