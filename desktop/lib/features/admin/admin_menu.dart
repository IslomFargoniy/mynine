import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../exam/exam_controller.dart';
import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../setup/setup_views.dart' show setupErrorMessage;
import '../updater/update_dialog.dart';

/// Asks for the center password (verified online, or offline against
/// the cached PBKDF2 hash). Returns true when correct.
Future<bool> askExitPassword(BuildContext context, WidgetRef ref, {String? reason}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PasswordDialog(reason: reason),
  );
  return ok ?? false;
}

class _PasswordDialog extends ConsumerStatefulWidget {
  const _PasswordDialog({this.reason});
  final String? reason;

  @override
  ConsumerState<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends ConsumerState<_PasswordDialog> {
  final _controller = TextEditingController();
  bool _checking = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    final ok = await ref.read(deviceRepositoryProvider).verifyExitPassword(_controller.text);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _checking = false;
        _error = 'Incorrect password.';
        _controller.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Center password'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.reason ?? 'Enter the center password to continue.'),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              obscureText: true,
              enabled: !_checking,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(labelText: 'Center password', errorText: _error),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _checking ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _checking ? null : _submit,
          child: _checking
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Continue'),
        ),
      ],
    );
  }
}

/// Hidden admin menu (Ctrl+Shift+M): PC name, server URL, updates, exit.
Future<void> showAdminMenu(BuildContext context, WidgetRef ref) async {
  if (!await askExitPassword(context, ref)) return;
  if (!context.mounted) return;
  await showDialog<void>(context: context, builder: (_) => const _AdminMenuDialog());
}

class _AdminMenuDialog extends ConsumerStatefulWidget {
  const _AdminMenuDialog();

  @override
  ConsumerState<_AdminMenuDialog> createState() => _AdminMenuDialogState();
}

class _AdminMenuDialogState extends ConsumerState<_AdminMenuDialog> {
  late final TextEditingController _name;
  late final TextEditingController _url;
  final _centerPassword = TextEditingController();
  String? _message;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: ref.read(deviceRepositoryProvider).pcName);
    _url = TextEditingController(text: ref.read(kioskControllerProvider).serverUrl.value);
  }

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _centerPassword.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await action();
      _message = done;
    } on ApiException catch (e) {
      _message = 'Failed: ${setupErrorMessage(e)}';
    } catch (e) {
      _message = 'Failed: $e';
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final device = ref.read(deviceRepositoryProvider);
    final kiosk = ref.read(kioskControllerProvider);
    final config = ref.read(appConfigProvider);
    final exam = ref.read(examControllerProvider);
    return AlertDialog(
      title: const Text('Administration'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('App version ${config.appVersion}${config.apiFake ? ' (demo mode)' : ''}',
                style: const TextStyle(color: AppColors.grey)),
            Text('Machine ID: ${device.machineId ?? '-'}',
                style: const TextStyle(color: AppColors.grey, fontSize: 12)),
            Text(
              device.pcNumber != null ? 'PC number: ${device.pcNumber} (${device.pcName})' : 'PC name: ${device.pcName}',
              style: const TextStyle(color: AppColors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Text('Re-register this PC', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(
                child: TextField(
                  key: const Key('admin-pc-name'),
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'PC name (e.g. PC-07)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  key: const Key('admin-center-password'),
                  controller: _centerPassword,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Center password'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                key: const Key('admin-reregister'),
                icon: const Icon(Icons.app_registration),
                onPressed: _saving
                    ? null
                    : () {
                        if (_centerPassword.text.isEmpty) {
                          setState(() => _message = 'Enter the center password to re-register.');
                          return;
                        }
                        final password = _centerPassword.text;
                        _centerPassword.clear();
                        _run(
                          () => kiosk.registerDevice(password: password, name: _name.text),
                          'Device registered. An Admin must approve this PC again (its number is kept).',
                        );
                      },
                label: const Text('Re-register'),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(controller: _url, decoration: const InputDecoration(labelText: 'Server API URL')),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _saving ? null : () => _run(() => kiosk.setServerUrl(_url.text), 'Server URL saved.'),
                child: const Text('Save'),
              ),
            ]),
            const Text(
              'Re-registering or changing the server rotates the device token and requires a new approval '
              'by an Admin. A new server asks for its center password on the Setup screen.',
              style: TextStyle(fontSize: 12, color: AppColors.grey),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.system_update),
                onPressed: _saving || exam.examActive
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        unawaited(checkForUpdatesInteractive(context, ref, passwordChecked: true));
                      },
                label: const Text('Check for updates'),
              ),
              if (exam.stage == ExamStage.blocked || (exam.stage == ExamStage.completed && !exam.submitConfirmed))
                OutlinedButton.icon(
                  key: const Key('admin-return-start'),
                  icon: const Icon(Icons.home_outlined),
                  onPressed: () {
                    Navigator.of(context).pop();
                    exam.returnToCodeScreen();
                  },
                  // The answers stay queued on this PC and keep syncing.
                  label: const Text('Return to start screen'),
                ),
            ]),
            if (exam.examActive) ...[
              const SizedBox(height: 12),
              const Text(
                'An exam is running on this PC. Exiting now leaves the candidate\'s answers on this computer; '
                'they are sent when the candidate logs in again.',
                style: TextStyle(color: Colors.red),
              ),
            ],
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: () => kiosk.exitApp(),
          child: const Text('Exit application'),
        ),
        FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
      ],
    );
  }
}
