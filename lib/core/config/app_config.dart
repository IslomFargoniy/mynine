import 'dart:io';

/// Compile-time and runtime configuration.
///
/// * `--dart-define=API_FAKE=true` runs against the built-in fake API (demo).
/// * `--dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1` overrides the
///   default server (the admin menu can also change it at runtime).
/// * `--dart-define=KIOSK=false` disables lockdown even on Windows (dev only).
class AppConfig {
  const AppConfig({
    required this.appVersion,
    required this.apiFake,
    required this.defaultBaseUrl,
    required this.kioskEnabled,
  });

  static const bool apiFakeDefine = bool.fromEnvironment('API_FAKE');
  static const String baseUrlDefine = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://mynine.uz/api/v1',
  );
  static const bool kioskDefine = bool.fromEnvironment('KIOSK', defaultValue: true);

  /// Semver of the running app (from package_info, e.g. `1.0.0`).
  final String appVersion;
  final bool apiFake;
  final String defaultBaseUrl;

  /// Lockdown is only implemented on Windows.
  final bool kioskEnabled;

  static AppConfig fromEnvironment(String appVersion) => AppConfig(
        appVersion: appVersion,
        apiFake: apiFakeDefine,
        defaultBaseUrl: baseUrlDefine,
        kioskEnabled: kioskDefine && Platform.isWindows && !apiFakeDefine,
      );

  String get clientHeader => 'desktop/$appVersion';

  /// Code screen version check interval.
  static const updateCheckInterval = Duration(minutes: 30);

  /// Max random delay before an automatic update download.
  static const updateJitterMax = Duration(minutes: 10);

  /// Device heartbeat on the code screen.
  static const deviceHeartbeatInterval = Duration(seconds: 60);

  /// Retry GET /device/config while the PC waits for admin approval.
  static const approvalPollInterval = Duration(seconds: 30);

  /// Banned process / monitor scan interval during the exam.
  static const lockdownScanInterval = Duration(seconds: 5);

  /// Completed screen auto-return.
  static const completedReturnDelay = Duration(seconds: 10);

  /// Final submit waits at most this long for the answer queue while offline.
  static const offlineSubmitGrace = Duration(minutes: 5);

  /// Post-update self-check window.
  static const updateSelfCheckWindow = Duration(minutes: 2);

  /// Max answers per `POST /exam/answers` batch.
  static const answerBatchSize = 200;
}
