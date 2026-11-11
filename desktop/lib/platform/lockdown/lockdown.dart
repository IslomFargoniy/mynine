import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Events pushed from the native side.
enum LockdownEventType { focusLost, focusGained, displayChanged, captureBlocked, unknown }

class LockdownEvent {
  const LockdownEvent(this.type, [this.detail = const {}]);
  final LockdownEventType type;
  final Map<String, Object?> detail;

  static LockdownEventType parseType(String? s) => switch (s) {
        'focus_lost' => LockdownEventType.focusLost,
        'focus_gained' => LockdownEventType.focusGained,
        'display_changed' => LockdownEventType.displayChanged,
        'capture_blocked' => LockdownEventType.captureBlocked,
        _ => LockdownEventType.unknown,
      };
}

/// Processes the app never terminates, whatever the server's banned list says
/// (Windows shell / session / security processes and the app itself).
const kProtectedProcesses = <String>{
  'system', 'registry', 'idle', 'smss.exe', 'csrss.exe', 'wininit.exe', 'winlogon.exe', 'services.exe',
  'lsass.exe', 'lsaiso.exe', 'svchost.exe', 'explorer.exe', 'dwm.exe', 'fontdrvhost.exe', 'sihost.exe',
  'ctfmon.exe', 'taskhostw.exe', 'runtimebroker.exe', 'searchhost.exe', 'searchapp.exe',
  'startmenuexperiencehost.exe', 'shellexperiencehost.exe', 'textinputhost.exe', 'logonui.exe',
  'conhost.exe', 'audiodg.exe', 'spoolsv.exe', 'msmpeng.exe', 'securityhealthservice.exe',
  'securityhealthsystray.exe', 'userinit.exe', 'dllhost.exe', 'wudfhost.exe', 'mynine.exe',
  'mynine_desktop.exe',
};

/// Fallback banned list until the PC has fetched `GET /device/config`
/// (mirrors the server default in config/desktop.php).
const kDefaultBannedProcesses = <String>[
  'taskmgr.exe', 'processhacker.exe', 'procexp.exe', 'procexp64.exe', 'cmd.exe', 'powershell.exe', 'pwsh.exe',
  'windowsterminal.exe', 'mstsc.exe', 'teams.exe', 'ms-teams.exe', 'slack.exe', 'whatsapp.exe', 'skype.exe',
  'zoom.exe', 'chrome.exe', 'msedge.exe', 'firefox.exe', 'opera.exe', 'brave.exe', 'yandex.exe', 'browser.exe',
  'anydesk.exe', 'teamviewer.exe', 'rustdesk.exe', 'discord.exe', 'telegram.exe', 'obs64.exe', 'obs32.exe',
  'snippingtool.exe', 'screenclippinghost.exe', 'notepad.exe', 'wordpad.exe', 'winword.exe',
];

/// The list actually enforced: the server list (or the default), lower case,
/// without protected system processes.
List<String> effectiveBannedProcesses(List<String> fromServer) {
  final source = fromServer.isEmpty ? kDefaultBannedProcesses : fromServer;
  final out = <String>{};
  for (final name in source) {
    final n = name.trim().toLowerCase();
    if (n.isNotEmpty && !kProtectedProcesses.contains(n)) out.add(n);
  }
  return out.toList();
}

/// Result of terminating the processes of one banned exe name.
class ProcessKillResult {
  const ProcessKillResult(this.process, {required this.terminated});

  /// Lower-case exe name, e.g. `chrome.exe`.
  final String process;

  /// True when every running instance (of this user's session) was closed.
  final bool terminated;

  @override
  String toString() => 'ProcessKillResult($process, terminated: $terminated)';
}

/// Kiosk / anti-cheat primitives. Implemented natively on Windows
/// (`windows/runner/lockdown_channel.cpp`) over MethodChannel `mynine/lockdown`.
abstract class Lockdown {
  /// Whether lockdown is real on this platform.
  bool get isSupported;

  /// Fullscreen + topmost kiosk window, keyboard hook (Win, Alt+Tab, Alt+F4,
  /// Ctrl+Esc, Ctrl+Shift+Esc, Alt+Esc, Alt+Space, PrintScreen), capture
  /// protection (WDA_EXCLUDEFROMCAPTURE), other windows minimized, and the
  /// per-user system policies (Task Manager / Lock / Change password off,
  /// touchpad gestures off, toast notifications off). Original values are
  /// saved in `%LOCALAPPDATA%\Mynine\lockdown_applied.ini` and restored on
  /// [disable] — or at the next start if the app crashed.
  Future<void> enable();

