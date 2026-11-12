import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../app/widgets.dart';
import '../../core/api/api_exception.dart';

/// Registers the PC: `(centerCode, password, name)` → throws [ApiException]
/// on failure. An empty center code means the Mynine center (older setups).
typedef RegisterCallback = Future<void> Function(String centerCode, String password, String? name);

/// Center codes: uppercase letters and digits, 3–12 characters.
final centerCodePattern = RegExp(r'^[A-Z0-9]{3,12}$');

/// Uppercases and keeps only A-Z / 0-9 (at most 12) in a center code field.
final List<TextInputFormatter> centerCodeFormatters = [
  TextInputFormatter.withFunction((oldValue, newValue) {
    final clean = newValue.text.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    final text = clean.length > 12 ? clean.substring(0, 12) : clean;
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }),
];

/// Error for an entered center code, or null when it may be sent (empty is
/// allowed: the server then uses the Mynine center).
String? centerCodeError(String code) =>
    code.isEmpty || centerCodePattern.hasMatch(code) ? null : 'The center code has 3–12 letters or digits.';

/// First run (no device token): staff enters the center code, the center
/// password and an optional PC name; only then does the PC register.
class SetupView extends StatefulWidget {
  const SetupView({super.key, required this.onRegister, this.initialName, this.initialCenterCode});

  final RegisterCallback onRegister;
  final String? initialName;

  /// Last center code used on this PC (prefilled).
  final String? initialCenterCode;

  @override
  State<SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<SetupView> {
  late final TextEditingController _centerCode = TextEditingController(text: widget.initialCenterCode ?? '');
  final _password = TextEditingController();
  late final TextEditingController _name = TextEditingController(text: widget.initialName ?? '');
  final _passwordFocus = FocusNode();
  final _centerCodeFocus = FocusNode();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _centerCode.dispose();
    _password.dispose();
    _name.dispose();
    _passwordFocus.dispose();
    _centerCodeFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final codeError = centerCodeError(_centerCode.text);
    if (codeError != null) {
      setState(() => _error = codeError);
      _centerCodeFocus.requestFocus();
      return;
    }
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
      await widget.onRegister(_centerCode.text, _password.text, _name.text.trim().isEmpty ? null : _name.text.trim());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = setupErrorMessage(e));
      if (e.code == ApiErrorCode.invalidCenterCode) {
        _centerCodeFocus.requestFocus();
      } else {
        _password.clear();
        _passwordFocus.requestFocus();
      }
    } catch (e) {
      // Show the cause: staff reads it out when reporting a setup problem.
      final detail = e.toString().replaceAll(RegExp(r'\s+'), ' ');
      if (mounted) {
        setState(() => _error =
            'Something went wrong. Please try again. (${detail.length > 140 ? '${detail.substring(0, 140)}…' : detail})');
      }
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
          'Staff only. Enter the center code and password to register this computer. '
          'An administrator then approves it and gives it a number.',
          style: TextStyle(fontSize: 15, color: AppColors.grey),
        ),
        const SizedBox(height: 24),
        TextField(
          key: const Key('setup-center-code'),
          controller: _centerCode,
          focusNode: _centerCodeFocus,
          autofocus: _centerCode.text.isEmpty,
          enabled: !_busy,
          inputFormatters: centerCodeFormatters,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(labelText: 'Center code *', hintText: 'e.g. MYNINE'),
          onSubmitted: (_) => _passwordFocus.requestFocus(),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('setup-password'),
          controller: _password,
          focusNode: _passwordFocus,
          autofocus: _centerCode.text.isNotEmpty,
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
      ApiErrorCode.invalidCenterCode ||
      ApiErrorCode.centerSuspended =>
        e.userMessage,
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
    this.centerName = 'Mynine',
  });

  /// Brand name next to the IELTS badge (the PC's center).
  final String centerName;
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
        Row(children: [
          const IeltsBadge(),
          const SizedBox(width: 10),
          Expanded(
            child: Text(centerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ),
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
