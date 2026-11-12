import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/widgets.dart';
import '../../core/theme/web_tokens.dart';
import '../setup/setup_views.dart';
import 'exam_controller.dart';

/// The exam is locked: the server refused the session's token (the candidate
/// signed in on another PC, or the session expired) or this app version is
/// no longer accepted. Nothing is lost — the answers stay queued on this PC.
///
/// After the invigilator released the session in the admin panel, the
/// candidate's code can be entered here again: the same attempt continues
/// and the queued answers are uploaded with the new token.
class BlockedScreen extends ConsumerStatefulWidget {
  const BlockedScreen({super.key});

  @override
  ConsumerState<BlockedScreen> createState() => _BlockedScreenState();
}

class _BlockedScreenState extends ConsumerState<BlockedScreen> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exam = ref.watch(examControllerProvider);
    final device = ref.watch(deviceRepositoryProvider);
    return Scaffold(
      body: Stack(children: [
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
              final lines = exam.blockMessage.split('\n');
              final canRelogin = exam.blockReason == BlockReason.sessionLost;
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
                if (canRelogin) ...[
                  const SizedBox(height: 28),
                  Text('After the invigilator has released the session, enter the code again:',
                      textAlign: TextAlign.center, style: inter(13, color: TW.gray500)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 280,
                    child: TextField(
                      key: const Key('blocked-code'),
                      controller: _code,
                      enabled: !exam.busy,
                      textAlign: TextAlign.center,
                      // Candidates of attempts made before the 6-digit codes
                      // keep their old codes (e.g. AVGUST17-697100).
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9-]')),
                        LengthLimitingTextInputFormatter(32),
                        const _UpperCaseFormatter(),
                      ],
                      decoration: const InputDecoration(hintText: 'Exam code'),
                      onSubmitted: (_) => exam.login(_code.text),
                    ),
                  ),
                  if (exam.error != null) ...[
                    const SizedBox(height: 8),
                    Text(exam.error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('blocked-relogin'),
                    onPressed: exam.busy ? null : () => exam.login(_code.text),
                    child: const Text('Sign in again'),
                  ),
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

class _UpperCaseFormatter extends TextInputFormatter {
  const _UpperCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
