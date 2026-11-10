import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/mynine_api.dart';
import '../../core/config/app_config.dart';
import '../../core/time/server_clock.dart';
import '../../data/db/app_database.dart';
import '../../data/models/exam_models.dart';
import '../../data/models/part_payload.dart';
import '../../data/repositories/answer_queue.dart';
import '../../data/repositories/device_repository.dart';
import '../../data/repositories/exam_repository.dart';
import '../../data/repositories/sync_service.dart';
import '../../data/repositories/violation_queue.dart';

enum ExamStage { idle, prefetching, rules, soundCheck, exam, transition, completed }

/// Drives one candidate's exam on this PC:
/// code → prefetch → rules → sound check → Listening → Reading → Writing →
/// Completed. All answers go through the local queue first.
class ExamController extends ChangeNotifier {
  ExamController({
    required this.api,
    required this.db,
    required this.clock,
    required this.examRepo,
    required this.answerQueue,
    required this.violationQueue,
    required this.sync,
    required this.device,
    required this.connection,
  });

  final MynineApi api;
  final AppDatabase db;
  final ServerClock clock;
  final ExamRepository examRepo;
  final AnswerQueueRepository answerQueue;
  final ViolationQueueRepository violationQueue;
  final SyncService sync;
  final DeviceRepository device;
  final ConnectionStatus connection;

  // ---- State ---------------------------------------------------------------------

  ExamStage _stage = ExamStage.idle;
  ExamStage get stage => _stage;

  bool _busy = false;
  bool get busy => _busy;

  String? _error;
  String? get error => _error;

  /// Set when the server says the app must be updated (426).
  bool _updateRequired = false;
  bool get updateRequired => _updateRequired;

  double _prefetchProgress = 0;
  double get prefetchProgress => _prefetchProgress;
  String _prefetchLabel = '';
  String get prefetchLabel => _prefetchLabel;

  String? _transitionMessage;
  String? get transitionMessage => _transitionMessage;

  int? _attemptId;
  int? get attemptId => _attemptId;
  String? _token;
  String _candidateName = '';
  String get candidateName => _candidateName;
  String _candidateCode = '';
  String get candidateCode => _candidateCode;

  CachedExam? _cached;
  CachedExam? get cached => _cached;

  List<ExamModule> _modules = const [];
  List<ExamModule> get modules => _modules;
  int _moduleIndex = 0;

  ExamModule? get currentModule =>
      _moduleIndex < _modules.length ? _modules[_moduleIndex] : null;

  final Map<int, PartPayload> _parts = {};
  int? _currentPartId;
  int? get currentPartId => _currentPartId;
  PartPayload? get currentPart => _currentPartId == null ? null : _parts[_currentPartId];

  final Map<int, SavedAnswer> _answers = {};
  final Set<int> _flagged = {};
  Set<int> get flagged => _flagged;

  int? _activeQuestionId;
  int? get activeQuestionId => _activeQuestionId;

  bool _paused = false;
  bool get paused => _paused;

  bool _finishing = false;
  bool get finishing => _finishing;

  /// Raised when an admin remotely unlocked the PC (heartbeat `unlock: true`).
  VoidCallback? onRemoteUnlock;

  Timer? _ticker;
  Timer? _heartbeat;
  final Map<int, Timer> _debounces = {};
  final Map<int, _PendingChange> _pendingChanges = {};

  // ---- Derived -----------------------------------------------------------------------

  List<PartPayload> partsOf(ExamModule m) => [
        for (final s in m.parts)
          if (_parts[s.id] != null) _parts[s.id]!,
      ];

  List<PartPayload> get currentParts =>
      currentModule == null ? const [] : partsOf(currentModule!);

  SavedAnswer answerFor(int questionId) => _answers[questionId] ?? const SavedAnswer();

  bool get moduleTimeOver => clock.isExpired(currentModule?.finishedAt);

  /// Inputs are read-only once the module time is over, while paused or while submitting.
  bool get inputsLocked => moduleTimeOver || _paused || _finishing || _stage != ExamStage.exam;

