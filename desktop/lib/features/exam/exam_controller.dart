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
import '../sound_check/sound_check_screen.dart' show listeningVolume;

enum ExamStage { idle, prefetching, rules, soundCheck, exam, transition, completed, blocked }

/// Why the exam UI is locked ([ExamStage.blocked]).
enum BlockReason {
  /// 401 `session_revoked` / `session_expired`: the candidate signed in on
  /// another PC or the token ran out. Local answers stay queued; they are
  /// uploaded once the session is restored (admin release + re-login here).
  sessionLost,

  /// 426 during the exam (cannot happen with API v1.1, kept as a safe stop).
  clientOutdated,
}

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
  }) {
    sync.onSessionAuthLost = (id) {
      if (id == _attemptId && examActive) unawaited(_block(BlockReason.sessionLost));
    };
    sync.onPausedDetected = (id) {
      if (id == _attemptId && examActive && !_paused) {
        _setPaused(true);
        unawaited(_sendHeartbeat());
      }
    };
    sync.onSessionClosed = (id) {
      if (id == _attemptId && _stage == ExamStage.completed && !_submitConfirmed) {
        _set(() => _submitConfirmed = true);
      }
    };
  }

  final MynineApi api;
  final AppDatabase db;
  final ServerClock clock;
  final ExamRepository examRepo;
  final AnswerQueueRepository answerQueue;
  final ViolationQueueRepository violationQueue;
  final SyncService sync;
  final DeviceRepository device;
  final ConnectionStatus connection;

  /// Returns true while logging in must wait (an update is being installed).
  bool Function() loginBlocked = () => false;

  /// Zone the controller was created in. Persistence triggered by UI events
  /// runs here, so SQLite writes never depend on the zone of the gesture that
  /// caused them (relevant for widget tests running in a fake-async zone).
  final Zone _zone = Zone.current;

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

  /// A module is being started (guards double taps on Start).
  bool _entering = false;

  /// The final submit is running.
  bool _finalizing = false;

  BlockReason? _blockReason;
  BlockReason? get blockReason => _blockReason;

  /// True only when `POST /exam/submit` (or the server itself) confirmed the
  /// attempt is finished. The Completed screen says "submitted" only then.
  bool _submitConfirmed = false;
  bool get submitConfirmed => _submitConfirmed;

  /// Pause intervals of the attempt in server time (end null = still paused),
  /// tracked locally from the heartbeat (Listening audio position).
  final List<({DateTime start, DateTime? end})> _pauses = [];

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

  /// Candidate-facing text of the locked screen.
  String get blockMessage => switch (_blockReason) {
        BlockReason.clientOutdated =>
          'This app version is no longer accepted by the server.\n'
              'Your answers are saved on this PC. Please call the invigilator.',
        _ => 'Your session was moved or expired — call the invigilator.\n'
            'Your answers are saved on this PC and will be sent when the session is restored.',
      };

  /// Total time the attempt was paused between [from] and now (server time).
  Duration pausedSince(DateTime from) {
    final now = clock.now();
    final start = from.toUtc();
    var total = Duration.zero;
    for (final p in _pauses) {
      final a = p.start.isBefore(start) ? start : p.start;
      final b = p.end ?? now;
      if (b.isAfter(a)) total += b.difference(a);
    }
    return total;
  }

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
    if (_stage != ExamStage.idle && _stage != ExamStage.blocked) return;
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) {
      _set(() => _error = 'Please enter your exam code.');
      return;
    }
    final before = _stage;
    _set(() {
      _busy = true;
      _error = null;
      _updateRequired = false;
    });
    try {
      if (!device.isRegistered) {
        _error = 'This PC is not set up yet. Please ask the reception.';
        return;
      }
      if (loginBlocked()) {
        _error = 'An update is being installed. Please wait a moment.';
        return;
      }
      LoginResponse login;
      try {
        login = await api.login(trimmed);
      } on ApiException catch (e) {
        // 401 here can only mean the device token (no exam token yet): the
        // server no longer knows this PC. Staff must set it up again with the
        // center password (Setup screen) — never re-register automatically.
        if (e.code == ApiErrorCode.unauthenticated) {
          await device.forgetRegistration();
          _error = 'This PC must be set up again. Please ask the reception.';
          return;
        }
        rethrow;
      }
      device.markApproved();
      final previous = _attemptId;
      if (previous != null && previous != login.attemptId) {
        // Another candidate on a locked PC: the lost session keeps its queue
        // (sent if it is ever restored) but is no longer resumed here.
        await db.markSession(previous, completed: true);
      }
      if (previous != login.attemptId) {
        // New candidate: fresh audio volume and view settings.
        listeningVolume.value = 100;
      }
      _stopTimers();
      // Same attempt again (session restored): the token is replaced and the
      // queued answers are delivered with it.
      await db.upsertSession(ExamSessionsCompanion.insert(
        attemptId: Value(login.attemptId),
        token: login.token,
        candidateName: login.candidate.name,
        candidateCode: login.candidate.code,
        mockName: Value(login.mock.name),
        expiresAt: Value(login.expiresAt),
        submitPending: const Value(false),
        completed: const Value(false),
        closed: const Value(false),
        authLost: const Value(false),
      ));
      _attemptId = login.attemptId;
      _token = login.token;
      _candidateName = login.candidate.name;
      _candidateCode = login.candidate.code;
      _blockReason = null;
      _submitConfirmed = false;
      sync.kick();
      await _prefetchAndOpen();
    } on ApiException catch (e) {
      _error = e.userMessage;
      device.noteApproval(e);
      if (e.code == ApiErrorCode.deviceNotApproved) {
        _error = device.notApprovedMessage;
      }
      if (e.code == ApiErrorCode.clientOutdated) _updateRequired = true;
      if (_stage == ExamStage.prefetching) _stage = before;
    } catch (e) {
      _error = 'Something went wrong. Please try again.';
      debugPrint('login failed: $e');
      if (_stage == ExamStage.prefetching) _stage = before;
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
    await _enterFirstStage();
  }

  /// Opens the stage for the current module. When every module is already
  /// submitted (e.g. the app stopped between the last module and the final
  /// submit) the final submit is sent now.
  Future<void> _enterFirstStage() async {
    final m = currentModule;
    if (m == null) {
      await _finalSubmit();
      return;
    }
    // Resuming a module that is already running: straight back in.
    _stage = m.isInProgress ? ExamStage.exam : ExamStage.rules;
    notifyListeners();
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
    _flagged
      ..clear()
      ..addAll(await _loadFlags());
    await _loadPauses();
    if (currentModule?.isInProgress ?? false) _startTimers();
  }

  static String _flagsKey(int attemptId) => 'flags:$attemptId';
  static String _pausesKey(int attemptId) => 'pauses:$attemptId';

  Future<Set<int>> _loadFlags() async {
    final id = _attemptId;
    if (id == null) return {};
    try {
      final raw = await db.getCache(_flagsKey(id));
      if (raw == null) return {};
      return {for (final v in _jsonDecode(raw) as List) (v as num).toInt()};
    } catch (_) {
      return {};
    }
  }

  void _persistFlags() {
    final id = _attemptId;
    if (id == null) return;
    final json = _jsonEncode(_flagged.toList());
    _zone.run(() => unawaited(db.putCache(_flagsKey(id), json)));
  }

  Future<void> _loadPauses() async {
    _pauses.clear();
    final id = _attemptId;
    if (id == null) return;
    try {
      final raw = await db.getCache(_pausesKey(id));
      if (raw == null) return;
      for (final e in _jsonDecode(raw) as List) {
        final m = e as Map;
        final start = DateTime.tryParse(m['start']?.toString() ?? '');
        if (start == null) continue;
        _pauses.add((start: start.toUtc(), end: DateTime.tryParse(m['end']?.toString() ?? '')?.toUtc()));
      }
    } catch (_) {}
  }

  void _persistPauses() {
    final id = _attemptId;
    if (id == null) return;
    final json = _jsonEncode([
      for (final p in _pauses) {'start': p.start.toIso8601String(), 'end': p.end?.toIso8601String()},
    ]);
    _zone.run(() => unawaited(db.putCache(_pausesKey(id), json)));
  }

  /// Updates the pause state and the locally tracked pause intervals.
  void _setPaused(bool value) {
    if (_paused == value) return;
    _paused = value;
    final now = clock.now();
    if (value) {
      if (_pauses.isEmpty || _pauses.last.end != null) _pauses.add((start: now, end: null));
    } else if (_pauses.isNotEmpty && _pauses.last.end == null) {
      _pauses[_pauses.length - 1] = (start: _pauses.last.start, end: now);
    }
    _persistPauses();
    notifyListeners();
  }

  /// Resumes an unfinished session after an app restart / crash.
  Future<bool> resumeIfNeeded() async {
    if (_busy || _stage != ExamStage.idle) return false;
    _busy = true;
    try {
      return await _resume();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> _resume() async {
    final s = await db.activeSession();
    if (s == null) return false;
    // The token's local expiry is not checked: the heartbeat extends it on
    // the server (API v1.1), which answers 401 when it really ran out.
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
    var authLost = s.authLost;
    bool? paused; // null: unknown (offline)
    if (!authLost) {
      try {
        final state = await api.examState(s.token);
        if (state.attempt.finished) {
          await db.markSession(s.attemptId, completed: true);
          sync.kick();
          _resetSession();
          return false;
        }
        modules = state.modules;
        paused = state.attempt.paused;
      } on ApiException catch (e) {
        if (e.isAuthLost) {
          authLost = true;
          await db.markSession(s.attemptId, authLost: true);
        } else {
          // Offline: continue from the cache (timers keep the cached finished_at).
          final saved = await db.getCache(_modulesKey(s.attemptId));
          if (saved != null) modules = _decodeModules(saved) ?? modules;
        }
      }
    }
    await _open(cached, modules);
    if (authLost) {
      _stopTimers();
      _blockReason = BlockReason.sessionLost;
      _stage = ExamStage.blocked;
      notifyListeners();
      return true;
    }
    if (paused != null) {
      _setPaused(paused);
    } else if (_pauses.isNotEmpty && _pauses.last.end == null) {
      _paused = true; // last known state: still paused
    }
    await _violation(ViolationType.appRestarted);
    await _enterFirstStage();
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
    if (m == null || _stage != ExamStage.rules || _entering) return;
    if (m.isListening && m.isNotStarted) {
      _set(() => _stage = ExamStage.soundCheck);
    } else {
      unawaited(_enterModule());
    }
  }

  void confirmSoundCheck() {
    if (_stage != ExamStage.soundCheck || _entering) return;
    unawaited(_enterModule());
  }

  Future<void> _enterModule() async {
    if (_entering) return;
    _entering = true;
    try {
      await _enterModuleImpl();
    } finally {
      _entering = false;
    }
  }

  Future<void> _enterModuleImpl() async {
    final m = currentModule;
    if (m == null) {
      await _finalSubmit();
      return;
    }
    if (m.isSubmitted) {
      _entering = false;
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
            _entering = false;
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
            _entering = false;
            await _advance();
            return;
          }
          if (e.isAuthLost) {
            await _block(BlockReason.sessionLost);
            return;
          }
          if (e.code == ApiErrorCode.clientOutdated) {
            await _block(BlockReason.clientOutdated);
            return;
          }
          if (e.code == ApiErrorCode.paused) _setPaused(true);
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
    _startHeartbeat();
  }

  void _startHeartbeat() {
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
    if (token == null || _stage == ExamStage.blocked) return;
    try {
      final r = await api.examHeartbeat(
        token,
        typeId: currentModule?.typeId,
        partId: _currentPartId,
        queuedAnswers: await answerQueue.pendingCount(attemptId: _attemptId),
        queuedViolations: await violationQueue.pendingCount(attemptId: _attemptId),
        onlineSince: connection.onlineSince,
      );
      if (token != _token) return; // another session meanwhile
      connection.reportSuccess();
      if (r.expiresAt != null && _attemptId != null) {
        final id = _attemptId!;
        final expires = r.expiresAt;
        _zone.run(() => unawaited(() async {
              try {
                await db.setSessionExpiry(id, expires);
              } catch (_) {}
            }()));
      }
      applyHeartbeat(r);
    } on ApiException catch (e) {
      if (token != _token) return;
      connection.reportFailure(e);
      if (e.code == ApiErrorCode.attemptFinished) {
        if (!_finalizing) await _endLocally();
      } else if (e.isAuthLost) {
        // During the final submit the token is revoked by the submit itself;
        // the submit loop handles a refused token on its own.
        if (!_finalizing) await _block(BlockReason.sessionLost);
      } else if (e.code == ApiErrorCode.clientOutdated) {
        await _block(BlockReason.clientOutdated);
      }
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
      _setPaused(r.paused);
      if (!r.paused) sync.kick(); // deferred answers go out right after the resume
    }
    if (changed) unawaited(_persistModules());
    if (r.finished && _stage != ExamStage.completed && !_finalizing && _stage != ExamStage.blocked) {
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

  void toggleFlag(int questionId) {
    _set(() {
      if (!_flagged.remove(questionId)) _flagged.add(questionId);
    });
    _persistFlags();
  }

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
    if (text != null && text.length > kMaxAnswerChars) text = text.substring(0, kMaxAnswerChars);
    final normalizedText = text == null || text.trim().isEmpty ? null : text;
    _answers[questionId] = SavedAnswer(text: normalizedText, optionIds: optionIds);
    final change = _PendingChange(partId, normalizedText, List.of(optionIds), clock.now());
    _pendingChanges[questionId] = change;
    _debounces[questionId]?.cancel();
    if (debounce) {
      _debounces[questionId] = Timer(const Duration(milliseconds: 600), () {
        _debounces.remove(questionId);
        _zone.run(() => unawaited(_commit(questionId)));
      });
    } else {
      _zone.run(() => unawaited(_commit(questionId)));
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
      final r = await answerQueue.drainDetailed(api, token, attempt).timeout(timeout);
      if (r.deferred > 0 && !_paused) _setPaused(true);
      return r.remaining;
    } on ApiException catch (e) {
      // 409 attempt_finished: the server refuses every further answer batch.
      if (e.code == ApiErrorCode.attemptFinished) return 0;
      if (e.isAuthLost) throw _SessionLost();
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
        if (_stage == ExamStage.blocked || _token == null) return;
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
          if (e.isAuthLost) {
            await _block(BlockReason.sessionLost);
            return;
          }
          if (e.code == ApiErrorCode.clientOutdated) {
            await _block(BlockReason.clientOutdated);
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
      _finishing = false;
      await _afterModuleSubmitted();
    } on _SessionLost {
      await _block(BlockReason.sessionLost);
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
  /// grace while offline (then the background sync delivers it later). The
  /// grace does not run while the attempt is paused. "Completed" says
  /// "submitted" only when the server confirmed it.
  Future<void> _finalSubmit() async {
    final attempt = _attemptId;
    final token = _token;
    if (attempt == null || token == null || _finalizing) return;
    _finalizing = true;
    try {
      await _finalSubmitImpl(attempt, token);
    } on _SessionLost {
      await _block(BlockReason.sessionLost);
    } finally {
      _finalizing = false;
    }
  }

  Future<void> _finalSubmitImpl(int attempt, String token) async {
    // The heartbeat keeps running (pause / resume must still be seen).
    _ticker?.cancel();
    _ticker = null;
    if (_heartbeat == null) _startHeartbeat();
    _set(() {
      _stage = ExamStage.transition;
      _transitionMessage = 'Finishing your exam…';
    });
    await flushPending();
    var deadline = DateTime.now().add(AppConfig.offlineSubmitGrace);
    var left = await _drainQueue();
    while (left > 0) {
      if (_paused) {
        deadline = DateTime.now().add(AppConfig.offlineSubmitGrace);
        _set(() => _transitionMessage = 'The exam is paused by the invigilator. Please wait.\n'
            'Your answers are saved on this computer.');
      } else if (!DateTime.now().isBefore(deadline)) {
        break;
      } else {
        _set(() => _transitionMessage =
            'Finishing your exam… sending $left saved answer(s).\nPlease wait, do not turn off the computer.');
      }
      await Future<void>.delayed(const Duration(seconds: 3));
      if (_stage == ExamStage.blocked || _token != token) return;
      left = await _drainQueue(timeout: const Duration(seconds: 10));
    }
    var submitted = false;
    if (left == 0) {
      // Violations are best effort: never block the submit.
      try {
        await violationQueue.syncOnce(api, token, attempt).timeout(const Duration(seconds: 10));
      } catch (_) {}
      while (true) {
        try {
          await api.submitExam(token);
          submitted = true;
        } on ApiException catch (e) {
          if (e.code == ApiErrorCode.attemptFinished) {
            submitted = true;
          } else if (e.isAuthLost) {
            throw _SessionLost();
          } else if (e.code == ApiErrorCode.paused) {
            _setPaused(true);
            _set(() => _transitionMessage = 'The exam is paused by the invigilator. Please wait.');
            await Future<void>.delayed(const Duration(seconds: 5));
            if (_stage == ExamStage.blocked || _token != token) return;
            continue;
          }
        }
        break;
      }
    }
    _stopTimers();
    await db.markSession(attempt, completed: true, submitPending: !submitted, closed: submitted);
    if (!submitted) sync.kick();
    _submitConfirmed = submitted;
    _stage = ExamStage.completed;
    _transitionMessage = null;
    notifyListeners();
  }

  /// Ends the exam on this PC without a final submit of our own: the server
  /// already finished the attempt (force-submitted by an admin, or
  /// `attempt_finished`). A force-submitted attempt keeps its token valid
  /// until `/exam/submit`, which then answers `completed` and revokes it.
  Future<void> _endLocally() async {
    final attempt = _attemptId;
    final token = _token;
    _stopTimers();
    await flushPending();
    if (attempt != null) {
      var closed = false;
      if (token != null) {
        try {
          await api.submitExam(token);
          closed = true;
        } on ApiException catch (e) {
          closed = e.code == ApiErrorCode.attemptFinished || e.isAuthLost;
        }
      }
      await db.markSession(attempt, completed: true, closed: closed, submitPending: !closed);
      sync.kick();
    }
    _submitConfirmed = true; // the server reported the attempt as finished
    _set(() => _stage = ExamStage.completed);
  }

  /// Locks the exam UI (session revoked / expired, or an outdated client).
  /// Nothing is dropped: the answer queue stays on this PC.
  Future<void> _block(BlockReason reason) async {
    if (_stage == ExamStage.blocked ||
        _stage == ExamStage.completed ||
        _stage == ExamStage.idle ||
        _attemptId == null) {
      return;
    }
    _stopTimers();
    // Debounced edits are kept too.
    for (final t in _debounces.values) {
      t.cancel();
    }
    _debounces.clear();
    for (final id in _pendingChanges.keys.toList()) {
      await _commit(id);
    }
    if (reason == BlockReason.sessionLost) {
      await db.markSession(_attemptId!, authLost: true);
    }
    _finishing = false;
    _blockReason = reason;
    _transitionMessage = null;
    _set(() => _stage = ExamStage.blocked);
  }

  /// Called by the Completed screen after 10 s (or by staff from the admin
  /// menu). The session is marked completed so a restart never shows this
  /// candidate's screens again; queued data keeps syncing in the background.
  void returnToCodeScreen() {
    final attempt = _attemptId;
    if (attempt != null && (_stage == ExamStage.completed || _stage == ExamStage.blocked)) {
      _zone.run(() => unawaited(db.markSession(attempt, completed: true)));
    }
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
    _pauses.clear();
    _finishing = false;
    _entering = false;
    _blockReason = null;
    _submitConfirmed = false;
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
          _stage == ExamStage.transition ||
          _stage == ExamStage.blocked);

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

  bool _disposed = false;

  /// Async work (heartbeats, syncs) can complete after dispose: ignore it.
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stopTimers();
    for (final t in _debounces.values) {
      t.cancel();
    }
    super.dispose();
  }
}

/// Internal signal: the exam token was refused while submitting.
class _SessionLost implements Exception {}

class _PendingChange {
  _PendingChange(this.partId, this.text, this.optionIds, this.changedAt);
  final int partId;
  final String? text;
  final List<int> optionIds;
  final DateTime changedAt;
}

String _jsonEncode(Object o) => jsonEncode(o);
Object? _jsonDecode(String s) => jsonDecode(s);
