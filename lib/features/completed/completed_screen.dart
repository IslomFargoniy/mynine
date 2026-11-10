import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/config/app_config.dart';

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
            const Icon(Icons.check_circle, size: 72, color: Color(0xFF16A34A)),
            const SizedBox(height: 16),
            const Text('Completed', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'Thank you${name.isEmpty ? '' : ', $name'}. Your exam has been submitted.\n'
              'Please leave the room quietly. Your results will be given at the reception.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.grey),
            ),
            const SizedBox(height: 24),
            Text('Returning to the start screen in $_left s',
                style: const TextStyle(color: AppColors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
