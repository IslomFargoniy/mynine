import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../data/models/app_models.dart';
import '../../data/models/exam_models.dart';
import '../../data/models/part_payload.dart';
import '../crypto/pbkdf2.dart';
import '../time/server_clock.dart';
import 'api_exception.dart';
import 'mynine_api.dart';

/// In-memory implementation of [MynineApi] for `--dart-define=API_FAKE=true`
/// demo mode and for tests. Behaves like the contract in API.md: codes
/// starting with `DEMO` log in, module order is enforced, answers are
/// idempotent per `client_uuid` and last-write-wins by `changed_at`.
///
/// Demo exit password: `mynine`.
class FakeMynineApi implements MynineApi {
  FakeMynineApi({
    required this.clock,
    this.appVersionString = '1.0.0',
    this.offerUpdate = false,
    this.latency = const Duration(milliseconds: 150),
    this.listeningSeconds = 10 * 60,
    this.readingSeconds = 20 * 60,
    this.writingSeconds = 20 * 60,
    this.audioSeconds = 90,
    DateTime Function()? now,
  }) : _now = now ?? (() => DateTime.now().toUtc());

  static const exitPassword = 'mynine';

  final ServerClock clock;
  final String appVersionString;
  final bool offerUpdate;
  final Duration latency;
  final int listeningSeconds;
  final int readingSeconds;
  final int writingSeconds;
  final int audioSeconds;
  final DateTime Function() _now;

  /// When true every call fails with a network error.
  bool offline = false;

  /// When false, login and device config answer 403 `device_not_approved`.
  bool approved = true;

  void _requireApproved() {
    if (!approved) {
      throw ApiException(
        code: ApiErrorCode.deviceNotApproved,
        statusCode: 403,
        message: 'This PC is waiting for administrator approval: PC-DEMO',
      );
    }
  }

  /// Number of upcoming `sendAnswers` calls that fail with a network error.
  int failNextAnswerCalls = 0;

  /// Request log (method names), for tests.
  final List<String> calls = [];

  /// Applied answers per question: (changedAt, text, optionIds).
  final Map<int, ({DateTime changedAt, String? text, List<int> optionIds})> savedAnswers = {};
  final Set<String> appliedUuids = {};
  final List<ViolationItem> receivedViolations = [];
  bool examSubmitted = false;
  bool paused = false;
  bool forceFinished = false;
  bool unlockRequested = false;

  String? _token;
  final Map<int, DateTime> _started = {};
  final Map<int, DateTime> _finished = {};
  final Set<int> _submitted = {};
  String? _offlineHash;
  Uint8List? _audioBytes;
  Uint8List? _installerBytes;

  static const attemptId = 55;

  Future<void> _io(String name) async {
    calls.add(name);
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (offline) throw ApiException(code: ApiErrorCode.network, message: 'offline (fake)');
  }

  DateTime get _serverNow => _now();

  void _tick() => clock.update(_serverNow);

  void _requireToken(String token) {
    if (token != _token) {
      throw ApiException(code: ApiErrorCode.unauthenticated, statusCode: 401);
    }
  }

  // ---- App -------------------------------------------------------------------

  String get _nextVersion {
    final parts = appVersionString.split('.').map(int.parse).toList();
    return '${parts[0]}.${parts[1]}.${parts[2] + 1}';
  }

  /// Overrides the generated manifest (tests); null = default demo manifest.
  UpdateManifest? manifestOverride;

  /// When true, `version.json` answers 404 (file not uploaded yet).
  bool manifestMissing = false;

  /// File names served from the fake static update folder
  /// (`fake://desktop/<file>`); others answer 404.
  final List<String> downloadedFiles = [];

  @override
  String updateFileUrl(String fileName) => 'fake://desktop/$fileName';