  /// Restores the normal window, the hook and the saved system policies.
  Future<void> disable();

  /// Terminates the running processes named in [names] (lower case exe names)
  /// that belong to this user's session. Protected system processes are
  /// skipped. One result per name that was running.
  Future<List<ProcessKillResult>> terminateProcesses(List<String> names);

  Future<int> monitorCount();

  /// Returns the names (lower case, e.g. `chrome.exe`) of running processes
  /// that appear in [banned].
  Future<List<String>> scanProcesses(List<String> banned);

  Future<void> clearClipboard();

  /// Stable machine id (Windows `MachineGuid`). Null if unavailable.
  Future<String?> machineId();

  /// True if the BIOS vendor looks like a virtual machine.
  Future<bool> isVirtualMachine();

  Stream<LockdownEvent> get events;
}

/// No-op implementation for macOS/Linux dev runs and the fake demo.
class NoopLockdown implements Lockdown {
  final _events = StreamController<LockdownEvent>.broadcast();

  @override
  bool get isSupported => false;
  @override
  Future<void> enable() async {}
  @override
  Future<void> disable() async {}
  @override
  Future<int> monitorCount() async => 1;
  @override
  Future<List<String>> scanProcesses(List<String> banned) async => const [];
  @override
  Future<List<ProcessKillResult>> terminateProcesses(List<String> names) async => const [];
  @override
  Future<void> clearClipboard() async {}
  @override
  Future<String?> machineId() async => null;
  @override
  Future<bool> isVirtualMachine() async => false;
  @override
  Stream<LockdownEvent> get events => _events.stream;
}

/// MethodChannel implementation (Windows).
class MethodChannelLockdown implements Lockdown {
  MethodChannelLockdown({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('mynine/lockdown') {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onEvent') {
        final args = (call.arguments as Map?)?.cast<Object?, Object?>() ?? {};
        _events.add(LockdownEvent(
          LockdownEvent.parseType(args['type']?.toString()),
          args.map((k, v) => MapEntry(k.toString(), v)),
        ));
      }
      return null;
    });
  }

  final MethodChannel _channel;
  final _events = StreamController<LockdownEvent>.broadcast();

  @override
  bool get isSupported => true;

  Future<T?> _call<T>(String method, [Object? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      debugPrint('lockdown.$method failed: ${e.code} ${e.message}');
      return null;
    } on MissingPluginException {
      debugPrint('lockdown.$method: channel not registered');
      return null;
    }
  }

  @override
  Future<void> enable() => _call<void>('enable', {
        'keyboardHook': true,
        'captureProtection': true,
        'kiosk': true,
        'systemPolicies': true,
        'minimizeOthers': true,
      });

  @override
  Future<void> disable() => _call<void>('disable');

  @override
  Future<int> monitorCount() async => await _call<int>('monitorCount') ?? 1;

  @override
  Future<List<String>> scanProcesses(List<String> banned) async {
    final r = await _call<List<Object?>>(
      'scanProcesses',
      {'names': banned.map((e) => e.toLowerCase()).toList()},
    );
    return r?.map((e) => e.toString()).toList() ?? const [];
  }

  @override
  Future<List<ProcessKillResult>> terminateProcesses(List<String> names) async {
    final wanted = names.map((e) => e.toLowerCase()).where((e) => !kProtectedProcesses.contains(e)).toList();
    if (wanted.isEmpty) return const [];
    final r = await _call<List<Object?>>('terminateProcesses', {'names': wanted});
    if (r == null) return const [];
    return [
      for (final item in r)
        if (item is Map)
          ProcessKillResult(item['process']?.toString() ?? '', terminated: item['terminated'] == true),
    ].where((e) => e.process.isNotEmpty).toList();
  }

  @override
  Future<void> clearClipboard() => _call<void>('clearClipboard');

  @override
  Future<String?> machineId() => _call<String>('machineId');

  @override
  Future<bool> isVirtualMachine() async =>
      await _call<bool>('isVirtualMachine') ?? false;

  @override
  Stream<LockdownEvent> get events => _events.stream;
}

Lockdown createLockdown() =>
    Platform.isWindows ? MethodChannelLockdown() : NoopLockdown();
