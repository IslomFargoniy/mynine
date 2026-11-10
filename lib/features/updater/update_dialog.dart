import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../admin/admin_menu.dart';
import 'update_service.dart';

/// "Check for updates" button flow: password (if kiosk locked) → check →
/// dialog with notes → download (progress) → silent install + relaunch.
Future<void> checkForUpdatesInteractive(
  BuildContext context,
  WidgetRef ref, {
  bool passwordChecked = false,
}) async {
  final kiosk = ref.read(kioskControllerProvider);
  if (kiosk.kioskLocked && !passwordChecked) {
    final ok = await askExitPassword(context, ref, reason: 'Enter the center password to update this app.');
    if (!ok || !context.mounted) return;
  }
  final updates = ref.read(updateServiceProvider);
  unawaited(updates.check(manual: true));
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => UpdateDialog(service: updates),
  );
}

class UpdateDialog extends StatelessWidget {
  const UpdateDialog({super.key, required this.service});

  final UpdateService service;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final release = service.release;
        final phase = service.phase;
        final canClose = !(service.mandatory && release != null) &&
            phase != UpdatePhase.downloading &&
            phase != UpdatePhase.installing;
        return AlertDialog(
          title: Text(switch (phase) {
            UpdatePhase.checking => 'Checking for updates…',
            UpdatePhase.upToDate => 'No updates',
            UpdatePhase.available => 'Update available',
            UpdatePhase.downloading => 'Downloading update…',
            UpdatePhase.installing => 'Installing…',
            UpdatePhase.error => 'Update failed',
            UpdatePhase.unsupported => 'Update downloaded',
            UpdatePhase.idle => 'Updates',
          }),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Installed version: ${service.currentVersion}',
                    style: const TextStyle(color: AppColors.grey)),
                const SizedBox(height: 12),
                if (phase == UpdatePhase.checking) const LinearProgressIndicator(),
                if (phase == UpdatePhase.upToDate) const Text('This computer has the latest version.'),
                if (release != null &&
                    (phase == UpdatePhase.available ||
                        phase == UpdatePhase.downloading ||
                        phase == UpdatePhase.installing ||
                        phase == UpdatePhase.unsupported)) ...[
                  Text('New version: ${release.version}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (service.mandatory)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('This update is required.', style: TextStyle(color: Colors.red)),
                    ),
                  if (release.notes.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(release.notes),
                  ],
                ],
                if (phase == UpdatePhase.downloading) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: service.progress == 0 ? null : service.progress),
                  const SizedBox(height: 4),
                  Text('${(service.progress * 100).round()}%'),
                ],
                if (phase == UpdatePhase.installing) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 4),
                  const Text('The app will restart automatically.'),
                ],
                if (service.error != null) ...[
                  const SizedBox(height: 8),
                  Text(service.error!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
          actions: [
            if (canClose)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(phase == UpdatePhase.available ? 'Later' : 'Close'),
              ),
            if (phase == UpdatePhase.error)
              OutlinedButton(onPressed: () => service.check(manual: true), child: const Text('Retry')),
            if (phase == UpdatePhase.available)
              FilledButton(
                onPressed: () async {
                  final file = await service.download();
                  if (file != null) await service.install(file);
                },
                child: const Text('Install now'),
              ),
          ],
        );
      },
    );
  }
}
