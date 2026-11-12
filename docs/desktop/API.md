# Desktop API v1 — contract

> **v1.1:** see ["v1.1 changes"](#v11-changes-server-implemented-desktop-client-must-follow) at the end — it overrides the
> sections below where they differ (timestamps with ms, per-item answer results, `seq`, `deferred`, late sync,
> 426 on login only, token lifetime and 401 codes, `session_active_elsewhere`).

Base URL: `https://mynine.uz/api/v1` (dev: `http://127.0.0.1:8000/api/v1`). JSON only.
Every request from the app sends:

```
Accept: application/json
X-Mynine-Client: desktop/<semver>      e.g. desktop/1.0.0
X-Device-Token: <device token>         (after device registration; omitted only on /device/register)
Authorization: Bearer <exam token>     (exam endpoints only)
```

Errors: `{ "message": "...", "code": "<machine_code>" }` with HTTP status. Codes used by the app:
`unauthenticated` 401, `device_blocked` 403, `client_outdated` 426 (body also has `min_version`),
`invalid_password` 422, `setup_password_missing` 409, `device_other_center` 409, `device_not_approved` 403,
`invalid_code` 422, `mock_not_active` 422, `mock_not_started` 422 (+`starts_at`), `mock_finished` 422,
`attempt_finished` 409, `paused` 409, `module_locked` 409, `module_time_over` 409, `validation_failed` 422,
v1.1: `session_revoked` 401, `session_expired` 401, `session_active_elsewhere` 409.
Multi-center (2026-11): `invalid_center_code` 422, `center_suspended` 403 — see "Multi-center" below.

Server rejects exam requests whose `X-Mynine-Client` version is lower than `min_version` of `desktop/version.json` with 426.
All timestamps are ISO-8601 with offset (server timezone). Every exam response includes `server_time`.

---

## Updates — static folder (not part of the API, no auth)

Updates are **static files**, not API endpoints: nginx serves the server's `public/desktop/` folder as
`https://mynine.uz/desktop/` (site root = API base URL without `/api/v1`). It holds `version.json` and the
installers `mynine-setup-<version>.exe` (uploaded by hand, not in git; old installers are kept there for rollback).

### GET {site}/desktop/version.json?t=<epoch seconds>
The `t` query only busts caches. No auth headers are needed (the app sends no device token).
```json
{
  "version": "1.2.0",
  "file": "mynine-setup-1.2.0.exe",
  "sha256": "…64 hex…",
  "size": 41234567,
  "mandatory": false,
  "min_version": null,
  "notes": "…",
  "published_at": "2026-11-10T12:00:00Z"
}
```
- `version` (`x.y.z`) is the newest release. The app offers it only when it is **higher** than the installed version
  and the manifest is complete (`file` is a plain `*.exe` name, `sha256` is 64 hex, `size` > 0). An empty `sha256`,
  `size: 0`, a missing `file`, an invalid body or a 404 mean "no update", never an error that blocks an exam.
- Mandatory (update dialog cannot be dismissed) when `mandatory` is `true` **or** the installed version is below
  `min_version`.
- `min_version` (`x.y.z` or `null`) is also read by the server: `/exam/*` answers 426 `client_outdated` to older clients
  (`null` → no check).
- The CI workflow generates this file next to the installer (see `desktop/README.md`).

### GET {site}/desktop/{file}
The installer, served by nginx with HTTP `Range` (resume). The app verifies `size` and `sha256` before installing.
Before installing an update the app also fetches `{site}/desktop/mynine-setup-<installed version>.exe` as its rollback
copy (if it does not have one yet); without it no automatic rollback is possible.

---

## Device

### POST /device/register
**Contract change (desktop 1.0.2):** registration requires the center password (the desktop exit password set in
Desktop settings / `php artisan desktop:center-password`, alias of `desktop:exit-password`), so only center staff
can add a PC. The same center password unlocks the exam screen and opens the app's admin menu.

Body: `{ "machine_id": "<stable GUID from Windows MachineGuid>", "center_code": "ACME", "password": "<center password>", "name": "PC-07", "os_version": "Windows 11 23H2", "app_version": "1.0.0" }`
(`name` optional — default `PC-<last 4 characters of machine_id>`, an existing PC keeps its name; `center_code` optional,
see "Multi-center": without it the PC registers to the Mynine center).
Response 200: `{ "device_id": 7, "device_token": "<plain token, shown once>", "name": "PC-07", "number": null, "approved": false, "exit_password_offline": "pbkdf2_sha256$120000$<salt_b64>$<hash_b64>", "center": { "code": "ACME", "name": "Acme Learning", "logo_url": "https://…/storage/centers/logos/….png", "suspended": false } }`.
- `exit_password_offline` (same value as in `/device/config`): the app stores it right after registering, so a PC that is
  not approved yet (403 `device_not_approved` on `/device/config`) or is blocked later can still verify the center
  password offline (exit / admin menu).
- Missing / wrong `password` → 422 `invalid_password`.
- No center password configured for the center → 409 `setup_password_missing` ("… Set the center password in Desktop settings first.").
- Unknown `center_code` → 422 `invalid_center_code`. Suspended center (after a correct password) → 403 `center_suspended`.
- Re-registering the same `machine_id` with the same center rotates the token and drops the approval (the exam-room
  number is kept, the admin confirms it again). Blocked devices → 403 `device_blocked`.
- A PC is identified by (center, `machine_id`). If the `machine_id` is still registered to another center → 409
  `device_other_center` ("This PC is registered to another center. Ask that center to remove it first."); the other
  center's PC row and token are left untouched. Once that center deletes the PC (Desktop → PCs), it can register here
  as a new, unapproved PC.
- `number` is the exam-room number ("PC 7") the admin gives when approving; it is `null` until the PC is approved.

### POST /device/heartbeat
Header `X-Device-Token`. Body: `{ "app_version": "1.0.0", "state": "idle" }` (state: `idle|updating|exam`).
Response: `{ "server_time": "…", "unlock": false, "name": "PC-07", "number": 7, "approved": true }`
(`number` is `null` while not approved). Used on the code screen every 60 s (marks the PC online in the admin device list);
the app updates its displayed number from it (the admin may renumber a PC at any time). Works for unapproved PCs too.

### GET /device/background
Header `X-Device-Token`. The code-screen background picture (jpg/png/webp), 404 when none is set.

### POST /device/unlock
Header `X-Device-Token`. Body: `{ "password": "…" }` → 200 `{ "ok": true }` or 422 `{ "ok": false }`. Rate-limited 5/min.

### GET /device/config
Header `X-Device-Token`. Response:
```json
{ "name": "PC-07", "number": 7, "approved": true,
  "exit_password_offline": "pbkdf2_sha256$120000$<salt_b64>$<hash_b64>",
  "banned_processes": ["anydesk.exe","teamviewer.exe","discord.exe","obs64.exe","telegram.exe","chrome.exe","msedge.exe","firefox.exe","zoom.exe","skype.exe"],
  "heartbeat_seconds": 20, "violation_batch_seconds": 10, "server_time": "…",
  "background_url": "https://mynine.uz/api/v1/device/background", "background_sha256": "…",
  "center": { "code": "ACME", "name": "Acme Learning", "logo_url": null, "suspended": false } }
```
Everything here (center password, background, `center`) is the PC's own center's.
`background_url` / `background_sha256` are null when no background picture is set (Admin: Exam PCs → Background).
An idle PC re-reads the config every minute and keeps the picture on disk (verified by SHA-256).
403 `device_not_approved` until the PC is approved (see "Device approval"). `banned_processes` comes from
`config/desktop.php` (override with `DESKTOP_BANNED_PROCESSES="a.exe,b.exe"`). Since desktop 1.0.2 the app **closes**
these programs (its own session only, never Windows system processes) when the exam starts and on every scan, and
blocks "Start" on the rules screen while any is running.

---

## Exam auth

### POST /exam/login
Header `X-Device-Token`. Body: `{ "code": "849201" }` (six digits since 2026-11; older codes still accepted, trimmed). Throttle 10/min per device.
Checks: code exists **in a mock of the PC's center** (a code of another center is 422 `invalid_code`, exactly like an
unknown code), the center is not suspended (403 `center_suspended`), attempt not finished (409 `attempt_finished`), mock
active, inside window (`started_at`/`finished_at`).
A candidate who already has an unfinished attempt that was opened on a PC (or has a started Listening / Reading / Writing
module) **resumes**: the active / not-started / finished checks are skipped (see v1.1 §i). An attempt that only holds an
early Speaking band (no PC yet) is not a resume. Marks `attended`, `checked_in_at` (if empty), creates the attempt if missing (modules from `mock_modules`), binds `attempts.device_id`, revokes previous exam tokens of this candidate (only one PC at a time).
Response 200:
```json
{
  "token": "<sanctum plain-text token>",
  "expires_at": "…",                       // max(mock finished_at, now) + all module durations + 2 h; extended by /exam/heartbeat (v1.1 §g)
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
      "from_option": "A", "to_option": "G",       // strings or null: letters, numbers ("1"-"5") or roman numerals
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
`practice-option.tsx`, `practice-essay.tsx`). `complete_section` / `drag_and_drop`: blanks are marked in `section.html` as `{}` (the server strips the stored
answers out of the braces); each blank maps to a question in order. `drag_and_drop`: the candidate drops a `drag_options.label` onto a question; it is saved as `text`.
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
`detail` (desktop ≥ 1.0.2): `focus_lost` → `{ "process": "chrome.exe" }` (the program that took the focus, when known);
`banned_process` → `{ "process": "chrome.exe", "terminated": true }`.
Types: `focus_lost`, `second_monitor`, `banned_process`, `screen_capture_attempt`, `app_restarted`, `network_lost`, `clipboard`, `vm_detected`.
Response: `{ "accepted": 1, "server_time": "…" }`.

### GET /exam/audio/test/{test}  ·  GET /exam/audio/part/{part}
Streams audio with `Range` support; only for tests/parts of the current attempt.

---

## Admin-side (web, session auth — not used by the app)

Monitor actions (`Admin` unless noted): `POST /monitor/attempts/{attempt}/extra-time {minutes}`, `/pause`, `/resume`,
`/force-submit`, `/unlock` (Admin + Reception). Device list and settings live under the web admin (installers are uploaded to the static folder, see above).
Devices (Admin): `POST /desktop/devices/{device}/approve {number}` (required, 1–999, unique among PCs; the page prefills the
lowest free number), `PATCH /desktop/devices/{device} {name?, number?}` (renumber / rename), block / unblock keep the number.
`POST /monitor/attempts/{attempt}/release-device` (Admin + Reception): frees the PC of a candidate so the code works on
another PC (clears `attempts.device_id`, the devices' `current_attempt_id` and the candidate's exam tokens), see v1.1 §h.

Guards (web flash error, nothing changes):
- Block or delete a PC is refused while an exam runs on it (its `current_attempt_id` is unfinished and sent an exam
  heartbeat in the last 90 s, `desktop.active_elsewhere_seconds`): finish the exam or release the PC first.
- A mock / candidate with an unfinished attempt cannot be deleted; deleting them also revokes the candidates' exam tokens.
  An unfinished attempt cannot be deleted.
- A mock's modules are locked as soon as any candidate has an attempt (logged in on a PC, possibly prefetched; or a
  Speaking band), not only after a module started.
- Test content (part / section / question / option delete, PDF import replace, move to practice) is locked while the test
  has attempts or any mock that sits one of its modules (`mock_modules` or legacy `mocks.test_id`) has attempts or has not
  ended. A test used by any mock is never deleted (the mock and its candidates are kept; delete or change the mock first).
- `attempts:close-old` never closes an attempt that has no started Listening / Reading / Writing module while the mock
  window is open (a Speaking band given before the written exam creates the attempt early).
- The result is not ready while offline late answers may still arrive (`acceptsLateAnswers`); a late essay that arrives
  after the Writing review was confirmed clears the confirmation (back in the Writing review queue). Confirming Writing
  needs a submitted module and no essay waiting for its AI band, unless the Admin enters the band.
The monitor lists attempts by PC number (`device_number`), the reception list shows `device.number`.

---

## Implementation notes (server, v1)

Additive clarifications of the contract above, as implemented on branch `feat/desktop-mock-system`.

**Errors and limits**
- Extra codes besides the list above: `forbidden` 403, `not_found` 404, `method_not_allowed` 405, `too_many_requests` 429,
  `server_error` 500. `validation_failed` also carries Laravel's `errors` object.
- Throttles: `/device/register` 30/min per IP; `/exam/login` 10/min per device **and** 60/min per IP; `/device/unlock`
  5/min per device; every other device/exam endpoint 300/min per device.
- The `X-Mynine-Client` check (426 `client_outdated`) runs on `/exam/*` only (login included). `/device/*` never
  returns 426 and updates are static files, so an outdated PC can still heartbeat and update. A missing or malformed
  header counts as outdated while `version.json` has a `min_version`. `min_version` comes from
  `public/desktop/version.json` (`App\Services\Desktop\ReleaseManifest`, cached per file mtime; a missing or invalid
  file means no check).

**App / device**
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
  with a flash message). Requests with `Accept: application/json` (and no `X-Inertia` header) get
  `{ "ok": bool, "message": "...", "attempt": {...monitor row...} }` instead (409 when the action could not be applied).
  The monitor page itself is `GET /monitor?mock_id=` (Admin + Reception). `extra-time` takes `minutes` 1–120 and extends every started, unsubmitted module and its parts.
- Resume moves every unsubmitted `attempt_types.finished_at` and every `attempt_parts.finished_at` still running at pause
  time forward by the whole seconds the attempt was paused.

**Storage additions** (not listed in ARCHITECTURE.md): `attempt_answers.client_uuid`, `attempt_answers.client_changed_at`
(datetime(3)) + index (`attempt_part_id`, `question_id`); `attempt_violations.client_uuid` with unique (`attempt_id`,
`client_uuid`); index on `mock_students.phone`. `devices.current_attempt_id` has no foreign key.
The center password (setting key `desktop_exit_password`) is set in Desktop settings or with
`php artisan desktop:center-password <password>` (= `desktop:exit-password`; minimum 6 characters, 16-byte salt).

### Device approval (added by coordinator)
- A newly registered PC has `is_approved = false`. Until an Admin approves it in the web panel,
  `POST /exam/login` and `GET /device/config` return **403 `device_not_approved`** (message names the PC).
  `/device/heartbeat` and `/device/unlock` keep working, so the PC shows up as "pending" in the admin device list.
- **Re-registering** an existing `machine_id` rotates the token **and drops the approval** (someone who learns an approved
  PC's machine id cannot take over its approval); the number stays. The app therefore registers only once and keeps its token.
- Since desktop 1.0.2 registration needs the center password: on first start (no stored token) the app shows a Setup screen
  (center password + optional PC name). After registering it shows "Waiting for administrator approval" (PC name + short
  machine id) and retries `GET /device/config` every 30 s; once approved it opens the code screen, which shows the PC
  number ("PC 7"). The hidden admin menu's "Re-register" asks for the center password again.

---

## v1.1 changes (server implemented; desktop client must follow)

All changes are additive or relax earlier errors; a v1.0 client keeps working except where noted.

**a) Timestamps.** Every timestamp in the API (`server_time`, `started_at`, `finished_at`, `expires_at`, `starts_at`,
`ends_at`) is `Y-m-d\TH:i:s.vP`, e.g. `2026-11-12T09:14:03.120+05:00` (milliseconds + offset, server timezone).
Module timers are whole seconds (`.000`). The client should send `changed_at` with milliseconds in the same format.

**b) `POST /exam/answers` — per-item validation.** The batch is a 422 `validation_failed` only when the envelope is
malformed: `answers` missing / not an array / empty / more than 200 items, an item that is not an object, or an item
without a string `client_uuid` (≤ 64 chars). Every other problem rejects only that item:

| `reason` | when |
|---|---|
| `invalid` | `part_id` / `question_id` not integers, `text` not a string or longer than 20 000 chars, `option_ids` not an array of integers, `changed_at` missing / not a date, `seq` not an integer ≥ 0 |
| `too_many_options` | more than 50 `option_ids`, or a `multiple_response` ("choose TWO") question with more selected options than the key has correct options (the web exam room refuses the same with 422 `reason: too_many_options`) |
| `invalid_question` | part not in a started module of this attempt, or question not in that part (unchanged) |
| `module_submitted`, `module_time_over` | unchanged (see e) for the offline exception) |

**c) Ordering — `seq`.** Optional per-item integer `seq` ≥ 0: a monotonic counter **per question per attempt**
kept by the client (persist it with the queue; never reset it during an attempt). Stored in `attempt_answers.client_seq`.
Last-write-wins: when both the stored answer and the item have a `seq`, the higher `seq` wins (equal → the later
request wins); otherwise `changed_at` decides (ms precision, equal → later request wins). A losing item is `stale`.

**d) Pause.** Items with `changed_at` ≥ the pause time are **not** final any more:
`{ "status": "deferred", "reason": "paused" }`. The client keeps them in its queue and re-sends them (same
`client_uuid`, same `seq`/`changed_at`) after `/exam/heartbeat` reports `paused: false`. Because resume moves the module
end forward by the pause length, the re-sent items are accepted as long as the module is still open. Items changed
before the pause are still accepted during the pause. (`rejected/paused` no longer occurs on the desktop API.)
Result statuses: `saved | duplicate | stale | rejected` are final (drop from the queue), `deferred` is not.

**e) Offline across the module end (late sync).** After a module ended (`finished_at` + 30 s grace) an item is still
accepted when all of these hold:
1. its `changed_at` ≤ the module's `finished_at`;
2. the PC was offline at the end — its last exam heartbeat before reconnecting is older than `finished_at`. The server
   records this per module (`attempt_types.offline_at_end`) before the first heartbeat after the grace moves
   `last_heartbeat_at`, so heartbeating first after a reconnect is fine;
3. the server time is ≤ `finished_at` + `desktop.offline_late_sync_minutes` (env `DESKTOP_OFFLINE_LATE_SYNC_MINUTES`, default 120).

Such items answer `{ "status": "saved", "late": true }`, the answer is marked `attempt_answers.late_synced = true`
(for review) and the module score is recalculated (a late essay is (re-)evaluated unless the Admin already confirmed
Writing). This also works when the module or the whole attempt is already submitted (auto-finish, force submit,
`attempts:close-old`): the batch is refused with 409 `attempt_finished` only when no module of the finished attempt
qualifies for late sync any more. Items changed after `finished_at` stay `rejected` / `module_time_over` or
`module_submitted`. A module's `finished_at` is never moved to the submit time when its time had already run out.

**f) Version gate.** 426 `client_outdated` is returned by `POST /exam/login` only. Requests with a valid exam token
are never 426 (an outdated client finishes the running exam and updates afterwards). `/device/*` was never gated.

**g) Exam token lifetime.** `expires_at` = max(mock `finished_at`, now) + sum of the durations of the mock's modules
+ 2 h (`desktop.token_sliding_hours`). Sliding: every `POST /exam/heartbeat` of an unfinished attempt extends the
token to at least now + 2 h. 401 responses on exam endpoints carry a specific `code`:

| code | meaning | client action |
|---|---|---|
| `session_revoked` | the token was deleted (login on another PC, `/exam/submit`, PC released by the invigilator) or the attempt is bound to another PC | stop the exam UI, keep unsent answers, show "This exam continues on another PC — ask the invigilator", back to the code screen |
| `session_expired` | the token ran out | back to the code screen; logging in again with the code continues the attempt |
| `unauthenticated` | no / malformed token | back to the code screen |

**h) Login on another PC.** `POST /exam/login` answers 409 `session_active_elsewhere` ("This exam is running on another
PC. Ask the invigilator to release it.") when the attempt is bound to a different PC that sent an exam heartbeat within
the last 90 s (`desktop.active_elsewhere_seconds`). Otherwise the login moves the attempt to this PC: the old PC's token
is revoked (`session_revoked`) and every other device's `current_attempt_id` for this attempt is cleared (a pending
remote unlock is never delivered to the wrong PC). Admin and Reception can release a PC from the live monitor:
`POST /monitor/attempts/{attempt}/release-device` (web, session auth; JSON `{ok, message, attempt}` for fetch requests)
clears `attempts.device_id`, the devices' `current_attempt_id` and the candidate's exam tokens.

**i) Login after the mock window.** After the mock's `finished_at`, login is still allowed for a candidate who has an
unfinished attempt (the PC died); only candidates without an attempt get 422 `mock_finished`. The same resume rule skips
`mock_not_active` and `mock_not_started` (the mock was deactivated or rescheduled mid-exam). An attempt created only by
an early Speaking band (no PC, no started written module) does not count as a resume. A finished attempt
answers 409 `attempt_finished` (checked first).

**j) Images.** `prefetch.images` still lists every `<img src>` as an absolute URL, including external hosts.
Contract: the client sends `X-Device-Token` / `Authorization` **only** to the API origin (`https://mynine.uz`);
images on any other origin must be fetched anonymously (no auth headers, no cookies). A failed image download must not
block the exam (show the alt text / an empty box).

**Audio delivery.** Unchanged for the client (`GET /exam/audio/...` with `Range`). With `DESKTOP_X_ACCEL_AUDIO=true`
the server answers with `X-Accel-Redirect` and nginx streams the file (206 for Range requests). nginx include
(FastPanel: `/etc/nginx/fastpanel2-sites/mynine_uz_usr/mynine.uz.includes`):

```nginx
location /_protected_audio/ {
    internal;
    alias /var/www/mynine_uz_usr/data/www/mynine.uz/storage/app/private/audio/;
}
```

(`storage/app/private` = root of the `local` disk, `audio/` = `AudioUploadService::DIRECTORY`; the location prefix is
`DESKTOP_X_ACCEL_AUDIO_LOCATION`, default `/_protected_audio/`.) Reload nginx before enabling the env flag; legacy files
still on the public disk are streamed by PHP. The web exam room's `/media/audio/{file}` uses the same mechanism.

**New storage:** `attempt_answers.client_seq` (unsigned bigint, nullable), `attempt_answers.late_synced` (bool, default
false), `attempt_types.offline_at_end` (bool, nullable) — migration `2026_11_11_000002_add_v11_sync_columns`.

---

## Multi-center (server, 2026-11)

The platform is rented to several learning centers. **A center is its Admin user**; mocks, candidates, attempts, Mock
Bank tests and exam PCs belong to one center (`owner_id` = the Admin's user id). The existing data belongs to the
**Mynine** center (code `MYNINE`).

- **Center code**: short, unique, uppercase `A-Z0-9`, 3–12 characters (Admin: Center settings, read-only there; set by
  the platform owner on the Centers page). The app asks for it together with the center password when registering a PC
  and sends it as `center_code` (case-insensitive) on `POST /device/register`.
- **Backward compatible**: a client that sends no `center_code` registers to the Mynine center, and only the Mynine
  center's password is accepted — exactly the old behaviour.
- A PC belongs to the center it registered with. Re-registering with another center's code moves it there (number and
  current attempt are cleared, approval is required again). PC numbers are unique per center.
- `GET /device/config`, `/device/background`, `/device/unlock` and the offline hash use the PC's center's settings;
  `config.center` = `{ code, name, logo_url, suspended }` (logo for the code screen; `logo_url` may be null).
- `POST /exam/login` only finds candidates of the PC's center: any other code is 422 `invalid_code` (other centers are
  never revealed). Candidate codes stay six digits and unique across all centers. Exam tokens only work through a PC
  of the candidate's center.
- **Suspended center** (suspended by the platform owner, or `contract_until` has passed): `POST /exam/login` and
  `POST /device/register` answer **403 `center_suspended`** ("This center is suspended…"). The app shows the message on
  the code / registration screen; it is not retried automatically. An exam that is already running is not interrupted.
  The center's staff can still sign in to the web panel read-only (view and print results).

