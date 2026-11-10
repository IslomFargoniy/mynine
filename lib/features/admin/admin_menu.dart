import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../updater/update_dialog.dart';

/// Asks for the center exit password (verified online, or offline against
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
      title: const Text('Staff password'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.reason ?? 'Enter the center exit password to continue.'),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              obscureText: true,
              enabled: !_checking,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(labelText: 'Password', errorText: _error),
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
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: TextField(controller: _name, decoration: const InputDecoration(labelText: 'PC name (e.g. PC-07)')),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _saving
                    ? null
                    : () => _run(
                          () => device.setPcName(_name.text, reRegister: true),
                          'PC name saved. The PC registered again and needs admin approval.',
                        ),
                child: const Text('Save'),
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
              'Saving the name, changing the server or re-registering rotates the device token '
              'and requires a new approval by an Admin.',
              style: TextStyle(fontSize: 12, color: AppColors.grey),
            ),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.app_registration),
                onPressed: _saving
                    ? null
                    : () => _run(() => device.register(force: true),
                        'Device registered. An Admin must approve this PC again.'),
                label: const Text('Re-register device'),
              ),
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
