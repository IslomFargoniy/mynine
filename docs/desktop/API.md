# Desktop API v1 — contract

Base URL: `https://mynine.uz/api/v1` (dev: `http://127.0.0.1:8000/api/v1`). JSON only.
Every request from the app sends:

```
Accept: application/json
X-Mynine-Client: desktop/<semver>      e.g. desktop/1.0.0
X-Device-Token: <device token>         (after device registration; omitted only on /device/register and /app/*)
Authorization: Bearer <exam token>     (exam endpoints only)
```

Errors: `{ "message": "...", "code": "<machine_code>" }` with HTTP status. Codes used by the app:
`unauthenticated` 401, `device_blocked` 403, `client_outdated` 426 (body also has `min_version`),
`invalid_code` 422, `mock_not_active` 422, `mock_not_started` 422 (+`starts_at`), `mock_finished` 422,
`attempt_finished` 409, `paused` 409, `module_locked` 409, `module_time_over` 409, `validation_failed` 422.

Server rejects exam requests whose `X-Mynine-Client` version is lower than the active `min_version` with 426.
All timestamps are ISO-8601 with offset (server timezone). Every exam response includes `server_time`.

---

## App / updates (no auth)

### GET /app/version
Query: `current=1.0.0` (optional).
```json
{
  "latest": { "version": "1.2.0", "notes": "…", "mandatory": false,
              "url": "https://mynine.uz/api/v1/app/releases/1.2.0/download",
              "sha256": "…64 hex…", "size": 41234567, "published_at": "…" },
  "min_version": "1.1.0",
  "update_available": true,
  "server_time": "…"
}
```
`latest` is the highest **active** release; `min_version` is the highest active release with `mandatory=true` (or `null`). If no release: `latest: null`.

### GET /app/releases/{version}/download
Streams the installer (`application/octet-stream`), supports HTTP `Range` (resume). 404 if inactive/unknown.

---

## Device

### POST /device/register
Body: `{ "machine_id": "<stable GUID from Windows MachineGuid>", "name": "PC-07", "os_version": "Windows 11 23H2", "app_version": "1.0.0" }`
Response 200: `{ "device_id": 7, "device_token": "<plain token, shown once>", "name": "PC-07" }`.
Re-registering the same `machine_id` rotates the token. Blocked devices → 403 `device_blocked`.

### POST /device/heartbeat
Header `X-Device-Token`. Body: `{ "app_version": "1.0.0", "state": "idle" }` (state: `idle|updating|exam`).
Response: `{ "server_time": "…", "unlock": false }`. Used on the code screen every 60 s (marks the PC online in the admin device list).

### POST /device/unlock
Header `X-Device-Token`. Body: `{ "password": "…" }` → 200 `{ "ok": true }` or 422 `{ "ok": false }`. Rate-limited 5/min.

### GET /device/config
Header `X-Device-Token`. Response:
```json
{ "exit_password_offline": "pbkdf2_sha256$120000$<salt_b64>$<hash_b64>",
  "banned_processes": ["anydesk.exe","teamviewer.exe","discord.exe","obs64.exe","telegram.exe","chrome.exe","msedge.exe","firefox.exe","zoom.exe","skype.exe"],
  "heartbeat_seconds": 20, "violation_batch_seconds": 10, "server_time": "…" }
```

---

## Exam auth

### POST /exam/login
Header `X-Device-Token`. Body: `{ "code": "MS1A2B3C" }` (case-insensitive, trimmed). Throttle 10/min per device.
Checks: code exists, mock active, inside window (`started_at`/`finished_at`), attempt not finished. Marks `attended`, `checked_in_at` (if empty), creates the attempt if missing (modules from `mock_modules`), binds `attempts.device_id`, revokes previous exam tokens of this candidate (only one PC at a time).
Response 200:
```json
{
  "token": "<sanctum plain-text token>",
  "expires_at": "…",                       // mock finished_at + 1h, or now + 6h
  "candidate": { "id": 12, "name": "Ali Valiyev", "code": "MS1A2B3C" },
  "mock": { "id": 3, "name": "Mock 12.11", "starts_at": "…", "ends_at": "…" },
  "attempt_id": 55,
  "server_time": "…"
}
```

### POST /exam/logout  → 204 (revokes the token)

---

## Exam (Bearer exam token + device token)

### GET /exam
Current state. Module order is always Listening, Reading, Writing (Speaking is never part of the desktop exam).
```json
{
  "attempt": { "id": 55, "status": "in_progress", "paused": false, "finished": false },
  "modules": [
    { "type_id": 1, "type": "listening", "title": "Listening", "duration_seconds": 1980,
      "status": "not_started",          // not_started | in_progress | submitted
      "started_at": null, "finished_at": null,
      "audio": { "url": "https://…/api/v1/exam/audio/test/9", "duration_seconds": 1920 } ,   // listening only, else null
      "parts": [ { "id": 101, "name": "Part 1", "order": 1, "question_count": 10, "first_question_number": 1 } ]
    }
  ],
  "server_time": "…"
}
```
`duration_seconds`: Listening = test `playtime_seconds + 5` if set else `types.minute*60`; others `types.minute*60`.
A module becomes `in_progress` only via `/start`. The app must follow the order; starting a module while an earlier one is not submitted → 409 `module_locked`.