  ({int answered, int total}) stats(Iterable<PartPayload> parts) {
    var answered = 0;
    var total = 0;
    for (final p in parts) {
      for (final q in p.allQuestions) {
        total += q.answerCount;
        if (answerFor(q.id).isAnswered) answered += q.answerCount;
      }
    }
    return (answered: answered, total: total);
  }

  /// Audio file for the current listening module (test audio first, else the
  /// first part with audio).
  String? get listeningAudioFile {
    final m = currentModule;
    final c = _cached;
    if (m == null || c == null || !m.isListening) return null;
    if (m.audio != null) {
      final f = c.audioFileForUrl(m.audio!.url);
      if (f != null) return f;
    }
    for (final p in partsOf(m)) {
      if (p.audioKey != null && c.audioFiles[p.audioKey!] != null) {
        return c.audioFiles[p.audioKey!];
      }
    }
    return null;
  }

  void _set(VoidCallback f) {
    f();
    notifyListeners();
  }

  // ---- Login + prefetch ------------------------------------------------------------------

  Future<void> login(String code) async {
    if (_busy) return;
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) {
      _set(() => _error = 'Please enter your exam code.');
      return;
    }
    _set(() {
      _busy = true;
      _error = null;
      _updateRequired = false;
    });
    try {
      if (!device.isRegistered) await device.register();
      LoginResponse login;
      try {
        login = await api.login(trimmed);
      } on ApiException catch (e) {
        // 401 here can only mean the device token (no exam token yet):
        // the one case where re-registering is allowed.
        if (e.code != ApiErrorCode.unauthenticated) rethrow;
        await device.register(force: true);
        login = await api.login(trimmed);
      }
      device.markApproved();
      await db.upsertSession(ExamSessionsCompanion.insert(
        attemptId: Value(login.attemptId),
        token: login.token,
        candidateName: login.candidate.name,
        candidateCode: login.candidate.code,
        mockName: Value(login.mock.name),
        expiresAt: Value(login.expiresAt),
      ));
      _attemptId = login.attemptId;
      _token = login.token;
      _candidateName = login.candidate.name;
      _candidateCode = login.candidate.code;
      await _prefetchAndOpen();
    } on ApiException catch (e) {
      _error = e.userMessage;
      device.noteApproval(e);
      if (e.code == ApiErrorCode.deviceNotApproved) {
        _error = device.notApprovedMessage;
      }
      if (e.code == ApiErrorCode.clientOutdated) _updateRequired = true;
      if (_stage == ExamStage.prefetching) _stage = ExamStage.idle;
    } catch (e) {
      _error = 'Something went wrong. Please try again.';
      debugPrint('login failed: $e');
      if (_stage == ExamStage.prefetching) _stage = ExamStage.idle;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _prefetchAndOpen() async {
    _set(() {
      _stage = ExamStage.prefetching;
      _prefetchProgress = 0;
      _prefetchLabel = 'Preparing your exam…';
    });
    final cached = await examRepo.prefetch(
      _token!,
      _attemptId!,
      onProgress: (v, label) => _set(() {
        _prefetchProgress = v;
        _prefetchLabel = label;
      }),
    );
    await _open(cached, cached.payload.modules);
    _stage = _firstStage();
    notifyListeners();
  }

  ExamStage _firstStage() {
    final m = currentModule;
    if (m == null) return ExamStage.completed;
    // Resuming a module that is already running: straight back in.
    if (m.isInProgress) return ExamStage.exam;
    return ExamStage.rules;
  }

  Future<void> _open(CachedExam cached, List<ExamModule> modules) async {
    _cached = cached;
    _parts
      ..clear()
      ..addEntries(cached.payload.parts.map((p) => MapEntry(p.id, p)));
    _modules = List.of(modules);
    _moduleIndex = _modules.indexWhere((m) => !m.isSubmitted);
    if (_moduleIndex < 0) _moduleIndex = _modules.length;

    // Server answers first, then local answers (local is never older).
    _answers.clear();
    for (final p in cached.payload.parts) {
      for (final q in p.allQuestions) {
        if (q.answer.isAnswered) _answers[q.id] = q.answer;
      }
    }
    _answers.addAll(await answerQueue.localAnswers(_attemptId!));
    final first = currentModule?.parts.firstOrNull;
    _currentPartId = first?.id;
    _activeQuestionId = null;
    _flagged.clear();
    if (currentModule?.isInProgress ?? false) _startTimers();
  }

  /// Resumes an unfinished session after an app restart / crash.
  Future<bool> resumeIfNeeded() async {
    final s = await db.activeSession();
    if (s == null) return false;
    if (s.expiresAt != null && s.expiresAt!.isBefore(DateTime.now().toUtc())) {
      await db.markSession(s.attemptId, completed: true);
      return false;
    }
    final cached = await examRepo.loadCached(s.attemptId);
    if (cached == null) {
      await db.markSession(s.attemptId, completed: true);
      return false;
    }
    _attemptId = s.attemptId;
    _token = s.token;
    _candidateName = s.candidateName;
    _candidateCode = s.candidateCode;
    var modules = cached.payload.modules;
    try {
      final state = await api.examState(s.token);
      if (state.attempt.finished) {
        await db.markSession(s.attemptId, completed: true);
        _resetSession();
        return false;
      }
      modules = state.modules;
      _paused = state.attempt.paused;
    } on ApiException catch (e) {
      if (e.code == ApiErrorCode.unauthenticated) {
        await db.markSession(s.attemptId, completed: true);
        _resetSession();
        return false;
      }
      // Offline: continue from the cache (timers keep the cached finished_at).
      final saved = await db.getCache(_modulesKey(s.attemptId));
      if (saved != null) modules = _decodeModules(saved) ?? modules;
    }
    await _open(cached, modules);
    await _violation(ViolationType.appRestarted);
    _stage = _firstStage();
    notifyListeners();
    return true;
  }

  static String _modulesKey(int attemptId) => 'modules:$attemptId';

  List<ExamModule>? _decodeModules(String raw) {
    try {
      final c = CachedExam.fromJson({
        'payload': {'modules': _jsonDecode(raw)},
      });
      return c.payload.modules;
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistModules() async {
    final id = _attemptId;
    if (id == null) return;
    await db.putCache(_modulesKey(id), _jsonEncode(_modules.map((m) => m.toJson()).toList()));
  }

  // ---- Rules / sound check / modules --------------------------------------------------

  void acceptRules() {
    final m = currentModule;
    if (m == null) return;
    if (m.isListening && m.isNotStarted) {
      _set(() => _stage = ExamStage.soundCheck);
    } else {
      unawaited(_enterModule());
    }
  }

  void confirmSoundCheck() => unawaited(_enterModule());

  Future<void> _enterModule() async {
    final m = currentModule;
    if (m == null) {
      await _finalSubmit();
      return;
    }
    if (m.isSubmitted) {
      await _advance();
      return;
    }
    if (m.isNotStarted || m.finishedAt == null) {
      _set(() {
        _stage = ExamStage.transition;
        _transitionMessage = 'Starting ${m.title}…';
      });
      while (true) {
        try {
          final r = await api.startModule(_token!, m.typeId);
          if (r.status == ModuleStatus.submitted) {
            _modules[_moduleIndex] = m.copyWith(status: ModuleStatus.submitted);
            await _advance();
            return;
          }
          _modules[_moduleIndex] = m.copyWith(
            status: ModuleStatus.inProgress,
            startedAt: r.startedAt,
            finishedAt: r.finishedAt,
          );
          await _persistModules();
          break;
        } on ApiException catch (e) {
          if (e.code == ApiErrorCode.moduleTimeOver || e.code == ApiErrorCode.attemptFinished) {
            _modules[_moduleIndex] = m.copyWith(status: ModuleStatus.submitted);
            await _advance();
            return;
          }
          if (e.code == ApiErrorCode.unauthenticated) {
            await _endLocally();
            return;
          }
          if (e.code == ApiErrorCode.paused) _paused = true;
          _set(() => _transitionMessage = e.isTransient
              ? 'Waiting for the connection to start ${m.title}…\nYour answers are saved on this computer.'
              : e.userMessage);
          await Future<void>.delayed(const Duration(seconds: 3));
        }
      }
    }
    _currentPartId = currentModule!.parts.firstOrNull?.id;
    _activeQuestionId = null;
    _transitionMessage = null;
    _stage = ExamStage.exam;
    _startTimers();
    notifyListeners();
  }

  void _startTimers() {
    _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    _heartbeat?.cancel();
    final every = Duration(seconds: device.config.heartbeatSeconds.clamp(5, 300));
    _heartbeat = Timer.periodic(every, (_) => _sendHeartbeat());
    unawaited(_sendHeartbeat());
  }

  void _stopTimers() {
    _ticker?.cancel();
    _ticker = null;
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  void _onTick() {
    if (_stage == ExamStage.exam && !_finishing && !_paused && moduleTimeOver) {
      unawaited(_submitModule(auto: true));
    }
    // No notify here: the header timer repaints itself every second.
  }

  Future<void> _sendHeartbeat() async {
    final token = _token;
    if (token == null) return;
    try {
      final r = await api.examHeartbeat(
        token,
        typeId: currentModule?.typeId,
        partId: _currentPartId,
        queuedAnswers: await answerQueue.pendingCount(attemptId: _attemptId),
        queuedViolations: await violationQueue.pendingCount(attemptId: _attemptId),
        onlineSince: connection.onlineSince,
      );
      connection.reportSuccess();
      applyHeartbeat(r);
    } on ApiException catch (e) {
      connection.reportFailure(e);
      if (e.code == ApiErrorCode.attemptFinished) await _endLocally();
    }
  }

  /// Applies a heartbeat response: timer moves, pause, force submit, unlock.
  void applyHeartbeat(ExamHeartbeatResponse r) {
    var changed = false;
    for (final t in r.modules) {
      final i = _modules.indexWhere((m) => m.typeId == t.typeId);
      if (i < 0) continue;
      final m = _modules[i];
      if (m.finishedAt != t.finishedAt && t.finishedAt != null) {
        _modules[i] = m.copyWith(finishedAt: t.finishedAt);
        changed = true;
      }
      if (t.status == ModuleStatus.submitted && !m.isSubmitted) {
        _modules[i] = _modules[i].copyWith(status: ModuleStatus.submitted);
        changed = true;
        if (i == _moduleIndex && _stage == ExamStage.exam && !_finishing) {
          unawaited(_afterModuleSubmitted());
        }
      }
    }
    if (_paused != r.paused) {
      _paused = r.paused;
      changed = true;
    }
    if (changed) unawaited(_persistModules());
    if (r.finished && _stage != ExamStage.completed) {
      unawaited(_endLocally());
    }
    if (r.unlock) onRemoteUnlock?.call();
    notifyListeners();
  }

  // ---- Navigation --------------------------------------------------------------------

  void selectPart(int partId) {
    if (_currentPartId == partId) return;
    _set(() {
      _currentPartId = partId;
      _activeQuestionId = null;
    });
  }

  void stepPart(int delta) {
    final parts = currentModule?.parts ?? const [];
    final i = parts.indexWhere((p) => p.id == _currentPartId);
    final j = i + delta;
    if (i >= 0 && j >= 0 && j < parts.length) selectPart(parts[j].id);
  }

  void setActiveQuestion(int? id) => _set(() => _activeQuestionId = id);

  void toggleFlag(int questionId) => _set(() {
        if (!_flagged.remove(questionId)) _flagged.add(questionId);
      });

  // ---- Answers -----------------------------------------------------------------------

  /// Records an answer. Text answers are debounced (600 ms, like the web);
  /// option answers are queued immediately. The UI updates at once either way.
  void setAnswer({
    required int partId,
    required int questionId,
    String? text,
    List<int> optionIds = const [],
    bool debounce = false,
  }) {
    if (inputsLocked || _attemptId == null) return;
    final normalizedText = text == null || text.trim().isEmpty ? null : text;
    _answers[questionId] = SavedAnswer(text: normalizedText, optionIds: optionIds);
    final change = _PendingChange(partId, normalizedText, List.of(optionIds), clock.now());
    _pendingChanges[questionId] = change;
    _debounces[questionId]?.cancel();
    if (debounce) {
      _debounces[questionId] = Timer(const Duration(milliseconds: 600), () {
        _debounces.remove(questionId);
        unawaited(_commit(questionId));
      });
    } else {
      unawaited(_commit(questionId));
    }
    notifyListeners();
  }

  Future<void> _commit(int questionId) async {
    final c = _pendingChanges.remove(questionId);
    final attempt = _attemptId;
    if (c == null || attempt == null) return;
    await answerQueue.enqueue(
      attemptId: attempt,
      partId: c.partId,
      questionId: questionId,
      text: c.text?.trim(),
      optionIds: c.optionIds,
      changedAt: c.changedAt,
    );
    sync.kick();
  }

  /// Commits every debounced change right away.
  Future<void> flushPending() async {
    for (final t in _debounces.values) {
      t.cancel();
    }
    _debounces.clear();
    for (final id in _pendingChanges.keys.toList()) {
      await _commit(id);
    }
  }

  // ---- Submitting -------------------------------------------------------------------

  Future<void> confirmFinishModule() => _submitModule(auto: false);

  Future<int> _drainQueue({Duration timeout = const Duration(seconds: 20)}) async {
    final token = _token;
    final attempt = _attemptId;
    if (token == null || attempt == null) return 0;
    try {
      return await answerQueue.drain(api, token, attempt).timeout(timeout);
    } on ApiException catch (e) {
      // 409 attempt_finished: the server refuses every further answer batch.
      if (e.code == ApiErrorCode.attemptFinished) return 0;
      connection.reportFailure(e);
      return answerQueue.pendingCount(attemptId: attempt);
    } catch (e) {
      connection.reportFailure(e);
      return answerQueue.pendingCount(attemptId: attempt);
    }
  }

  Future<void> _submitModule({required bool auto}) async {
    final m = currentModule;
    if (m == null || _finishing) return;
    _set(() => _finishing = true);
    try {
      await flushPending();
      await _drainQueue();
      while (true) {
        try {
          await api.submitModule(_token!, m.typeId);
          break;
        } on ApiException catch (e) {
          if (e.code == ApiErrorCode.attemptFinished) {
            await _endLocally();
            return;
          }
          if (e.code == ApiErrorCode.moduleTimeOver ||
              e.code == ApiErrorCode.validationFailed ||
              e.code == ApiErrorCode.moduleLocked) {
            break; // already finished (or never started) on the server
          }
          if (e.code == ApiErrorCode.unauthenticated) {
            await _endLocally();
            return;
          }
          _set(() {
            _stage = ExamStage.transition;
            _transitionMessage = e.code == ApiErrorCode.paused
                ? 'The exam is paused by the invigilator. Please wait.'
                : 'Saving ${m.title}… waiting for the connection.\nYour answers are saved on this computer.';
          });
          await Future<void>.delayed(const Duration(seconds: 3));
          await _drainQueue(timeout: const Duration(seconds: 10));
        }
      }
      _modules[_moduleIndex] = _modules[_moduleIndex].copyWith(status: ModuleStatus.submitted);
      await _persistModules();
      await _afterModuleSubmitted();
    } finally {
      _finishing = false;
      notifyListeners();
    }
  }

  Future<void> _afterModuleSubmitted() async {
    await _advance();
  }

  Future<void> _advance() async {
    _moduleIndex = _modules.indexWhere((m) => !m.isSubmitted);
    if (_moduleIndex < 0) {
      _moduleIndex = _modules.length;
      await _finalSubmit();
      return;
    }
    await _enterModule();
  }

  /// Final submit: only after the answer queue is empty, or after a 5 minute
  /// grace while offline (then the background sync delivers it later).
  Future<void> _finalSubmit() async {
    final attempt = _attemptId;
    final token = _token;
    if (attempt == null || token == null) return;
    _stopTimers();
    _set(() {
      _stage = ExamStage.transition;
      _transitionMessage = 'Finishing your exam…';
    });
    await flushPending();
    final deadline = DateTime.now().add(AppConfig.offlineSubmitGrace);
    var left = await _drainQueue();
    while (left > 0 && DateTime.now().isBefore(deadline)) {
      _set(() => _transitionMessage =
          'Finishing your exam… sending $left saved answer(s).\nPlease wait, do not turn off the computer.');
      await Future<void>.delayed(const Duration(seconds: 3));
      left = await _drainQueue(timeout: const Duration(seconds: 10));
    }
    var submitted = false;
    if (left == 0) {
      try {
        await violationQueue.syncOnce(api, token, attempt);
      } catch (_) {}
      while (true) {
        try {
          await api.submitExam(token);
          submitted = true;
        } on ApiException catch (e) {
          submitted = e.code == ApiErrorCode.attemptFinished ||
              e.code == ApiErrorCode.unauthenticated;
          if (e.code == ApiErrorCode.paused) {
            _set(() => _transitionMessage = 'The exam is paused by the invigilator. Please wait.');
            await Future<void>.delayed(const Duration(seconds: 5));
            continue;
          }
        }
        break;
      }
    }
    await db.markSession(attempt, completed: true, submitPending: !submitted, closed: submitted);
    if (!submitted) sync.kick();
    _stage = ExamStage.completed;
    _transitionMessage = null;
    notifyListeners();
  }

  /// Ends the exam on this PC without a final submit (force-submitted by an
  /// admin, attempt already finished, or token revoked).
  Future<void> _endLocally() async {
    final attempt = _attemptId;
    final token = _token;
    _stopTimers();
    await flushPending();
    if (attempt != null) {
      // Force-submitted attempts keep the token valid until /exam/submit,
      // which then answers `completed` and revokes it.
      var closed = false;
      if (token != null) {
        try {
          await api.submitExam(token);
          closed = true;
        } on ApiException catch (e) {
          closed = e.code == ApiErrorCode.attemptFinished || e.code == ApiErrorCode.unauthenticated;
        }
      }
      await db.markSession(attempt, completed: true, closed: closed);
      sync.kick();
    }
    _set(() => _stage = ExamStage.completed);
  }

  /// Called by the Completed screen after 10 s.
  void returnToCodeScreen() {
    _resetSession();
    _set(() => _stage = ExamStage.idle);
  }

  void _resetSession() {
    _stopTimers();
    for (final t in _debounces.values) {
      t.cancel();
    }
    _debounces.clear();
    _pendingChanges.clear();
    _attemptId = null;
    _token = null;
    _candidateName = '';
    _candidateCode = '';
    _cached = null;
    _modules = const [];
    _moduleIndex = 0;
    _parts.clear();
    _answers.clear();
    _flagged.clear();
    _currentPartId = null;
    _activeQuestionId = null;
    _paused = false;
    _finishing = false;
    _error = null;
    _transitionMessage = null;
  }

  void clearError() => _set(() {
        _error = null;
        _updateRequired = false;
      });

  // ---- Violations --------------------------------------------------------------------

  bool get examActive =>
      _attemptId != null &&
      (_stage == ExamStage.rules ||
          _stage == ExamStage.soundCheck ||
          _stage == ExamStage.exam ||
          _stage == ExamStage.transition);

  Future<void> reportViolation(String type, [Map<String, Object?>? detail]) => _violation(type, detail);

  Future<void> _violation(String type, [Map<String, Object?>? detail]) async {
    final attempt = _attemptId;
    if (attempt == null) return;
    await violationQueue.enqueue(
      attemptId: attempt,
      type: type,
      detail: detail,
      occurredAt: clock.now(),
    );
    sync.kick();
  }

  @override
  void dispose() {
    _stopTimers();
    for (final t in _debounces.values) {
      t.cancel();
    }
    super.dispose();
  }
}

class _PendingChange {
  _PendingChange(this.partId, this.text, this.optionIds, this.changedAt);
  final int partId;
  final String? text;
  final List<int> optionIds;
  final DateTime changedAt;
}

String _jsonEncode(Object o) => jsonEncode(o);
Object? _jsonDecode(String s) => jsonDecode(s);
