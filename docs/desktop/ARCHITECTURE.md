# Mynine Desktop Exam System — Architecture

Mynine.uz is the system of **one learning center**. This document is the single source of truth for the
mock-exam + desktop-client work on branch `feat/desktop-mock-system`. The API contract lives in
[API.md](API.md).

## Product decisions (fixed)

| Topic | Decision |
|---|---|
| Roles | `Admin`, `Reception`, `Student` only. Teacher role removed (migration `2026_11_10_000001`). |
| Open tests | Practice tests (`tests.purpose = practice`, `open = 1`) are solved by anyone on the website. Unchanged. |
| Mock tests | Live in a separate **Mock Bank** (`tests.purpose = mock`). Never listed in practice/all-test, never startable outside a mock. |
| Mock Bank granularity | Per **module** (a `test_types` row = one L, R or W module of a test). A mock picks one module per type, modules may come from different tests. |
| Mock Bank storage | Mock Bank tests have **no folder** (`tests.folder_id = NULL`, migration `2026_11_10_000015`); admins own them directly. "Move to practice" asks for the target folder. |
| PDF import | Mock Bank card → "Import from PDF": Listening / Reading question papers (+ optional answer key, optional Listening audio). One queued `ImportMockModuleJob` per module: text extraction (`DocumentTextExtractor`, smalot/pdfparser) → AI (`OpenAIService::parseMockModule`, model `OPENAI_IMPORT_MODEL`) → strict normalisation (`MockImportNormalizer`, answers applied by question number) → rows (`MockTestImporter`). Status in `test_imports`. Writing tasks and pictures are added by hand in the module editor. |
| Reuse rule | A module used in a mock is not auto-picked again for **14 days** (`test_types.last_used_at`). Manual pick shows a warning. |
| Candidates | **Code-only guests** (`mock_students`). Phone is **mandatory** for new candidates; it is used to detect repeat candidates (warn if a candidate already did a selected module). No account linking. |
| Exam order | Listening → Reading → Writing on the desktop app, then Speaking face-to-face by time slot. |
| Writing grading | AI evaluates immediately (existing `EvaluateEssayJob`), **Admin confirms** (`attempt_types.reviewed_at`). |
| Speaking | Admin assigns time slots (`mock_students.speaking_at`) and enters the band manually (existing `attempt-type.store`). |
| Results | Printed at reception. Result sheet = module bands (L, R, W, S) + overall band only. The desktop app never shows scores: after submit it shows "Completed" and returns to the code screen. |
| Desktop client | Flutter, Windows 10/11, ≤ 20 PCs, **English UI only**, lockdown/kiosk, offline-tolerant (internet sometimes drops). No code signing (Defender allow-listed once). |
| Updates | Self-updating from the **static folder `https://mynine.uz/desktop/`** (server `public/desktop/`: `version.json` + installers, uploaded by hand; not GitHub, no DB). Visible "Check for updates" button on the code screen (never during an exam); rollout to all PCs at once; auto-rollback if the new version fails its self-check. PCs only install a **higher** version, so a manual rollback is a new higher version built from the old code. |
| Lockdown exit | Center-wide exit password (setting `desktop_exit_password`, stored hashed). Admin **and** Reception may unlock (password on the PC, or remote unlock from the monitor). |

## Role matrix

| Action | Admin | Reception | Student |
|---|---|---|---|
| Solve open tests (web) | ✓ | ✓ | ✓ |
| Tests, Mock Bank, answer keys, content editing | ✓ | — | — |
| Create / configure mocks, pick modules | ✓ | — | — |
| Add candidates, print code cards, check-in (attendance) | ✓ | ✓ | — |
| Live monitor (view) | ✓ | ✓ | — |
| Monitor actions: extra time, pause/resume, force submit | ✓ | — | — |
| Remote unlock of a desktop PC | ✓ | ✓ | — |
| Confirm Writing, enter Speaking band, assign speaking slots | ✓ | — | — |
| Print result sheet, mark "delivered" | ✓ | ✓ | — |
| Users, devices, settings | ✓ | — | — |

## Data model changes

Existing hierarchy (unchanged): `tests → test_types (one per module: Listening/Reading/Writing/Speaking via types) → parts → sections → questions → options`.
Attempts: `attempts → attempt_types (per module timer/score) → attempt_parts → attempt_answers → attempt_answer_options`.

New / changed columns:

- `tests.purpose` (`practice`|`mock`, default `practice`), `tests.bank_status` (`draft`|`ready`|`archived`, default `draft`).
  Data migration: every test referenced by `mocks.test_id` → `purpose=mock`, `open=0`, `bank_status=ready`.
- `test_types.last_used_at` (nullable timestamp) — set when a mock using the module goes live / is created.
- `mocks.require_desktop` (bool, default false), `mocks.speaking_starts_at` (nullable datetime), `mocks.speaking_slot_minutes` (smallint, default 15). `mocks.test_id` becomes nullable (kept for legacy mocks).
- `mock_modules` (new): `id, mock_id → mocks (cascade), type_id → types, test_type_id → test_types, timestamps, unique(mock_id, type_id)`.
  Data migration: each existing mock gets one module row per `test_types` row of its `test_id` (types that have parts).
