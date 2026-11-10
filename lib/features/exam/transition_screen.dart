import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/widgets.dart';

/// Shown between sections (starting a module, submitting, waiting for the network).
class TransitionScreen extends ConsumerWidget {
  const TransitionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exam = ref.watch(examControllerProvider);
    return Scaffold(
      body: Stack(children: [
        CenterCard(
          maxWidth: 560,
          child: ListenableBuilder(
            listenable: exam,
            builder: (context, _) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  exam.transitionMessage ?? 'Please wait…',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 20,
          bottom: 16,
          child: ConnectionIndicator(
            connection: ref.watch(connectionProvider),
            sync: ref.watch(syncServiceProvider),
          ),
        ),
      ]),
    );
  }
}
