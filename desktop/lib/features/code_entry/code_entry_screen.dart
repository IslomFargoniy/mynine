import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../exam/exam_controller.dart';
import '../setup/setup_views.dart';
import '../updater/update_dialog.dart';
import '../updater/update_service.dart';

/// First screen: candidate enters the code from their code card.
/// Also shows the version label and the "Check for updates" button.
///
/// Before that the PC must be set up: without a device token it shows the
/// Setup view (center password), then "Waiting for administrator approval"
/// until an Admin approves it; afterwards the PC number ("PC 7").
class CodeEntryScreen extends ConsumerStatefulWidget {
  const CodeEntryScreen({super.key});

  @override
  ConsumerState<CodeEntryScreen> createState() => _CodeEntryScreenState();
}

class _CodeEntryScreenState extends ConsumerState<CodeEntryScreen> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  bool _mandatoryShown = false;

  @override
  void initState() {
    super.initState();
    final updates = ref.read(updateServiceProvider);
    final exam = ref.read(examControllerProvider);
    updates.canAutoInstall =
        () => exam.stage == ExamStage.idle && !exam.busy && exam.attemptId == null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      updates.reportCodeScreenRendered();
      updates.startPeriodic();
      if (updates.lastCheck == null) unawaited(updates.check());
      ref.read(examViewSettingsProvider.notifier).reset();
    });
    updates.addListener(_onUpdates);
    exam.addListener(_onExam);
  }

  @override
  void dispose() {
    ref.read(updateServiceProvider).removeListener(_onUpdates);
    ref.read(examControllerProvider).removeListener(_onExam);
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onUpdates() {
    final u = ref.read(updateServiceProvider);
    if (u.phase == UpdatePhase.available && u.mandatory && !_mandatoryShown && mounted) {
      _mandatoryShown = true;
      unawaited(
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (_) => UpdateDialog(service: u),
        ),
      );
    }
  }

  void _onExam() {
    final exam = ref.read(examControllerProvider);
    if (exam.updateRequired && mounted) {
      exam.clearError();
      _mandatoryShown = false;
      unawaited(ref.read(updateServiceProvider).check(manual: true).then((_) => _onUpdates()));
    }
  }

  Future<void> _submit() async {
    final exam = ref.read(examControllerProvider);
    await exam.login(_code.text);
    if (mounted && exam.stage == ExamStage.idle) {
      _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final exam = ref.watch(examControllerProvider);
    final config = ref.watch(appConfigProvider);
    final device = ref.watch(deviceRepositoryProvider);
    final connection = ref.watch(connectionProvider);
    final updates = ref.watch(updateServiceProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Background picture chosen by the Admin (Exam PCs → Background).
          Positioned.fill(
            child: ListenableBuilder(
              listenable: device,
              builder: (_, _) {
                final bg = device.backgroundFile;
                if (bg == null) return const SizedBox.shrink();
                return Image.file(
                  bg,
                  key: ValueKey(bg.path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                );
              },
            ),
          ),
          CenterCard(
            maxWidth: 520,
            child: ListenableBuilder(
              listenable: Listenable.merge([exam, device]),
              builder: (context, _) => !device.isRegistered
                  ? SetupView(
                      initialName: null,
                      onRegister: (password, name) =>
                          ref.read(kioskControllerProvider).registerDevice(password: password, name: name),
                    )
                  : device.isApprovalPending
                  ? PendingApprovalView(
                      pcName: device.pcName,
                      machineIdShort: device.machineIdShort,
                      onCheckNow: () => ref.read(kioskControllerProvider).checkApprovalNow(),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const IeltsBadge(),
                            const SizedBox(width: 10),
                            const Text('Mynine', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                            const Spacer(),
                            if (device.pcNumber case final number?) PcNumberBadge(number: number, large: true),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'IELTS Mock Exam',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.ink),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Enter the 6-digit code printed on your candidate card.',
                          style: TextStyle(fontSize: 15, color: AppColors.grey),
                        ),
                        const SizedBox(height: 28),
                        TextField(
                          key: const Key('code-field'),
                          controller: _code,
                          focusNode: _focus,
                          autofocus: true,
                          enabled: !exam.busy,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 30, letterSpacing: 12, fontWeight: FontWeight.w700),
                          // Candidate codes are exactly six digits.
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: const InputDecoration(
                            hintText: '000000',
                            contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                          ),
                          onSubmitted: (_) => _submit(),
                        ),
                        if (exam.error != null && exam.error != device.notApprovedMessage) ...[
                          const SizedBox(height: 12),
                          Text(
                            exam.error!,
                            key: const Key('code-error'),
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ],
                        if (device.isBlocked) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'This computer is blocked. Please ask the reception.',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          key: const Key('code-submit'),
                          onPressed: exam.busy ? null : _submit,
                          child: exam.busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : const Text('START'),
                        ),
                      ],
                    ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 16,
            child: ListenableBuilder(
              listenable: device,
              builder: (context, _) => Row(
                children: [
                  ConnectionIndicator(connection: connection),
                  const SizedBox(width: 16),
                  Text(device.pcName, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                  if (config.apiFake) ...[
                    const SizedBox(width: 16),
                    const Text(
                      'DEMO MODE – center password "mynine", any code starting with DEMO',
                      style: TextStyle(color: Colors.deepOrange, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 12,
            child: ListenableBuilder(
              listenable: updates,
              builder: (context, _) => Row(
                children: [
                  if (updates.phase == UpdatePhase.downloading)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        'Downloading update ${(updates.progress * 100).round()}%',
                        style: const TextStyle(fontSize: 12, color: AppColors.grey),
                      ),
                    ),
                  Text(
                    'Version ${config.appVersion}',
                    key: const Key('version-label'),
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    key: const Key('check-updates'),
                    onPressed: updates.busy ? null : () => checkForUpdatesInteractive(context, ref),
                    icon: const Icon(Icons.system_update_alt, size: 16),
                    label: const Text('Check for updates', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
