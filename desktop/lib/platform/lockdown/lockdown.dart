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

/// Kiosk / anti-cheat primitives. Implemented natively on Windows
/// (`windows/runner/lockdown_channel.cpp`) over MethodChannel `mynine/lockdown`.
abstract class Lockdown {
  /// Whether lockdown is real on this platform.
  bool get isSupported;

  /// Fullscreen + topmost kiosk window, keyboard hook (Win, Alt+Tab, Alt+F4,
  /// Ctrl+Esc, Alt+Esc) and capture protection (WDA_EXCLUDEFROMCAPTURE).
  Future<void> enable();

  /// Restores the normal window and removes the hook.
  Future<void> disable();

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
  Future<void> enable() =>
      _call<void>('enable', {'keyboardHook': true, 'captureProtection': true, 'kiosk': true});

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
