import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/code_entry/code_entry_screen.dart';
import '../features/completed/completed_screen.dart';
import '../features/exam/exam_controller.dart';
import '../features/exam/exam_shell.dart';
import '../features/exam/transition_screen.dart';
import '../features/prefetch/prefetch_screen.dart';
import '../features/rules/rules_screen.dart';
import '../features/sound_check/sound_check_screen.dart';

abstract final class Routes {
  static const code = '/';
  static const prefetch = '/prefetch';
  static const rules = '/rules';
  static const soundCheck = '/sound-check';
  static const exam = '/exam';
  static const transition = '/transition';
  static const completed = '/completed';

  static String forStage(ExamStage s) => switch (s) {
        ExamStage.idle => code,
        ExamStage.prefetching => prefetch,
        ExamStage.rules => rules,
        ExamStage.soundCheck => soundCheck,
        ExamStage.exam => exam,
        ExamStage.transition => transition,
        ExamStage.completed => completed,
      };
}

/// The exam stage is the single source of truth for navigation: the router
/// redirects to the screen of the current stage whenever it changes, so the
/// candidate can never navigate "back".
GoRouter buildRouter(ExamController exam) {
  Page<void> page(Widget child) => NoTransitionPage<void>(child: child);
  return GoRouter(
    initialLocation: Routes.code,
    refreshListenable: _StageListenable(exam),
    redirect: (context, state) {
      final target = Routes.forStage(exam.stage);
      return state.matchedLocation == target ? null : target;
    },
    routes: [
      GoRoute(path: Routes.code, pageBuilder: (_, _) => page(const CodeEntryScreen())),
      GoRoute(path: Routes.prefetch, pageBuilder: (_, _) => page(const PrefetchScreen())),
      GoRoute(path: Routes.rules, pageBuilder: (_, _) => page(const RulesScreen())),
      GoRoute(path: Routes.soundCheck, pageBuilder: (_, _) => page(const SoundCheckScreen())),
      GoRoute(path: Routes.exam, pageBuilder: (_, _) => page(const ExamShell())),
      GoRoute(path: Routes.transition, pageBuilder: (_, _) => page(const TransitionScreen())),
      GoRoute(path: Routes.completed, pageBuilder: (_, _) => page(const CompletedScreen())),
    ],
  );
}

/// Notifies the router only when the stage changes (not on every tick).
class _StageListenable extends ChangeNotifier {
  _StageListenable(this.exam) : _last = exam.stage {
    exam.addListener(_check);
  }

  final ExamController exam;
  ExamStage _last;

  void _check() {
    if (exam.stage != _last) {
      _last = exam.stage;
      notifyListeners();
    }
  }
}