  @override
  Future<UpdateManifest> updateManifest() async {
    await _io('updateManifest');
    if (manifestMissing) {
      throw ApiException(code: ApiErrorCode.notFound, statusCode: 404, message: 'Not Found');
    }
    if (manifestOverride != null) return manifestOverride!;
    final bytes = _installer();
    final version = offerUpdate ? _nextVersion : appVersionString;
    return UpdateManifest(
      version: version,
      file: 'mynine-setup-$version.exe',
      sha256: sha256.convert(bytes).toString(),
      size: bytes.length,
      mandatory: false,
      minVersion: null,
      notes: offerUpdate ? 'Demo update: improved timer display.' : 'Current release.',
      publishedAt: _serverNow,
    );
  }

  Uint8List _installer() => _installerBytes ??=
      Uint8List.fromList(List<int>.generate(256 * 1024, (i) => (i * 31 + 7) & 0xff));

  // ---- Device ----------------------------------------------------------------

  @override
  Future<DeviceRegistration> registerDevice({
    required String machineId,
    required String name,
    required String osVersion,
    required String appVersion,
  }) async {
    await _io('registerDevice');
    return DeviceRegistration(deviceId: 7, deviceToken: 'fake-device-token', name: name);
  }

  @override
  Future<DeviceHeartbeat> deviceHeartbeat({
    required String appVersion,
    required DeviceState state,
  }) async {
    await _io('deviceHeartbeat');
    _tick();
    return DeviceHeartbeat(serverTime: _serverNow, unlock: false);
  }

  @override
  Future<bool> deviceUnlock(String password) async {
    await _io('deviceUnlock');
    return password == exitPassword;
  }

  /// Offline hash of [exitPassword] (fewer iterations to keep the demo fast).
  String get offlineHash {
    if (_offlineHash != null) return _offlineHash!;
    final salt = utf8.encode('fake-salt-1234');
    final hash = pbkdf2Sha256(
      password: utf8.encode(exitPassword),
      salt: salt,
      iterations: 2000,
      keyLength: 32,
    );
    return _offlineHash =
        'pbkdf2_sha256\$2000\$${base64.encode(salt)}\$${base64.encode(hash)}';
  }

  @override
  Future<DeviceConfig> deviceConfig() async {
    await _io('deviceConfig');
    _requireApproved();
    _tick();
    return DeviceConfig(
      exitPasswordOffline: offlineHash,
      bannedProcesses: const ['anydesk.exe', 'teamviewer.exe', 'discord.exe', 'obs64.exe', 'telegram.exe'],
      heartbeatSeconds: 20,
      violationBatchSeconds: 10,
      serverTime: _serverNow,
    );
  }

  // ---- Exam auth -------------------------------------------------------------

  @override
  Future<LoginResponse> login(String code) async {
    await _io('login');
    _requireApproved();
    final c = code.trim().toUpperCase();
    if (!c.startsWith('DEMO')) {
      throw ApiException(
        code: ApiErrorCode.invalidCode,
        statusCode: 422,
        message: 'Invalid code',
      );
    }
    if (examSubmitted) {
      throw ApiException(code: ApiErrorCode.attemptFinished, statusCode: 409);
    }
    _token = 'fake-exam-token-${_serverNow.millisecondsSinceEpoch}';
    _tick();
    return LoginResponse(
      token: _token!,
      expiresAt: _serverNow.add(const Duration(hours: 6)),
      candidate: Candidate(id: 12, name: 'Demo Candidate', code: c),
      mock: MockInfo(
        id: 3,
        name: 'Demo Mock',
        startsAt: _serverNow.subtract(const Duration(minutes: 5)),
        endsAt: _serverNow.add(const Duration(hours: 4)),
      ),
      attemptId: attemptId,
      serverTime: _serverNow,
    );
  }

  @override
  Future<void> logout(String examToken) async {
    await _io('logout');
    _token = null;
  }

  // ---- Exam ------------------------------------------------------------------

