import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/mynine_api.dart';
import '../db/app_database.dart';
import 'answer_queue.dart';
import 'violation_queue.dart';

/// Online/offline state as observed by real requests.
class ConnectionStatus extends ChangeNotifier {
  bool _online = true;
  DateTime? _onlineSince = DateTime.now().toUtc();

  bool get online => _online;
  DateTime? get onlineSince => _onlineSince;

  void reportSuccess() {
    if (!_online) {
      _online = true;
      _onlineSince = DateTime.now().toUtc();
      notifyListeners();
    }
  }

  void reportFailure(Object error) {
    if (error is ApiException && !error.isNetwork) return;
    if (_online) {
      _online = false;
      _onlineSince = null;
      notifyListeners();
    }
  }
}

/// Background delivery of queued answers, violations and pending final
/// submits for every open session on this PC. Keeps retrying with backoff;
/// never drops data.
class SyncService extends ChangeNotifier {
  SyncService({
    required this.api,
    required this.db,
    required this.answers,
    required this.violations,
    required this.connection,
  });

  final MynineApi api;
  final AppDatabase db;
  final AnswerQueueRepository answers;
  final ViolationQueueRepository violations;
  final ConnectionStatus connection;

  final Backoff _backoff = Backoff();
  Timer? _timer;
  bool _running = false;
  bool _again = false;
  bool _disposed = false;

  int _pendingAnswers = 0;
  int _pendingViolations = 0;
  int get pendingAnswers => _pendingAnswers;
  int get pendingViolations => _pendingViolations;

  /// Called when a final submit has been confirmed by the server.
  void Function(int attemptId)? onSessionClosed;

  /// Called when the server refused a session's token (401
  /// `session_revoked` / `session_expired`). The session's queue is kept; it
  /// is skipped until a new login on this PC replaces the token.
  void Function(int attemptId)? onSessionAuthLost;

  /// Called when the server deferred answers because the attempt is paused.
  void Function(int attemptId)? onPausedDetected;

  bool _deferred = false;

  void start() {
    _schedule(Duration.zero);
  }

  /// Run a sync pass as soon as possible.
  void kick() {
    if (_running) {
      _again = true;
      return;
    }
    _schedule(Duration.zero);
  }

  void _schedule(Duration delay) {
    if (_disposed) return;
    _timer?.cancel();
    _timer = Timer(delay, _run);
  }

  Future<void> _run() async {
    if (_running || _disposed) return;
    _running = true;
    _deferred = false;
    var failed = false;
    try {
      final sessions = await db.openSessions();
      for (final s in sessions) {
        try {
          await syncSession(s);
        } on ApiException catch (e) {
          if (e.isAuthLost) {
            // Token revoked / expired: keep every queued item (it is sent once
            // the session is restored by a new login on this PC).
            debugPrint('Session ${s.attemptId}: token refused (${e.code.wire}); queue kept.');
            await db.markSession(s.attemptId, authLost: true);
            onSessionAuthLost?.call(s.attemptId);
          } else if (e.code == ApiErrorCode.attemptFinished) {
            // The attempt is finished: the server refuses every further batch.
            // Data stays in SQLite for audit.
            debugPrint('Session ${s.attemptId}: attempt finished, closing.');
            await db.markSession(s.attemptId, closed: true);
          } else {
            failed = true;
            connection.reportFailure(e);
          }
        } catch (e) {
          failed = true;
          connection.reportFailure(e);
        }
      }
    } finally {
      _pendingAnswers = await answers.pendingCount();
      _pendingViolations = await violations.pendingCount();
      _running = false;
      if (!_disposed) notifyListeners();
    }
    if (failed) {
      _backoff.fail();
    } else {
      _backoff.reset();
    }
    if (_again) {
      _again = false;
      _schedule(Duration.zero);
    } else if (failed) {
      _schedule(_backoff.nextDelay);
    } else if (_deferred) {
      // Paused: the server keeps deferring; check again a little later.
      _schedule(const Duration(seconds: 10));
    } else if (_pendingAnswers > 0 || _pendingViolations > 0) {
      _schedule(const Duration(seconds: 2));
    } else {
      _schedule(const Duration(seconds: 15));
    }
  }

  /// Delivers everything queued for one session; sends the final submit when
  /// the answer queue is empty and the session is marked `submitPending`.
  /// Violations are best effort: a failure there never blocks the submit.
  Future<void> syncSession(ExamSessionRow s) async {
    final r = await answers.drainDetailed(api, s.token, s.attemptId);
    connection.reportSuccess();
    if (r.deferred > 0) {
      _deferred = true;
      onPausedDetected?.call(s.attemptId);
    }
    await syncViolations(s);
    final left = r.remaining;
    if (s.submitPending && left == 0) {
      try {
        await api.submitExam(s.token);
      } on ApiException catch (e) {
        if (e.code != ApiErrorCode.attemptFinished) rethrow;
      }
      await db.markSession(s.attemptId, submitPending: false, closed: true);
      onSessionClosed?.call(s.attemptId);
    } else if (s.completed && !s.submitPending && left == 0) {
      await db.markSession(s.attemptId, closed: true);
    }
  }

  /// Sends queued violations; errors other than a refused token are logged
  /// and left for the next pass.
  Future<void> syncViolations(ExamSessionRow s) async {
    try {
      while (await violations.syncOnce(api, s.token, s.attemptId) > 0) {}
    } on ApiException catch (e) {
      if (e.isAuthLost) rethrow;
      debugPrint('Violations of ${s.attemptId} not sent yet: $e');
    } catch (e) {
      debugPrint('Violations of ${s.attemptId} not sent yet: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
