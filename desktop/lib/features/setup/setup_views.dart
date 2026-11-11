import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/api/api_exception.dart';

/// Registers the PC: `(password, name)` → throws [ApiException] on failure.
typedef RegisterCallback = Future<void> Function(String password, String? name);

/// First run (no device token): staff enters the center password and an
/// optional PC name; only then does the PC register with the server.
class SetupView extends StatefulWidget {
  const SetupView({super.key, required this.onRegister, this.initialName});

  final RegisterCallback onRegister;
  final String? initialName;

  @override
  State<SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<SetupView> {
  final _password = TextEditingController();
  late final TextEditingController _name = TextEditingController(text: widget.initialName ?? '');
  final _passwordFocus = FocusNode();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _name.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (_password.text.isEmpty) {
      setState(() => _error = 'Enter the center password.');
      _passwordFocus.requestFocus();
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onRegister(_password.text, _name.text.trim().isEmpty ? null : _name.text.trim());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = setupErrorMessage(e));
      _password.clear();
      _passwordFocus.requestFocus();
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('setup-view'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(children: [
          IeltsBadge(),
          SizedBox(width: 10),
          Text('Mynine', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 24),
        const Text('Set up this PC',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.ink)),
        const SizedBox(height: 8),
        const Text(
          'Staff only. Enter the center password to register this computer. '
          'An administrator then approves it and gives it a number.',
          style: TextStyle(fontSize: 15, color: AppColors.grey),
        ),
        const SizedBox(height: 24),
        TextField(
          key: const Key('setup-password'),
          controller: _password,
          focusNode: _passwordFocus,
          autofocus: true,
          obscureText: true,
          enabled: !_busy,
          decoration: const InputDecoration(labelText: 'Center password'),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('setup-name'),
          controller: _name,
          enabled: !_busy,
          inputFormatters: [LengthLimitingTextInputFormatter(100)],
          decoration: const InputDecoration(labelText: 'PC name (optional, e.g. PC-07)'),
          onSubmitted: (_) => _submit(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, key: const Key('setup-error'), style: const TextStyle(color: Colors.red, fontSize: 14)),
        ],
        const SizedBox(height: 20),
        FilledButton(
          key: const Key('setup-submit'),
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : const Text('REGISTER THIS PC'),
        ),
      ],
    );
  }
}

/// English message for a failed registration.
String setupErrorMessage(ApiException e) => switch (e.code) {
      ApiErrorCode.invalidPassword => 'Incorrect center password.',
      ApiErrorCode.setupPasswordMissing => e.userMessage,
      ApiErrorCode.deviceBlocked => 'This computer is blocked. Ask the administrator to unblock it.',
      ApiErrorCode.validationFailed => e.message ?? 'Please check the entered data.',
      _ => e.userMessage,
    };

/// Registered but not approved yet: waits for the Admin (the kiosk
/// controller polls GET /device/config every 30 s and this view disappears
/// once the PC is approved).
class PendingApprovalView extends StatelessWidget {
  const PendingApprovalView({
    super.key,
    required this.pcName,
    required this.machineIdShort,
    this.onCheckNow,
  });

  final String pcName;
  final String machineIdShort;
  final VoidCallback? onCheckNow;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('approval-pending'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(children: [
          IeltsBadge(),
          SizedBox(width: 10),
          Text('Mynine', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 24),
        const Row(children: [
          SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
          SizedBox(width: 14),
          Expanded(
            child: Text('Waiting for administrator approval',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.ink)),
          ),
        ]),
        const SizedBox(height: 12),
        const Text(
          'This PC is registered. An administrator must approve it in the admin panel '
          '(Devices) and give it a number. This screen updates automatically.',
          style: TextStyle(fontSize: 15, color: AppColors.grey),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.panel, border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _InfoRow(label: 'PC name', value: pcName, valueKey: const Key('pending-pc-name')),
            const SizedBox(height: 6),
            _InfoRow(label: 'Machine ID', value: machineIdShort, mono: true),
          ]),
        ),
        if (onCheckNow != null) ...[
          const SizedBox(height: 20),
          OutlinedButton.icon(
            key: const Key('pending-check-now'),
            onPressed: onCheckNow,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Check now'),
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.mono = false, this.valueKey});

  final String label;
  final String value;
  final bool mono;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) => Row(children: [
        SizedBox(width: 110, child: Text(label, style: const TextStyle(color: AppColors.grey))),
        Expanded(
          child: Text(
            value,
            key: valueKey,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
              fontFamily: mono ? 'monospace' : null,
            ),
          ),
        ),
      ]);
}
