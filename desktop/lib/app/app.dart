import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';

import '../features/admin/admin_menu.dart';
import 'providers.dart';
import 'router.dart';
import 'theme.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

class MynineApp extends ConsumerStatefulWidget {
  const MynineApp({super.key});

  @override
  ConsumerState<MynineApp> createState() => _MynineAppState();
}

class _MynineAppState extends ConsumerState<MynineApp> with WindowListener {
  late final GoRouter _router;
  bool _adminOpen = false;

  @override
  void initState() {
    super.initState();
    final exam = ref.read(examControllerProvider);
    _router = buildRouter(exam);
    HardwareKeyboard.instance.addHandler(_onKey);
    windowManager.addListener(this);
    // Resume an exam interrupted by a crash / restart.
    unawaited(exam.resumeIfNeeded());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(updateServiceProvider).reportUiRendered();
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    windowManager.removeListener(this);
    super.dispose();
  }

  /// Hidden admin menu: Ctrl+Shift+M.
  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final keys = HardwareKeyboard.instance;
    if (event.logicalKey == LogicalKeyboardKey.keyM &&
        keys.isControlPressed &&
        keys.isShiftPressed) {
      unawaited(_openAdmin());
      return true;
    }
    return false;
  }

  Future<void> _openAdmin() async {
    if (_adminOpen) return;
    final context = _router.routerDelegate.navigatorKey.currentContext;
    if (context == null) return;
    _adminOpen = true;
    try {
      await showAdminMenu(context, ref);
    } finally {
      _adminOpen = false;
    }
  }

  @override
  void onWindowClose() async {
    // Closing is only possible through the admin menu (exit password).
    final kiosk = ref.read(kioskControllerProvider);
    final exam = ref.read(examControllerProvider);
    if (!kiosk.kioskLocked && !exam.examActive) {
      await kiosk.exitApp();
      return;
    }
    await _openAdmin();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mynine Exam',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      routerConfig: _router,
    );
  }
}
