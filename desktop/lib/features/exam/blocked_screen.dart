import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../../core/theme/web_tokens.dart';
import '../setup/setup_views.dart';
import 'exam_controller.dart';

/// The exam is locked. A lost session (token revoked or expired) only shows a spinner while the PC signs in again in
/// the background ([ExamController]); an app version the server no longer accepts shows its message. Nothing is
/// lost — the answers stay queued on this PC.
class BlockedScreen extends ConsumerStatefulWidget {
  const BlockedScreen({super.key});

  @override
  ConsumerState<BlockedScreen> createState() => _BlockedScreenState();
}

class _BlockedScreenState extends ConsumerState<BlockedScreen> {
  @override
  Widget build(BuildContext context) {
    final exam = ref.watch(examControllerProvider);
    final device = ref.watch(deviceRepositoryProvider);
    return Scaffold(
      body: Stack(children: [
        Positioned(
          top: 20,
          right: 20,
          child: ListenableBuilder(
            listenable: device,
            builder: (context, _) => device.pcNumber == null
                ? const SizedBox.shrink()
                : PcNumberCircle(number: device.pcNumber!),
          ),
        ),
        CenterCard(
          maxWidth: 560,
          child: ListenableBuilder(
            listenable: Listenable.merge([exam, device]),
            builder: (context, _) {
              // The PC itself was removed in the admin panel: set it up again
              // here (center password → Admin approval), then the candidate
              // signs in again and the same attempt continues.
              if (!device.isRegistered) {
                return SetupView(
                  initialName: device.pcName,
                  initialCenterCode: device.lastCenterCode,
                  onRegister: (centerCode, password, name) => ref
                      .read(kioskControllerProvider)
                      .registerDevice(centerCode: centerCode, password: password, name: name),
                );
              }
              if (device.isApprovalPending) {
                return PendingApprovalView(
                  centerName: device.centerName,
                  pcName: device.pcName,
                  machineIdShort: device.machineIdShort,
                  onCheckNow: () => ref.read(kioskControllerProvider).checkApprovalNow(),
                );
              }
              // A lost session is restored in the background (or the PC goes back to the code screen): nothing to
              // read for the candidate meanwhile.
              if (exam.blockReason == BlockReason.sessionLost) {
                return const Padding(
                  key: Key('blocked-recovering'),
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final lines = exam.blockMessage.split('\n');
              return Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.lock_outline, size: 64, color: TW.amber500),
                const SizedBox(height: 16),
                Text(lines.first,
                    key: const Key('blocked-message'),
                    textAlign: TextAlign.center,
                    style: inter(22, weight: FontWeight.w700, color: TW.gray900)),
                for (final l in lines.skip(1)) ...[
                  const SizedBox(height: 8),
                  Text(l, textAlign: TextAlign.center, style: inter(14, color: TW.gray600, height: 1.5)),
                ],
                if (exam.candidateName.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('${exam.candidateName} · ${exam.candidateCode}',
                      style: inter(14, weight: FontWeight.w600, color: TW.gray700)),
                ],
              ]);
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
