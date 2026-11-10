import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome, ${exam.candidateName}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Your exam is being prepared on this computer. This takes a moment.',
                  style: TextStyle(color: AppColors.grey)),
              const SizedBox(height: 28),
              LinearProgressIndicator(
                value: exam.prefetchProgress <= 0 ? null : exam.prefetchProgress,
                minHeight: 8,
              ),
              const SizedBox(height: 10),
              Text('${exam.prefetchLabel}  ${(exam.prefetchProgress * 100).round()}%',
                  style: const TextStyle(color: AppColors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
