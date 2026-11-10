import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mynine_desktop/data/models/exam_models.dart';
import 'package:mynine_desktop/data/models/part_payload.dart';

/// A PartPayload in the exact API.md shape, one section per question type.
const partJson = '''
{
  "id": 101, "type": "reading", "type_id": 2, "name": "Part 1", "order": 1,
  "first_question_number": 1,
  "html": "<p>passage</p>",
  "audio_key": null,
  "sections": [
    {"id": 1, "question_type": "multiple_choice", "input_type": "radio", "html": "<p>Choose</p>",
     "from_option": 1, "to_option": 5, "options": [], "drag_options": [],
     "questions": [{"id": 11, "number": 1, "order": 1, "html": "<p>Q</p>",
       "options": [{"id": 8001, "html": "A thing"}, {"id": 8002, "html": "B thing"}],
       "answer": {"text": null, "option_ids": [8002]}}]},
    {"id": 2, "question_type": "multiple_response", "input_type": "checkbox", "html": "",
     "from_option": null, "to_option": null, "options": [], "drag_options": [],
     "questions": [{"id": 12, "number": 2, "number_count": 2, "order": 2, "html": "<p>Choose TWO</p>",
       "options": [{"id": 1, "html": "a"}, {"id": 2, "html": "b"}, {"id": 3, "html": "c"}],
       "answer": {"text": null, "option_ids": [1, 3]}}]},
    {"id": 3, "question_type": "true_false", "input_type": "radio", "html": "",
     "options": [], "drag_options": [],
     "questions": [{"id": 13, "number": 4, "order": 3, "html": "<p>S</p>",
       "options": [{"id": 4, "html": "TRUE"}, {"id": 5, "html": "FALSE"}, {"id": 6, "html": "NOT GIVEN"}],
       "answer": {"text": null, "option_ids": []}}]},
    {"id": 4, "question_type": "yes_no", "input_type": "radio", "html": "",
     "options": [], "drag_options": [],
     "questions": [{"id": 14, "number": 5, "order": 4, "html": "<p>S</p>",
       "options": [{"id": 7, "html": "YES"}], "answer": {"text": null, "option_ids": []}}]},
    {"id": 5, "question_type": "fill_blank", "input_type": "text", "html": "",
     "options": [], "drag_options": [],
     "questions": [{"id": 15, "number": 6, "order": 5, "html": "<p>Built of {} iron</p>",
       "options": [], "answer": {"text": "wrought", "option_ids": []}}]},
    {"id": 6, "question_type": "matching", "input_type": "select", "html": "<p>Match</p>",
     "from_option": "A", "to_option": "F",
     "options": [{"id": 9001, "html": "i Heading one"}], "drag_options": [],
     "questions": [{"id": 16, "number": 7, "order": 6, "html": "Paragraph B",
       "options": [], "answer": {"text": "i Heading one", "option_ids": []}}]},
    {"id": 7, "question_type": "essay", "input_type": "textarea", "html": "",
     "options": [], "drag_options": [],
     "questions": [{"id": 17, "number": 1, "order": 1, "html": "<p>Task 1</p>",
       "options": [], "answer": {"text": "My essay", "option_ids": []}}]},
    {"id": 8, "question_type": "complete_section", "input_type": "text",
     "html": "<p>Name: {1} and {2}</p>", "options": [], "drag_options": [],
     "questions": [
       {"id": 18, "number": 8, "order": 7, "html": "", "options": [], "answer": {"text": null, "option_ids": []}},
       {"id": 19, "number": 9, "order": 8, "html": "", "options": [], "answer": {"text": "x", "option_ids": []}}]},
    {"id": 9, "question_type": "drag_and_drop", "input_type": "text",
     "html": "<p>Opens at {a}</p>", "options": [],
     "drag_options": [{"id": "d1", "label": "6 am"}, {"id": 2, "label": "7 am"}],
     "questions": [{"id": 20, "number": 10, "order": 9, "html": "", "options": [],
       "answer": {"text": "6 am", "option_ids": []}}]}
  ]
}
''';

