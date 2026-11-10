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

---

## Implementation notes (server, v1)

Additive clarifications of the contract above, as implemented on branch `feat/desktop-mock-system`.

**Errors and limits**
- Extra codes besides the list above: `forbidden` 403, `not_found` 404, `method_not_allowed` 405, `too_many_requests` 429,
  `server_error` 500. `validation_failed` also carries Laravel's `errors` object.
- Throttles: `/device/register` 30/min per IP; `/exam/login` 10/min per device **and** 60/min per IP; `/device/unlock`
  5/min per device; every other device/exam endpoint 300/min per device; `/app/*` 300/min per IP.
- The `X-Mynine-Client` check (426 `client_outdated`) runs on `/exam/*` only (login included). `/app/*` and `/device/*`
  never return 426, so an outdated PC can still heartbeat and update. A missing or malformed header counts as outdated
  while a `min_version` exists.

**App / device**
- `GET /app/version`: `update_available` compares `latest.version` with `current`, falling back to the version in
  `X-Mynine-Client`; with neither it is `true` whenever a release exists. `current` must be `x.y.z` (else 422).
- `POST /device/register`: the token is 64 random characters; only its SHA-256 is stored. Re-registering a blocked
  `machine_id` returns 403 `device_blocked`.
- `POST /device/unlock` 422 body is `{ "ok": false, "message": "...", "code": "invalid_password" }`.
- `POST /device/heartbeat` `unlock` is delivered for the attempt last started on this PC (so a PC already back on the code
  screen after submit can be unlocked remotely).
- Remote unlock (both heartbeats) is one-shot: it is cleared when delivered and expires 15 min after the monitor request.

**Exam auth**
- The exam token only works from the PC the attempt is bound to (`attempts.device_id`); other PCs get 401.
- Login on an already finished attempt → 409 `attempt_finished`. A mock with neither modules nor a test → 422 `mock_not_active`.
- A force-submitted attempt keeps its token valid so `/exam/heartbeat` can report `finished: true`; `/exam/submit` then
  answers `completed` and revokes it.

**Exam payloads**
- `attempt.status` is `in_progress` or `completed`.
- Parts are ordered by id inside a module, sections and questions by id inside a part (same as the web exam room).
- `questions[].number` is the **first** question number the question covers. Additive field `questions[].number_count`
  = how many numbers it covers (1, or the number of answers for "choose TWO/THREE" questions); `parts[].question_count`
  is the sum for the part. Numbering restarts at 1 for each module.
- `audio` (module) is `null` when the test has no audio file; `prefetch.audio` lists only files that exist on the server.
- `prefetch.images` are absolute URLs taken from `<img src>` in the part/section/question/option HTML (`data:` URIs skipped).
- `GET /exam/prefetch` on a finished attempt → 409 `attempt_finished`. `GET /exam/parts/{id}` and the audio endpoints answer
  403 `forbidden` for anything outside the attempt's Listening/Reading/Writing modules, 404 `not_found` if the file is missing.

**Modules**
- `start`: a type that is not one of the attempt's modules → 404 `not_found`. An already started module returns its timer
  (even if submitted). Otherwise 409 `attempt_finished` / `paused`, and 409 `module_locked` unless every earlier module
  is submitted (a module whose time ran out is auto-submitted 30 s after its `finished_at`).
- `submit`: not started → 409 `module_locked`; while paused → 409 `paused`; repeating it is a no-op returning `submitted`.
- `POST /exam/submit` while paused → 409 `paused`.

**Answers**
- The whole batch is refused with 409 `attempt_finished` when the attempt is finished.
- Items for parts of modules that are not started yet, or questions not in that part → `rejected` / `invalid_question`.
- The server keeps the last applied `client_uuid` + `changed_at` (ms precision) per question. Re-sending that uuid →
  `duplicate`; an item older than the stored change → `stale` (this also covers re-sending an older, already superseded
  uuid). Equal `changed_at` → the later request wins.
- `option_ids`: for single-choice questions only the first id is kept; ids that do not belong to the question are ignored.
  `option_ids: []` clears the selection.
- Pause: items with `changed_at` ≥ the pause time → `rejected` / `paused`; items changed before the pause are still
  accepted. While paused the server clock for time checks stands still.
- Grace: after `finished_at`, an item is accepted only if its `changed_at` ≤ `finished_at` and the server time is
  ≤ `finished_at` + 30 s. So a module can report `in_progress` for up to 30 s past `finished_at`.

**Violations**
- Deduplicated by `client_uuid` per attempt. `accepted` = number of items acknowledged (duplicates included).
  `detail` is an object with at most 20 keys. They are accepted even after the attempt is finished.

**Monitor (web)**
- Routes: `POST /monitor/attempts/{attempt}/{extra-time|pause|resume|force-submit|unlock}` (session auth, redirect back
  with a flash message). `extra-time` takes `minutes` 1–120 and extends every started, unsubmitted module and its parts.
- Resume moves every unsubmitted `attempt_types.finished_at` and every `attempt_parts.finished_at` still running at pause
  time forward by the whole seconds the attempt was paused.

**Storage additions** (not listed in ARCHITECTURE.md): `attempt_answers.client_uuid`, `attempt_answers.client_changed_at`
(datetime(3)) + index (`attempt_part_id`, `question_id`); `attempt_violations.client_uuid` with unique (`attempt_id`,
`client_uuid`); index on `mock_students.phone`. `devices.current_attempt_id` has no foreign key.
The exit password is set with `php artisan desktop:exit-password <password>` (minimum 6 characters, 16-byte salt).

### Device approval (added by coordinator)
- A newly registered PC has `is_approved = false`. Until an Admin approves it in the web panel,
  `POST /exam/login` and `GET /device/config` return **403 `device_not_approved`** (message names the PC).
  `/device/heartbeat`, `/device/unlock` and `/app/*` keep working, so the PC shows up as "pending" in the admin device list.
- **Re-registering** an existing `machine_id` rotates the token **and drops the approval** (someone who learns an approved
  PC's machine id cannot take over its approval). The app must therefore register only once and keep its token; on
  `device_not_approved` it shows "This PC is waiting for administrator approval: <name>" on the code screen and retries
  `GET /device/config` every 30 s.
