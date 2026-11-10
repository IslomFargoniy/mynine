import 'package:flutter_test/flutter_test.dart';
import 'package:mynine_desktop/core/api/api_exception.dart';
import 'package:mynine_desktop/core/api/fake_mynine_api.dart';
import 'package:mynine_desktop/core/time/server_clock.dart';
import 'package:mynine_desktop/data/db/app_database.dart';
import 'package:mynine_desktop/data/models/exam_models.dart';
import 'package:mynine_desktop/data/repositories/answer_queue.dart';

/// Fake whose responses can be "lost" after the server applied them.
class LossyApi extends FakeMynineApi {
  LossyApi(ServerClock clock) : super(clock: clock, latency: Duration.zero);
  int loseNextResponses = 0;

  @override
  Future<AnswersResponse> sendAnswers(String examToken, List<AnswerItem> answers) async {
    final r = await super.sendAnswers(examToken, answers);
    if (loseNextResponses > 0) {
      loseNextResponses--;
      throw ApiException(code: ApiErrorCode.network, message: 'response lost');
    }
    return r;
  }
}

void main() {
  late AppDatabase db;
  late AnswerQueueRepository queue;
  late LossyApi api;
  late String token;
  const attempt = FakeMynineApi.attemptId;
  final t0 = DateTime.utc(2026, 11, 12, 9);

  setUp(() async {
    db = AppDatabase.memory();
    queue = AnswerQueueRepository(db);
    api = LossyApi(ServerClock());
    token = (await api.login('DEMO1')).token;
    await api.startModule(token, 1);
  });

  tearDown(() => db.close());

  test('changes are stored locally and coalesced per question', () async {
    await queue.enqueue(attemptId: attempt, partId: 101, questionId: 7001, text: 'car', changedAt: t0);
    await queue.enqueue(
        attemptId: attempt, partId: 101, questionId: 7001, text: 'carbon', changedAt: t0.add(const Duration(seconds: 1)));
    await queue.enqueue(attemptId: attempt, partId: 101, questionId: 7007, optionIds: [5], changedAt: t0);
    expect(await queue.pendingCount(attemptId: attempt), 2);
    final local = await queue.localAnswers(attempt);
    expect(local[7001]!.text, 'carbon');
    expect(local[7007]!.optionIds, [5]);
  });

  test('network failure keeps items queued and bumps tries; retry delivers', () async {
    await queue.enqueue(attemptId: attempt, partId: 101, questionId: 7001, text: 'carbon', changedAt: t0);
    api.failNextAnswerCalls = 1;
    await expectLater(queue.syncOnce(api, token, attempt), throwsA(isA<ApiException>()));
    final pending = await queue.pending(attempt);
    expect(pending.single.tries, 1);
    final r = await queue.syncOnce(api, token, attempt);
    expect(r.removed, 1);
    expect(r.remaining, 0);
    expect(api.savedAnswers[7001]!.text, 'carbon');
  });

  test('re-sending after a lost response is idempotent (duplicate is final)', () async {
    await queue.enqueue(attemptId: attempt, partId: 101, questionId: 7001, text: 'carbon', changedAt: t0);
    api.loseNextResponses = 1;
    await expectLater(queue.syncOnce(api, token, attempt), throwsA(isA<ApiException>()));
    // Server applied it, client did not get the ack → item still queued.
    expect(await queue.pendingCount(attemptId: attempt), 1);
    expect(api.appliedUuids.length, 1);
    final r = await queue.syncOnce(api, token, attempt);
    expect(r.removed, 1);
    expect(await queue.pendingCount(attemptId: attempt), 0);
    expect(api.calls.where((c) => c == 'sendAnswers').length, 2);
    expect(api.savedAnswers.length, 1);
  });

  test('older change is stale, rejected items are dropped too', () async {
    await queue.enqueue(
        attemptId: attempt, partId: 101, questionId: 7001, text: 'new', changedAt: t0.add(const Duration(minutes: 1)));
    await queue.syncOnce(api, token, attempt);
    // An older change arriving later (e.g. from a queue on disk) must not win.
    await queue.enqueue(attemptId: attempt, partId: 101, questionId: 7001, text: 'old', changedAt: t0);
    // A question of a part that is not in the attempt → rejected.
    await queue.enqueue(attemptId: attempt, partId: 999, questionId: 1, text: 'x', changedAt: t0);
    final r = await queue.syncOnce(api, token, attempt);
    expect(r.removed, 2);
    expect(r.rejected.single.reason, 'invalid_question');
    expect(api.savedAnswers[7001]!.text, 'new');
    expect(await queue.pendingCount(), 0);
  });

  test('drain sends batches of at most 200', () async {
    for (var i = 0; i < 450; i++) {
      await queue.enqueue(attemptId: attempt, partId: 101, questionId: 100000 + i, text: '$i', changedAt: t0);
    }
    final left = await queue.drain(api, token, attempt);
    expect(left, 0);
    expect(api.calls.where((c) => c == 'sendAnswers').length, 3);
  });

  test('Backoff grows exponentially and is capped', () {
    final b = Backoff();
    expect(b.nextDelay, Duration.zero);
    b.fail();
    expect(b.nextDelay, const Duration(seconds: 1));
    b.fail();
    expect(b.nextDelay, const Duration(seconds: 2));
    for (var i = 0; i < 10; i++) {
      b.fail();
    }
    expect(b.nextDelay, const Duration(seconds: 30));
    b.reset();
    expect(b.nextDelay, Duration.zero);
  });
}
