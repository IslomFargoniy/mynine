import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/web_tokens.dart';

/// "Completed" — never shows scores. Returns to the code screen after 10 s;
/// queued answers / a pending submit keep syncing in the background.
class CompletedScreen extends ConsumerStatefulWidget {
  const CompletedScreen({super.key});

  @override
  ConsumerState<CompletedScreen> createState() => _CompletedScreenState();
}

class _CompletedScreenState extends ConsumerState<CompletedScreen> {
  Timer? _timer;
  int _left = AppConfig.completedReturnDelay.inSeconds;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left--);
      if (_left <= 0) {
        t.cancel();
        ref.read(examControllerProvider).returnToCodeScreen();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.read(examControllerProvider).candidateName;
    return Scaffold(
      body: CenterCard(
        maxWidth: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 72, color: TW.emerald500),
            const SizedBox(height: 16),
            Text('Completed', style: inter(30, weight: FontWeight.w700, color: TW.gray900, letterSpacing: -0.75)),
            const SizedBox(height: 12),
            Text(
              'Thank you${name.isEmpty ? '' : ', $name'}. Your exam has been submitted.\n'
              'Please leave the room quietly. Your results will be given at the reception.',
              textAlign: TextAlign.center,
              style: inter(16, color: TW.gray600, height: 1.5),
            ),
            const SizedBox(height: 24),
            Text('Returning to the start screen in $_left s', style: inter(12, color: TW.gray500)),
          ],
        ),
      ),
    );
  }
}
