import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/api/trusted_roots.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = TrustedRootsHttpOverrides();
  try {
    MediaKit.ensureInitialized();
  } catch (e) {
    // libmpv missing (e.g. macOS dev build without media_kit_libs_macos_audio):
    // the app still runs, Listening shows an audio error instead of crashing.
    debugPrint('media_kit unavailable: $e');
  }
  await windowManager.ensureInitialized();
  const options = WindowOptions(
    title: 'Mynine Exam',
    minimumSize: Size(1024, 700),
    size: Size(1366, 820),
    center: true,
  );
  unawaited(windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.setPreventClose(true);
    await windowManager.show();
    await windowManager.focus();
  }));

  final overrides = await bootstrap();
  runApp(ProviderScope(overrides: overrides, child: const MynineApp()));
}
