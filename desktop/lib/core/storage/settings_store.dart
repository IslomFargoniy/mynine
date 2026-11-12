import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;

/// Key/value store for device settings (device token, PC name, server URL,
/// cached device config).
///
/// Uses flutter_secure_storage (DPAPI on Windows, Keychain on macOS). If the
/// secure store is unavailable (e.g. unsigned macOS debug build without a
/// keychain entitlement) it falls back to a JSON file in the app support dir.
abstract class SettingsStore {
  Future<String?> read(String key);
  Future<void> write(String key, String? value);
}

abstract final class SettingsKeys {
  static const deviceToken = 'device_token';
  static const deviceId = 'device_id';
  static const machineIdFallback = 'machine_id_fallback';
  static const pcName = 'pc_name';
  static const pcNumber = 'pc_number';
  static const deviceApproved = 'device_approved';
  static const serverUrl = 'server_url';
  static const deviceConfig = 'device_config_json';
  /// Last center code entered on the Setup screen / admin menu (prefilled).
  static const centerCode = 'center_code';
}

class SecureSettingsStore implements SettingsStore {
  SecureSettingsStore(this._fallbackDir);

  final Directory _fallbackDir;
  final _secure = const FlutterSecureStorage();
  bool _useFallback = false;
  Map<String, String>? _fallbackCache;

  File get _fallbackFile => File(p.join(_fallbackDir.path, 'settings.json'));

  Future<Map<String, String>> _loadFallback() async {
    if (_fallbackCache != null) return _fallbackCache!;
    try {
      if (await _fallbackFile.exists()) {
        final decoded = jsonDecode(await _fallbackFile.readAsString());
        if (decoded is Map) {
          return _fallbackCache =
              decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
        }
      }
    } catch (_) {}
    return _fallbackCache = {};
  }

  Future<void> _saveFallback() async {
    await _fallbackDir.create(recursive: true);
    await _fallbackFile.writeAsString(jsonEncode(_fallbackCache ?? {}));
  }

  @override
  Future<String?> read(String key) async {
    if (!_useFallback) {
      try {
        return await _secure.read(key: key);
      } catch (e) {
        debugPrint('Secure storage unavailable, using file fallback: $e');
        _useFallback = true;
      }
    }
    return (await _loadFallback())[key];
  }

  @override
  Future<void> write(String key, String? value) async {
    if (!_useFallback) {
      try {
        if (value == null) {
          await _secure.delete(key: key);
        } else {
          await _secure.write(key: key, value: value);
        }
        return;
      } catch (e) {
        debugPrint('Secure storage unavailable, using file fallback: $e');
        _useFallback = true;
      }
    }
    final map = await _loadFallback();
    if (value == null) {
      map.remove(key);
    } else {
      map[key] = value;
    }
    await _saveFallback();
  }
}

/// In-memory store for tests and the fake API demo.
class MemorySettingsStore implements SettingsStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String? value) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }
}
