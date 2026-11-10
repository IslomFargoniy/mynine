import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../../core/theme/web_tokens.dart';

/// Between sections (starting a module, submitting, waiting for the network):
/// the web loading state (black ring + uppercase label) on the grey canvas.
class TransitionScreen extends ConsumerWidget {
  const TransitionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exam = ref.watch(examControllerProvider);
    return Scaffold(
      body: Stack(children: [
        Center(
          child: ListenableBuilder(
            listenable: exam,
            builder: (context, _) {
              final lines = (exam.transitionMessage ?? 'Loading...').split('\n');
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  WebSpinner(label: lines.first),
                  for (final l in lines.skip(1)) ...[
                    const SizedBox(height: 8),
                    Text(l, textAlign: TextAlign.center, style: inter(14, color: TW.gray600)),
                  ],
                ]),
              );
            },
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