  List<ExamModule> _modules() {
    ExamModule module(int typeId, String type, String title, int seconds, List<PartPayload> parts,
        {ModuleAudio? audio}) {
      final started = _started[typeId];
      final finished = _finished[typeId];
      var status = ModuleStatus.notStarted;
      if (_submitted.contains(typeId)) {
        status = ModuleStatus.submitted;
      } else if (started != null) {
        status = ModuleStatus.inProgress;
      }
      return ExamModule(
        typeId: typeId,
        type: type,
        title: title,
        durationSeconds: seconds,
        status: status,
        startedAt: started,
        finishedAt: finished,
        audio: audio,
        parts: [
          for (final p in parts)
            PartSummary(
              id: p.id,
              name: p.name,
              order: p.order,
              questionCount: p.allQuestions.fold(0, (s, q) => s + q.answerCount),
              firstQuestionNumber: p.firstQuestionNumber,
            ),
        ],
      );
    }

    return [
      module(1, 'listening', 'Listening', listeningSeconds, _listeningParts(),
          audio: ModuleAudio(url: 'fake://audio/test/9', durationSeconds: audioSeconds)),
      module(2, 'reading', 'Reading', readingSeconds, _readingParts()),
      module(3, 'writing', 'Writing', writingSeconds, _writingParts()),
    ];
  }

  List<PartPayload> _allParts() => [..._listeningParts(), ..._readingParts(), ..._writingParts()];

  PartPayload _withAnswers(PartPayload p) => p.copyWith(
        sections: [
          for (final s in p.sections)
            s.copyWith(questions: [
              for (final q in s.questions)
                q.copyWith(
                  answer: savedAnswers[q.id] == null
                      ? const SavedAnswer()
                      : SavedAnswer(
                          text: savedAnswers[q.id]!.text,
                          optionIds: savedAnswers[q.id]!.optionIds,
                        ),
                ),
            ]),
        ],
      );

  void _autoFinishExpired() {
    for (final entry in _finished.entries) {
      if (!_serverNow.isBefore(entry.value)) _submitted.add(entry.key);
    }
  }

  @override
  Future<ExamState> examState(String examToken) async {
    await _io('examState');
    _requireToken(examToken);
    _autoFinishExpired();
    _tick();
    return ExamState(
      attempt: AttemptInfo(
        id: attemptId,
        status: examSubmitted ? 'completed' : 'in_progress',
        paused: paused,
        finished: examSubmitted || forceFinished,
      ),
      modules: _modules(),
      serverTime: _serverNow,
    );
  }

  @override
  Future<PrefetchPayload> prefetch(String examToken) async {
    await _io('prefetch');
    _requireToken(examToken);
    _autoFinishExpired();
    _tick();
    final audio = _audio();
    return PrefetchPayload(
      modules: _modules(),
      parts: _allParts().map(_withAnswers).toList(),
      audio: [
        AudioAsset(
          key: 'test-9',
          url: 'fake://audio/test/9',
          size: audio.length,
          sha256: sha256.convert(audio).toString(),
        ),
      ],
      images: const [],
      serverTime: _serverNow,
    );
  }

  @override
  Future<PartPayload> part(String examToken, int partId) async {
    await _io('part');
    _requireToken(examToken);
    final p = _allParts().where((p) => p.id == partId).firstOrNull;
    if (p == null) throw ApiException(code: ApiErrorCode.unknown, statusCode: 403);
    return _withAnswers(p);
  }

  @override
  Future<ModuleStartResponse> startModule(String examToken, int typeId) async {
    await _io('startModule');
    _requireToken(examToken);
    _autoFinishExpired();
    final modules = _modules();
    final idx = modules.indexWhere((m) => m.typeId == typeId);
    if (idx < 0) throw ApiException(code: ApiErrorCode.validationFailed, statusCode: 422);
    for (var i = 0; i < idx; i++) {
      if (!_submitted.contains(modules[i].typeId)) {
        throw ApiException(code: ApiErrorCode.moduleLocked, statusCode: 409);
      }
    }
    if (_submitted.contains(typeId)) {
      throw ApiException(code: ApiErrorCode.moduleTimeOver, statusCode: 409);
    }
    _started.putIfAbsent(typeId, () => _serverNow);
    _finished.putIfAbsent(
      typeId,
      () => _started[typeId]!.add(Duration(seconds: modules[idx].durationSeconds)),
    );
    _tick();
    return ModuleStartResponse(
      typeId: typeId,
      status: ModuleStatus.inProgress,
      startedAt: _started[typeId],
      finishedAt: _finished[typeId],
      serverTime: _serverNow,
    );
  }

