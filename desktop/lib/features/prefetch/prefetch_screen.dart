import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../../core/theme/web_tokens.dart';

/// Downloads the whole exam + audio before the Rules screen.
class PrefetchScreen extends ConsumerWidget {
  const PrefetchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exam = ref.watch(examControllerProvider);
    return Scaffold(
      body: CenterCard(
        maxWidth: 560,
        child: ListenableBuilder(
          listenable: exam,
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CardHeading(
                title: 'Welcome, ${exam.candidateName}',
                subtitle: 'Your exam is being prepared on this computer. This takes a moment.',
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: exam.prefetchProgress <= 0 ? null : exam.prefetchProgress,
                  minHeight: 8,
                  color: TW.blue600,
                  backgroundColor: TW.gray200,
                ),
              ),
              const SizedBox(height: 10),
              Text(exam.prefetchProgress <= 0 ? exam.prefetchLabel : '${exam.prefetchLabel}  ${(exam.prefetchProgress * 100).round()}%',
                  style: inter(12, weight: FontWeight.w600, color: TW.gray600)),
            ],
          ),
        ),
      ),
    );
  }
}
