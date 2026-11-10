import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/mynine_api.dart';
import '../core/config/app_config.dart';
import '../core/storage/app_paths.dart';
import '../core/time/server_clock.dart';
import '../data/db/app_database.dart';
import '../data/repositories/device_repository.dart';
import '../data/repositories/sync_service.dart';
import '../features/exam/exam_controller.dart';
import '../features/updater/update_service.dart';
import '../platform/lockdown/lockdown.dart';
import 'kiosk_controller.dart';

// Services are created once in `bootstrap()` (lib/app/bootstrap.dart) and
// injected with ProviderScope overrides. Long-lived services are
// ChangeNotifiers; widgets listen with ListenableBuilder.

T _missing<T>() => throw UnimplementedError('$T must be overridden in ProviderScope');

final appConfigProvider = Provider<AppConfig>((ref) => _missing());
final appPathsProvider = Provider<AppPaths>((ref) => _missing());
final databaseProvider = Provider<AppDatabase>((ref) => _missing());
final serverClockProvider = Provider<ServerClock>((ref) => _missing());
final apiProvider = Provider<MynineApi>((ref) => _missing());
final lockdownProvider = Provider<Lockdown>((ref) => _missing());
final connectionProvider = Provider<ConnectionStatus>((ref) => _missing());
final syncServiceProvider = Provider<SyncService>((ref) => _missing());
final deviceRepositoryProvider = Provider<DeviceRepository>((ref) => _missing());
final examControllerProvider = Provider<ExamController>((ref) => _missing());
final updateServiceProvider = Provider<UpdateService>((ref) => _missing());
final kioskControllerProvider = Provider<KioskController>((ref) => _missing());

/// Accessibility settings of the exam room (text size, contrast, timer).
enum TextSizeSetting { standard, large, xlarge }

enum ContrastSetting { standard, yellowBlack, blueWhite }

class ExamViewSettings {
  const ExamViewSettings({
    this.textSize = TextSizeSetting.standard,
    this.contrast = ContrastSetting.standard,
    this.timerHidden = false,
  });

  final TextSizeSetting textSize;
  final ContrastSetting contrast;
  final bool timerHidden;

  double get textScale => switch (textSize) {
        TextSizeSetting.standard => 1.0,
        TextSizeSetting.large => 1.15,
        TextSizeSetting.xlarge => 1.3,
      };

  ExamViewSettings copyWith({TextSizeSetting? textSize, ContrastSetting? contrast, bool? timerHidden}) =>
      ExamViewSettings(
        textSize: textSize ?? this.textSize,
        contrast: contrast ?? this.contrast,
        timerHidden: timerHidden ?? this.timerHidden,
      );
}

class ExamViewSettingsNotifier extends Notifier<ExamViewSettings> {
  @override
  ExamViewSettings build() => const ExamViewSettings();

  void cycleTextSize() => state = state.copyWith(
        textSize: TextSizeSetting.values[(state.textSize.index + 1) % TextSizeSetting.values.length],
      );

  void cycleContrast() => state = state.copyWith(
        contrast: ContrastSetting.values[(state.contrast.index + 1) % ContrastSetting.values.length],
      );

  void setTextSize(TextSizeSetting s) => state = state.copyWith(textSize: s);
  void setContrast(ContrastSetting c) => state = state.copyWith(contrast: c);
  void toggleTimer() => state = state.copyWith(timerHidden: !state.timerHidden);
  void reset() => state = const ExamViewSettings();
}

final examViewSettingsProvider =
    NotifierProvider<ExamViewSettingsNotifier, ExamViewSettings>(ExamViewSettingsNotifier.new);