  int? _typeOfPart(int partId) {
    for (final m in _modules()) {
      if (m.parts.any((p) => p.id == partId)) return m.typeId;
    }
    return null;
  }

  @override
  Future<AnswersResponse> sendAnswers(String examToken, List<AnswerItem> answers) async {
    await _io('sendAnswers');
    if (failNextAnswerCalls > 0) {
      failNextAnswerCalls--;
      throw ApiException(code: ApiErrorCode.network, message: 'flaky (fake)');
    }
    _requireToken(examToken);
    final results = <AnswerResult>[];
    for (final a in answers) {
      if (appliedUuids.contains(a.clientUuid)) {
        results.add(AnswerResult(clientUuid: a.clientUuid, status: AnswerResultStatus.duplicate));
        continue;
      }
      final typeId = _typeOfPart(a.partId);
      if (typeId == null) {
        results.add(AnswerResult(
            clientUuid: a.clientUuid, status: AnswerResultStatus.rejected, reason: 'invalid_question'));
        continue;
      }
      if (paused) {
        results.add(AnswerResult(
            clientUuid: a.clientUuid, status: AnswerResultStatus.rejected, reason: 'paused'));
        continue;
      }
      final finished = _finished[typeId];
      final graceOk = finished != null &&
          a.changedAt.isBefore(finished) &&
          _serverNow.isBefore(finished.add(const Duration(seconds: 30)));
      if (_submitted.contains(typeId) && !graceOk) {
        results.add(AnswerResult(
            clientUuid: a.clientUuid, status: AnswerResultStatus.rejected, reason: 'module_submitted'));
        continue;
      }
      final existing = savedAnswers[a.questionId];
      appliedUuids.add(a.clientUuid);
      if (existing != null && existing.changedAt.isAfter(a.changedAt)) {
        results.add(AnswerResult(clientUuid: a.clientUuid, status: AnswerResultStatus.stale));
        continue;
      }
      savedAnswers[a.questionId] =
          (changedAt: a.changedAt, text: a.text, optionIds: List.of(a.optionIds));
      results.add(AnswerResult(clientUuid: a.clientUuid, status: AnswerResultStatus.saved));
    }
    _tick();
    return AnswersResponse(results: results, serverTime: _serverNow);
  }

  @override
  Future<ModuleSubmitResponse> submitModule(String examToken, int typeId) async {
    await _io('submitModule');
    _requireToken(examToken);
    _submitted.add(typeId);
    _tick();
    return ModuleSubmitResponse(typeId: typeId, status: ModuleStatus.submitted, serverTime: _serverNow);
  }

  @override
  Future<ExamSubmitResponse> submitExam(String examToken) async {
    await _io('submitExam');
    _requireToken(examToken);
    examSubmitted = true;
    _token = null;
    _tick();
    return ExamSubmitResponse(status: 'completed', serverTime: _serverNow);
  }

  @override
  Future<ExamHeartbeatResponse> examHeartbeat(
    String examToken, {
    int? typeId,
    int? partId,
    required int queuedAnswers,
    required int queuedViolations,
    DateTime? onlineSince,
  }) async {
    await _io('examHeartbeat');
    _requireToken(examToken);
    _tick();
    return ExamHeartbeatResponse(
      serverTime: _serverNow,
      paused: paused,
      finished: forceFinished,
      unlock: unlockRequested,
      modules: [
        for (final m in _modules())
          ModuleTimer(typeId: m.typeId, status: m.status, finishedAt: m.finishedAt),
      ],
    );
  }

  @override
  Future<ViolationsResponse> sendViolations(String examToken, List<ViolationItem> violations) async {
    await _io('sendViolations');
    _requireToken(examToken);
    receivedViolations.addAll(violations);
    return ViolationsResponse(accepted: violations.length, serverTime: _serverNow);
  }