void main() {
  test('PartPayload parses every question type', () {
    final p = PartPayload.fromJson(jsonDecode(partJson) as Map<String, dynamic>);
    expect(p.id, 101);
    expect(p.typeId, 2);
    expect(p.audioKey, isNull);
    expect(p.sections.map((s) => s.questionType).toSet(), QuestionType.all);

    final mc = p.sections[0];
    expect(mc.fromOption, '1'); // number → string
    expect(mc.questions.single.options.length, 2);
    expect(mc.questions.single.answer.optionIds, [8002]);
    expect(mc.questions.single.answerCount, 1);
    expect(mc.usesOptionIds, isTrue);

    final mr = p.sections[1].questions.single;
    expect(mr.answerCount, 2, reason: 'number_count');
    expect(mr.answer.optionIds, [1, 3]);

    expect(p.sections[4].questions.single.answer.text, 'wrought');
    expect(p.sections[5].fromOption, 'A');
    expect(p.sections[5].options.single.id, 9001);
    expect(p.sections[6].questions.single.answer.isAnswered, isTrue);
    expect(p.sections[7].questions.length, 2);
    expect(p.sections[8].dragOptions.map((d) => d.id), ['d1', '2']);
    expect(p.allQuestions.length, 10);
  });

  test('answer_count / is_correct_count fall back when number_count is absent', () {
    final q = QuestionPayload.fromJson({'id': 1, 'number': 3, 'is_correct_count': 3});
    expect(q.answerCount, 3);
    final q2 = QuestionPayload.fromJson({'id': 1, 'number': 3, 'number_count': 0});
    expect(q2.answerCount, 1);
    final q3 = QuestionPayload.fromJson({'id': 1, 'number': 3});
    expect(q3.answerCount, 1);
    expect(q3.answer.isAnswered, isFalse);
  });

  test('prefetch / exam state / heartbeat parse', () {
    final pre = PrefetchPayload.fromJson(jsonDecode('''
    {"modules": [{"type_id": 1, "type": "listening", "title": "Listening", "duration_seconds": 1980,
      "status": "in_progress", "started_at": "2026-11-12T09:00:00+05:00", "finished_at": "2026-11-12T09:33:00+05:00",
      "audio": {"url": "https://x/api/v1/exam/audio/test/9", "duration_seconds": 1920},
      "parts": [{"id": 101, "name": "Part 1", "order": 1, "question_count": 10, "first_question_number": 1}]},
      {"type_id": 2, "type": "reading", "title": "Reading", "duration_seconds": 3600, "status": "not_started",
       "started_at": null, "finished_at": null, "audio": null, "parts": []}],
     "parts": [$partJson],
     "audio": [{"key": "test-9", "url": "https://x/a", "size": 3, "sha256": "abc"}],
     "images": ["https://mynine.uz/storage/a.png"],
     "server_time": "2026-11-12T09:10:00+05:00"}
    ''') as Map<String, dynamic>);
    expect(pre.modules.first.isListening, isTrue);
    expect(pre.modules.first.isInProgress, isTrue);
    expect(pre.modules.first.finishedAt, DateTime.utc(2026, 11, 12, 4, 33));
    expect(pre.modules.first.audio!.durationSeconds, 1920);
    expect(pre.modules[1].audio, isNull);
    expect(pre.parts.single.sections.length, 9);
    expect(pre.serverTime, DateTime.utc(2026, 11, 12, 4, 10));

    final hb = ExamHeartbeatResponse.fromJson(jsonDecode('''
      {"server_time": "2026-11-12T09:10:00+05:00", "paused": true, "finished": false, "unlock": false,
       "modules": [{"type_id": 2, "status": "in_progress", "finished_at": "2026-11-12T10:10:00+05:00"}]}
    ''') as Map<String, dynamic>);
    expect(hb.paused, isTrue);
    expect(hb.modules.single.finishedAt, DateTime.utc(2026, 11, 12, 5, 10));
  });

  test('AnswerItem serialises to the API.md shape', () {
    final a = AnswerItem(
      clientUuid: 'u1',
      partId: 101,
      questionId: 7001,
      text: 'carbon',
      changedAt: DateTime.utc(2026, 11, 12, 4, 14, 3),
    );
    expect(a.toJson(), {
      'client_uuid': 'u1',
      'part_id': 101,
      'question_id': 7001,
      'text': 'carbon',
      'option_ids': <int>[],
      'changed_at': '2026-11-12T04:14:03.000Z',
    });
  });
}