### GET /exam/prefetch
Everything needed to run offline (does **not** start any timer):
```json
{ "modules": [ /* same as /exam modules */ ],
  "parts": [ /* PartPayload for every part of every module */ ],
  "audio": [ { "key": "test-9", "url": "…/exam/audio/test/9", "size": 31234567, "sha256": "…" },
             { "key": "part-101", "url": "…/exam/audio/part/101", "size": 1234, "sha256": "…" } ],
  "images": [ "https://mynine.uz/storage/…png" ],
  "server_time": "…" }
```

### GET /exam/parts/{part}
Returns one `PartPayload` (same shape as in prefetch). 403 if the part is not in this attempt.

**PartPayload** (answer keys stripped):
```json
{
  "id": 101, "type": "reading", "type_id": 2, "name": "Part 1", "order": 1,
  "first_question_number": 1,
  "html": "<p>passage HTML from TinyMCE (may be empty for listening)</p>",
  "audio_key": "part-101",                         // or null
  "sections": [
    { "id": 501,
      "question_type": "multiple_choice",          // multiple_choice | multiple_response | true_false | yes_no | fill_blank | matching | essay | complete_section | drag_and_drop
      "input_type": "radio",                       // radio | checkbox | text | select | textarea
      "html": "<p>Questions 1–5. Choose the correct letter…</p>",
      "from_option": 1, "to_option": 5,
      "options": [ { "id": 9001, "html": "A heading text" } ],            // section-level options (matching lists)
      "drag_options": [ { "id": "d1", "label": "…" } ],                   // drag_and_drop only, else []
      "questions": [
        { "id": 7001, "number": 1, "order": 1, "html": "<p>…</p>",
          "options": [ { "id": 8001, "html": "A …" } ],
          "answer": { "text": null, "option_ids": [] } }                  // candidate's saved answer
      ] }
  ]
}
```
Semantics of each question type follow the web exam room components in
`resources/js/components/practice/` (`practice-section.tsx`, `practice-question.tsx`, `matching-headings.tsx`,
`practice-option.tsx`, `practice-essay.tsx`). `complete_section`: blanks are marked in `section.html`; each blank maps to a
question in order. `drag_and_drop`: the candidate drops a `drag_options.label` onto a question; it is saved as `text`.
`matching`: saved as `text` (the chosen option letter/label) — mirror the web component.

### POST /exam/modules/{type_id}/start
Creates the module timer (and all its attempt parts). Idempotent: if already started returns the same timer.
Response: `{ "type_id": 1, "status": "in_progress", "started_at": "…", "finished_at": "…", "server_time": "…" }`.

### POST /exam/answers
Batch, idempotent.
```json
{ "answers": [
  { "client_uuid": "6f1c…", "part_id": 101, "question_id": 7001,
    "text": "carbon",                 // for text/select/textarea/drag types, else null
    "option_ids": [8001],             // for radio/checkbox, else []
    "changed_at": "2026-11-12T09:14:03+05:00" } ] }
```
Max 200 per batch. Per item the server: skips if `client_uuid` already applied; ignores the item if an answer for the same question with a later `changed_at` was already applied (last-write-wins by `changed_at`); rejects if the module is submitted or its time is over (+30 s grace for queued offline answers whose `changed_at` is before `finished_at`).
Response 200:
```json
{ "results": [ { "client_uuid": "6f1c…", "status": "saved" } ],   // saved | duplicate | stale | rejected
  "server_time": "…" }
```
`rejected` items carry `"reason": "module_time_over" | "module_submitted" | "invalid_question" | "paused"`. The app drops `saved|duplicate|stale|rejected` items from its queue (all are final).

### POST /exam/modules/{type_id}/submit
Finishes the module (queues Writing AI evaluation). Response: `{ "type_id": 1, "status": "submitted", "server_time": "…" }`.

### POST /exam/submit
Finishes the whole attempt and revokes the exam token. Response: `{ "status": "completed", "server_time": "…" }`. Never returns scores.

### POST /exam/heartbeat
Body: `{ "type_id": 2, "part_id": 105, "queued_answers": 0, "queued_violations": 0, "online_since": "…" }`
Response:
```json
{ "server_time": "…", "paused": false, "finished": false,
  "unlock": false,                                  // remote unlock requested by Admin/Reception
  "modules": [ { "type_id": 2, "status": "in_progress", "finished_at": "…" } ] }   // finished_at may move (extra time / pause)
```
If `finished` is true (force-submitted by Admin) the app shows Completed.

### POST /exam/violations
```json
{ "violations": [ { "client_uuid": "…", "type": "focus_lost", "detail": { "process": "chrome.exe" }, "occurred_at": "…" } ] }
```
Types: `focus_lost`, `second_monitor`, `banned_process`, `screen_capture_attempt`, `app_restarted`, `network_lost`, `clipboard`, `vm_detected`.
Response: `{ "accepted": 1, "server_time": "…" }`.

### GET /exam/audio/test/{test}  ·  GET /exam/audio/part/{part}
Streams audio with `Range` support; only for tests/parts of the current attempt.

---

## Admin-side (web, session auth — not used by the app)

Monitor actions (`Admin` unless noted): `POST /monitor/attempts/{attempt}/extra-time {minutes}`, `/pause`, `/resume`,
`/force-submit`, `/unlock` (Admin + Reception). Device list, releases upload, settings live under the web admin.