  @override
  Future<File> download(
    String url,
    File target, {
    String? examToken,
    ProgressCallback? onProgress,
    bool anonymous = false,
  }) async {
    await _io('download');
    if (url.startsWith('fake://desktop/')) downloadedFiles.add(url.substring('fake://desktop/'.length));
    final bytes = url.startsWith('fake://audio') ? _audio() : _installer();
    await target.parent.create(recursive: true);
    const chunk = 64 * 1024;
    final sink = target.openWrite();
    for (var i = 0; i < bytes.length; i += chunk) {
      final end = math.min(i + chunk, bytes.length);
      sink.add(bytes.sublist(i, end));
      onProgress?.call(end, bytes.length);
    }
    await sink.close();
    return target;
  }

  /// A simple WAV (8 kHz, 8-bit mono): a short beep every 2 seconds.
  Uint8List _audio() {
    if (_audioBytes != null) return _audioBytes!;
    const rate = 8000;
    final samples = rate * audioSeconds;
    final data = Uint8List(samples);
    for (var i = 0; i < samples; i++) {
      final t = i / rate;
      final inBeep = (t % 2.0) < 0.25;
      final freq = (t ~/ 2) % 2 == 0 ? 660.0 : 880.0;
      final v = inBeep ? math.sin(2 * math.pi * freq * t) * 60 : 0.0;
      data[i] = (128 + v).round().clamp(0, 255);
    }
    final header = ByteData(44);
    void str(int off, String s) {
      for (var i = 0; i < s.length; i++) {
        header.setUint8(off + i, s.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    header.setUint32(4, 36 + samples, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, 1, Endian.little);
    header.setUint32(24, rate, Endian.little);
    header.setUint32(28, rate, Endian.little);
    header.setUint16(32, 1, Endian.little);
    header.setUint16(34, 8, Endian.little);
    str(36, 'data');
    header.setUint32(40, samples, Endian.little);
    return _audioBytes = Uint8List.fromList([...header.buffer.asUint8List(), ...data]);
  }

  // ---- Demo content ------------------------------------------------------------

  static int _ids = 90000;

  static List<OptionPayload> _opts(List<String> labels) =>
      [for (final l in labels) OptionPayload(id: _ids++, html: l)];

  static List<PartPayload>? _listeningCache;
  static List<PartPayload>? _readingCache;
  static List<PartPayload>? _writingCache;

  static List<PartPayload> _listeningParts() => _listeningCache ??= [
        PartPayload(
          id: 101,
          type: 'listening',
          typeId: 1,
          name: 'Part 1',
          order: 1,
          firstQuestionNumber: 1,
          html: '',
          audioKey: null,
          sections: [
            SectionPayload(
              id: 501,
              questionType: QuestionType.completeSection,
              inputType: 'text',
              html: '<p><strong>Questions 1–6</strong></p>'
                  '<p>Complete the form below. Write <strong>NO MORE THAN TWO WORDS AND/OR A NUMBER</strong> for each answer.</p>'
                  '<table><tbody>'
                  '<tr><th colspan="2">CITY LIBRARY – MEMBERSHIP FORM</th></tr>'
                  '<tr><td>Name:</td><td>Sarah {1}</td></tr>'
                  '<tr><td>Address:</td><td>{2} Street, Brighton</td></tr>'
                  '<tr><td>Postcode:</td><td>{3}</td></tr>'
                  '<tr><td>Date of birth:</td><td>{4} 1994</td></tr>'
                  '</tbody></table>'
                  '<ul><li>Preferred contact: by {5}</li><li>Membership fee: £{6} per year</li></ul>',
              questions: [
                for (var i = 0; i < 6; i++)
                  QuestionPayload(id: 7001 + i, number: 1 + i, order: 1 + i, html: ''),
              ],
            ),
            SectionPayload(
              id: 502,
              questionType: QuestionType.multipleChoice,
              inputType: 'radio',
              html: '<p><strong>Questions 7–10</strong></p><p>Choose the correct letter, <strong>A</strong>, <strong>B</strong> or <strong>C</strong>.</p>',
              questions: [
                QuestionPayload(id: 7007, number: 7, order: 7, html: '<p>The library is closed on</p>',
                    options: _opts(['Mondays.', 'Wednesdays.', 'Sundays.'])),
                QuestionPayload(id: 7008, number: 8, order: 8, html: '<p>New members receive</p>',
                    options: _opts(['a free tote bag.', 'two free DVD rentals.', 'a discount at the café.'])),
                QuestionPayload(id: 7009, number: 9, order: 9, html: '<p>Books can be borrowed for up to</p>',
                    options: _opts(['one week.', 'two weeks.', 'three weeks.'])),
                QuestionPayload(id: 7010, number: 10, order: 10, html: '<p>The children\'s reading club meets</p>',
                    options: _opts(['on Saturday mornings.', 'after school on Fridays.', 'once a month.'])),
              ],
            ),
          ],
        ),
        PartPayload(
          id: 102,
          type: 'listening',
          typeId: 1,
          name: 'Part 2',
          order: 2,
          firstQuestionNumber: 11,
          html: '',
          sections: [
            SectionPayload(
              id: 503,
              questionType: QuestionType.matching,
              inputType: 'select',
              html: '<p><strong>Questions 11–14</strong></p><p>What does the speaker say about each facility? Choose <strong>FOUR</strong> answers from the box and write the correct letter, <strong>A–F</strong>.</p>'
                  '<ul><li>A  recently renovated</li><li>B  only open in summer</li><li>C  needs to be booked</li><li>D  free for residents</li><li>E  temporarily closed</li><li>F  popular with families</li></ul>',
              fromOption: 'A',
              toOption: 'F',
              questions: [
                QuestionPayload(id: 7011, number: 11, order: 11, html: 'Swimming pool'),
                QuestionPayload(id: 7012, number: 12, order: 12, html: 'Tennis courts'),
                QuestionPayload(id: 7013, number: 13, order: 13, html: 'Climbing wall'),
                QuestionPayload(id: 7014, number: 14, order: 14, html: 'Sauna'),
              ],
            ),
            SectionPayload(
              id: 504,
              questionType: QuestionType.multipleResponse,
              inputType: 'checkbox',
              html: '<p><strong>Questions 15–16</strong></p><p>Choose <strong>TWO</strong> letters, <strong>A–E</strong>.</p>',
              questions: [
                QuestionPayload(
                  id: 7015,
                  number: 15,
                  order: 15,
                  answerCount: 2,
                  html: '<p>Which <strong>TWO</strong> things does the speaker recommend bringing?</p>',
                  options: _opts(['a padlock', 'a towel', 'photo ID', 'cash', 'a water bottle']),
                ),
              ],
            ),
            SectionPayload(
              id: 505,
              questionType: QuestionType.dragAndDrop,
              inputType: 'text',
              html: '<p><strong>Questions 17–20</strong></p><p>Complete the notes. Drag the correct word into each gap.</p>'
                  '<p>The new sports centre opens at {17} on weekdays. Parking is available {18} the building. '
                  'Visitors should report to {19} first. The café serves {20} food only.</p>',
              dragOptions: const [
                DragOptionPayload(id: 'd1', label: '6 am'),
                DragOptionPayload(id: 'd2', label: 'behind'),
                DragOptionPayload(id: 'd3', label: 'reception'),
                DragOptionPayload(id: 'd4', label: 'vegetarian'),
                DragOptionPayload(id: 'd5', label: 'opposite'),
                DragOptionPayload(id: 'd6', label: '7 am'),
              ],
              questions: [
                for (var i = 0; i < 4; i++)
                  QuestionPayload(id: 7017 + i, number: 17 + i, order: 17 + i, html: ''),
              ],
            ),
          ],
        ),
      ];

  static const _passage1 = '<h2>The Eiffel Tower</h2>'
      '<p><strong>A</strong> The Eiffel Tower was built for the 1889 World\'s Fair, held to celebrate the centenary of the French Revolution. '
      'Gustave Eiffel\'s company designed and built the tower, although the original idea came from two of his senior engineers, '
      'Maurice Koechlin and Émile Nouguier.</p>'
      '<p><strong>B</strong> Construction began in January 1887 and was completed in just over two years. Around 300 workers joined together '
      '18,038 pieces of wrought iron using some 2.5 million rivets. Remarkably, only one worker died during the construction.</p>'
      '<p><strong>C</strong> At first, many leading artists and intellectuals opposed the tower, calling it useless and monstrous. '
      'A petition was published in the newspaper <em>Le Temps</em> in 1887. Over time, however, public opinion changed, and the tower became '
      'a symbol of Paris and of France itself.</p>'
      '<p><strong>D</strong> The tower was originally intended to stand for only 20 years. It was saved because of its value as a radio '
      'transmission tower; during the First World War it was used to intercept enemy radio communications.</p>'
      '<p>Today the tower welcomes nearly seven million visitors a year, making it one of the most visited paid monuments in the world.</p>';

  static List<PartPayload> _readingParts() => _readingCache ??= [
        PartPayload(
          id: 201,
          type: 'reading',
          typeId: 2,
          name: 'Part 1',
          order: 1,
          firstQuestionNumber: 1,
          html: _passage1,
          sections: [
            SectionPayload(
              id: 601,
              questionType: QuestionType.trueFalse,
              inputType: 'radio',
              html: '<p><strong>Questions 1–4</strong></p><p>Do the following statements agree with the information given in the passage? Choose <strong>TRUE</strong>, <strong>FALSE</strong> or <strong>NOT GIVEN</strong>.</p>',
              questions: [
                for (final (i, text) in const [
                  'Eiffel himself had the original idea for the tower.',
                  'The tower took more than two years to build.',
                  'Several workers died during construction.',
                  'The tower was meant to be temporary.',
                ].indexed)
                  QuestionPayload(
                    id: 8001 + i,
                    number: 1 + i,
                    order: 1 + i,
                    html: '<p>$text</p>',
                    options: _opts(['TRUE', 'FALSE', 'NOT GIVEN']),
                  ),
              ],
            ),
            SectionPayload(
              id: 602,
              questionType: QuestionType.fillBlank,
              inputType: 'text',
              html: '<p><strong>Questions 5–7</strong></p><p>Complete the sentences. Choose <strong>NO MORE THAN TWO WORDS</strong> from the passage.</p>',
              questions: const [
                QuestionPayload(id: 8005, number: 5, order: 5, html: '<p>The tower was built from pieces of {} iron.</p>'),
                QuestionPayload(id: 8006, number: 6, order: 6, html: '<p>A petition against the tower appeared in a {}.</p>'),
                QuestionPayload(id: 8007, number: 7, order: 7, html: '<p>The tower survived because it was useful for {} transmission.</p>'),
              ],
            ),
            SectionPayload(
              id: 603,
              questionType: QuestionType.matching,
              inputType: 'select',
              html: '<p><strong>Questions 8–10</strong></p><p>Choose the correct heading for paragraphs <strong>B–D</strong> from the list of headings below.</p>',
              options: _opts([
                'i  Early criticism and later acceptance',
                'ii  A rapid and safe building process',
                'iii  The economic cost of the project',
                'iv  An unexpected reason for survival',
                'v  The designers behind the idea',
              ]),
              questions: const [
                QuestionPayload(id: 8008, number: 8, order: 8, html: 'Paragraph B'),
                QuestionPayload(id: 8009, number: 9, order: 9, html: 'Paragraph C'),
                QuestionPayload(id: 8010, number: 10, order: 10, html: 'Paragraph D'),
              ],
            ),
          ],
        ),
        PartPayload(
          id: 202,
          type: 'reading',
          typeId: 2,
          name: 'Part 2',
          order: 2,
          firstQuestionNumber: 11,
          html: '<h2>Working from Home</h2>'
              '<p>Over the past decade, remote work has moved from a rare privilege to a common arrangement. Supporters argue that it '
              'saves commuting time and allows employees to organise their day more flexibly. Critics, on the other hand, worry that '
              'it weakens team relationships and makes it harder for junior staff to learn from experienced colleagues.</p>'
              '<p>Research suggests that productivity depends largely on the type of task. Work that requires deep concentration often '
              'benefits from a quiet home environment, while creative brainstorming tends to be more effective in person. Many '
              'companies have therefore adopted a <em>hybrid</em> model, asking staff to come to the office two or three days a week.</p>',
          sections: [
            SectionPayload(
              id: 604,
              questionType: QuestionType.yesNo,
              inputType: 'radio',
              html: '<p><strong>Questions 11–12</strong></p><p>Do the following statements agree with the views of the writer? Choose <strong>YES</strong>, <strong>NO</strong> or <strong>NOT GIVEN</strong>.</p>',
              questions: [
                QuestionPayload(id: 8011, number: 11, order: 11, html: '<p>Remote work used to be uncommon.</p>',
                    options: _opts(['YES', 'NO', 'NOT GIVEN'])),
                QuestionPayload(id: 8012, number: 12, order: 12, html: '<p>Hybrid models reduce company costs.</p>',
                    options: _opts(['YES', 'NO', 'NOT GIVEN'])),
              ],
            ),
            SectionPayload(
              id: 605,
              questionType: QuestionType.multipleChoice,
              inputType: 'radio',
              html: '<p><strong>Question 13</strong></p><p>Choose the correct letter, <strong>A</strong>, <strong>B</strong>, <strong>C</strong> or <strong>D</strong>.</p>',
              questions: [
                QuestionPayload(
                  id: 8013,
                  number: 13,
                  order: 13,
                  html: '<p>According to the passage, productivity at home depends on</p>',
                  options: _opts(['the size of the company.', 'the kind of work being done.', 'the age of the employee.', 'the quality of the internet connection.']),
                ),
              ],
            ),
            SectionPayload(
              id: 606,
              questionType: QuestionType.completeSection,
              inputType: 'text',
              html: '<p><strong>Questions 14–15</strong></p><p>Complete the summary. Write <strong>ONE WORD ONLY</strong>.</p>'
                  '<p>Tasks needing deep {14} are often done better at home, whereas {15} sessions work best face to face.</p>',
              questions: const [
                QuestionPayload(id: 8014, number: 14, order: 14, html: ''),
                QuestionPayload(id: 8015, number: 15, order: 15, html: ''),
              ],
            ),
          ],
        ),
      ];

  static List<PartPayload> _writingParts() => _writingCache ??= [
        PartPayload(
          id: 301,
          type: 'writing',
          typeId: 3,
          name: 'Part 1',
          order: 1,
          firstQuestionNumber: 1,
          html: '<p><strong>WRITING TASK 1</strong></p><p>You should spend about 20 minutes on this task.</p>'
              '<p>The table below shows the number of visitors (in millions) to three museums in 2010 and 2020.</p>'
              '<table><tr><th>Museum</th><th>2010</th><th>2020</th></tr>'
              '<tr><td>National Gallery</td><td>4.8</td><td>1.2</td></tr>'
              '<tr><td>Science Museum</td><td>2.9</td><td>0.9</td></tr>'
              '<tr><td>History Museum</td><td>3.6</td><td>1.4</td></tr></table>'
              '<p>Summarise the information by selecting and reporting the main features, and make comparisons where relevant.</p>'
              '<p>Write at least <strong>150</strong> words.</p>',
          sections: const [
            SectionPayload(
              id: 701,
              questionType: QuestionType.essay,
              inputType: 'textarea',
              html: '',
              questions: [QuestionPayload(id: 9001, number: 1, order: 1, html: '<p>Task 1</p>')],
            ),
          ],
        ),
        PartPayload(
          id: 302,
          type: 'writing',
          typeId: 3,
          name: 'Part 2',
          order: 2,
          firstQuestionNumber: 2,
          html: '<p><strong>WRITING TASK 2</strong></p><p>You should spend about 40 minutes on this task.</p>'
              '<p>Some people believe that working from home is better for both employees and companies. Others think that '
              'it has more disadvantages than advantages.</p><p>Discuss both views and give your own opinion.</p>'
              '<p>Write at least <strong>250</strong> words.</p>',
          sections: const [
            SectionPayload(
              id: 702,
              questionType: QuestionType.essay,
              inputType: 'textarea',
              html: '',
              questions: [QuestionPayload(id: 9002, number: 2, order: 2, html: '<p>Task 2</p>')],
            ),
          ],
        ),
      ];
}