- `mock_students`: `checked_in_at`, `speaking_at`, `result_printed_at`, `result_delivered_at` (nullable datetimes), `delivered_by` (nullable FK users).
- `attempts`: `device_id` (nullable FK devices, null on delete), `last_heartbeat_at`, `paused_at`, `unlock_requested_at` (nullable datetimes). `attempts.test_id` stays; for module mocks it is the test of the first module (legacy code paths keep working).
- `attempt_types`: `reviewed_at` (nullable datetime), `reviewed_by` (nullable FK users).
- `attempt_violations` (new): `id, attempt_id (cascade), device_id (nullable), type string(40), detail json nullable, occurred_at datetime, timestamps`, index on `attempt_id`. `attempts.tab_switch_count` is still incremented for type `focus_lost` for backward compatibility.
- `devices` (new): `id, machine_id string unique, name, token_hash string(64), app_version, os_version, ip, last_seen_at, is_blocked bool, current_attempt_id nullable, timestamps`.
- No release table: releases are described by the static `public/desktop/version.json` (see API.md "Updates"), read on the server by `App\Services\Desktop\ReleaseManifest` for `min_version` (426) and the admin devices page (latest version).
- `tests.folder_id` nullable; existing `purpose=mock` tests detached from their folders.
- `test_imports` (new): `id, test_id (cascade), user_id (nullable), status (queued|running|done|failed), replace bool, files json, modules json ({Listening: {status, message, warnings[], parts, questions}}), finished_at, timestamps`.
- `settings` (new): `key string primary, value text nullable, timestamps`. Keys: `desktop_exit_password` (bcrypt hash), `desktop_exit_password_offline` (`pbkdf2_sha256$<iterations>$<salt_b64>$<hash_b64>` so the app can verify offline).

Rules enforced server-side:

- `Attempt::allowsPart(Part $part)`: for a mock with modules → `part.test_type_id ∈ mock_modules.test_type_id`; otherwise `part.test_type.test_id == attempt.test_id`. Every exam endpoint (web and API) uses this instead of the old test_id comparison.
- Mock tests (`purpose=mock`) cannot be started from `attempt.store` / practice; they are reachable only through a mock attempt.
- If `mocks.require_desktop` is true, the web candidate entry (`/mock-student/enter`) refuses with a message telling the candidate to use the desktop app.
- Answer keys never leave the server for candidates: `options.is_correct`, `questions.answer_text`, `attempt_answers.is_correct/score/review_note*` are stripped (existing `hideAnswerKeys` logic, moved into `App\Services\ExamService`).
- While `attempts.paused_at` is set, answers are rejected (409) and module timers are frozen; on resume all unsubmitted `attempt_types.finished_at` / `attempt_parts.finished_at` are shifted by the pause duration.
- Results are never returned by the candidate API.

## Shared exam logic

`App\Services\ExamService` (new) owns: `hideAnswerKeys`, `autoFinishExpiredTypes`, `finishTypeWithEvaluation`, `mockWindowError`, `startModule` (creates AttemptType + AttemptParts with timers), `saveAnswer` (idempotent), `pause/resume/addTime/forceSubmit`. `PracticeController` and `AttemptAnswerController` (web) and `Api\V1\*` controllers (desktop) both call it, so web and desktop behave identically.

## Desktop client (Flutter)

Separate repository/folder: `/Users/macpro/Desktop/myProjects/mynine-desktop`.

Screens: Code entry (+ version label, "Check for updates", hidden admin menu) → Rules → Sound check → Listening → Reading → Writing → Completed (auto-return to code entry after 10 s). Pause overlay when the server reports `paused`.

Key behaviour:

- **Prefetch**: after login, download the whole exam (`GET /exam/prefetch`) and all audio files into the local cache before the Rules screen; show progress. The exam must survive internet loss after that point.
- **Offline answers**: every change is written to local SQLite first, then sent in batches (`POST /exam/answers`) with a client UUID per change; retried until acknowledged. `POST /exam/submit` only after the queue is empty (or after a 5 min grace while offline — then keep retrying in the background on the Completed screen; never drop data).
- **Timers**: based on server `finished_at` + clock offset from `server_time`, never the local clock alone.
- **Lockdown (Windows)**: native C++ in `windows/runner` exposed via MethodChannel `mynine/lockdown`: low-level keyboard hook (Win, Alt+Tab, Alt+F4, Ctrl+Esc, Alt+Esc), `SetWindowDisplayAffinity(WDA_EXCLUDEFROMCAPTURE)`, fullscreen topmost kiosk, monitor count, banned process scan every 5 s, clipboard clear, focus-loss detection. Violations are queued and sent to `POST /exam/violations`.
- **Exit**: only after submit, with the exit password (verified online, or offline against the cached PBKDF2 hash), or by remote unlock (`unlock: true` in heartbeat).
- **Updates**: `GET {site}/desktop/version.json?t=<epoch>` (static, see API.md "Updates"); download `{site}/desktop/<file>` with resume, verify size + SHA-256, run installer silently (`/VERYSILENT /SUPPRESSMSGBOXES /NORESTART`), relaunch; on failed self-check after update, reinstall the previous installer kept in `%LOCALAPPDATA%\Mynine\previous\`. Random 0–10 min delay before automatic download (not for the manual button).
- **Installer**: Inno Setup script in the repo; GitHub Actions `windows-latest` workflow builds `mynine-setup-<version>.exe`, its SHA-256 and a ready `version.json`. Release = upload the exe to the server's `public/desktop/` (keeping older installers: PCs download `mynine-setup-<installed version>.exe` from there as their rollback copy), then update `version.json`.
