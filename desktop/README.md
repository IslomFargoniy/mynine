# Mynine Exam — desktop client

Flutter desktop app for the IELTS mock exams of the Mynine learning centre.
It runs **only the exam process** on the centre's Windows 10/11 PCs:

code entry → instructions → sound check → **Listening → Reading → Writing** →
"Completed" (returns to the code screen after 10 s; scores are never shown).

The design reproduces the web practice exam room of mynine.uz
(`resources/js/pages/practice/index.tsx` and `components/practice/*`); all
colours/sizes live in `lib/core/theme/web_tokens.dart`.

Server contract: `mynine.uz/docs/desktop/API.md` (Desktop API v1).
Product decisions: `mynine.uz/docs/desktop/ARCHITECTURE.md`.

## Features

- **First-run Setup**: without a device token the app asks for the **center
  password** (+ optional PC name) and only then registers (`POST /device/register`;
  wrong password → error, server without a center password → "set it in Desktop
  settings first"). Never registers on its own. Then "Waiting for administrator
  approval" (PC name + short machine id, 30 s config poll) until an Admin approves
  the PC and gives it a **number**; the code screen shows it as a large "PC 7"
  badge and the exam header shows it too (heartbeat picks up renumbering).
  Re-registering (admin menu, asks for the center password) drops the approval but
  the server keeps the number. Device heartbeat on the code screen, cached device
  config (banned processes, offline center-password hash).
- Exam login by code, **prefetch** of the whole exam (parts, audio with SHA-256,
  images) before the instructions — the exam survives internet loss after that.
- Every question type of the web exam room: multiple choice, multiple response
  ("choose TWO", `number_count`), true/false/not given, yes/no, fill blank (`{}`),
  complete section (`{…}` gaps in the section HTML), matching / matching
  headings (drag or click-to-place), drag and drop, essay with word counter.
- Own TinyMCE-HTML renderer (no webview): paragraphs, headings, lists, tables,
  images, inline styles, inline gaps; Inspera highlighter + candidate notes stored
  as character offsets in SQLite.
- **Offline answer queue** (drift/SQLite): each change gets a `client_uuid`,
  is stored locally first, sent in batches of ≤ 200, retried with exponential
  backoff, never dropped. Final submit only after the queue is empty (or after a
  5 min offline grace — then it keeps syncing in the background).
- Timers from the server `finished_at` + clock offset (`server_time`), extra
  time / pause / force submit / remote unlock via the exam heartbeat.
- Listening audio plays once from the cached file, positioned from the server
  timer, no pause/seek (media_kit).
- **Lockdown on Windows** (`windows/runner/lockdown_channel.cpp`, MethodChannel
  `mynine/lockdown`), active while the app is locked (kiosk) and fully undone on
  unlock / exit:
  - fullscreen topmost kiosk; every other visible top-level window is minimized on
    lock and again whenever the app takes the focus back;
  - low-level keyboard hook: Win and every Win+key, Alt+Tab, Ctrl+Alt+Tab, Alt+F4,
    Alt+Esc, Ctrl+Esc, Ctrl+Shift+Esc, Alt+Space, PrintScreen, keyboard launch keys;
  - per-user policies (HKCU): `Policies\System` `DisableTaskMgr`,
    `DisableLockWorkstation`, `DisableChangePassword` = 1 (Task Manager and Lock
    disappear from Ctrl+Alt+Del; sign-out is left on so a PC can always be
    recovered); precision touchpad `ThreeFinger/FourFinger Slide/Tap Enabled` = 0
    (**some Windows builds apply touchpad changes only after the next sign-in**);
    toast notifications off (`Notifications\Settings\NOC_GLOBAL_SETTING_TOASTS_ENABLED`,
    `PushNotifications\ToastEnabled` = 0). The original values are saved first to
    `%LOCALAPPDATA%\Mynine\lockdown_applied.ini`, restored on unlock / exit / sign-out,
    and at the next start if the app crashed (delete the values by hand only if the
    app is uninstalled while locked);
  - banned programs (list from `GET /device/config`, default in the server's
    `config/desktop.php`) are **closed** (this user's session only, never system
    processes such as csrss, winlogon, explorer, dwm, svchost, lsass) when the exam
    starts and on every 5 s scan, and reported as `banned_process`
    `{process, terminated}`. The rules screen lists the ones still running and keeps
    **Start** disabled until they are closed ("Close these programs" button);
  - `SetWindowDisplayAffinity(WDA_EXCLUDEFROMCAPTURE)`, monitor count, clipboard
    clear, focus-loss events with the process that took the focus
    (`focus_lost {process}`), VM detection, `MachineGuid` as machine id.
  Violations are queued and sent to the server.
- **Self-update** from the static folder `https://mynine.uz/desktop/`
  (`version.json` + installers): check on start, every 30 min on the code screen
  (random 0–10 min delay before the automatic download) and with the
  "Check for updates" button (center password needed in kiosk mode). Resumable
  download, SHA-256 check, silent Inno Setup install and relaunch, automatic
  rollback to the previous installer when the new version fails its self-check
  (API reachable + code screen rendered) within 2 minutes.
- Hidden admin menu: **Ctrl+Shift+M** → center password (online, or offline
  PBKDF2) → re-register (PC name + center password), server URL, check for updates, exit.

## Project layout

```
lib/
  app/            bootstrap (DI), router (stage-driven go_router), theme, kiosk controller
  core/           api (interface, Dio client, fake API, errors), config, crypto (PBKDF2),
                  storage (paths, secure settings), theme (web tokens, Tailwind palette),
                  time (server clock), util (semver)
  data/           freezed models (API.md), drift database, repositories
                  (answer queue, violation queue, sync service, exam, device)
  features/       code_entry, prefetch, rules, sound_check, exam (controller, shell,
                  listening audio), questions, passage (HTML renderer, highlighter, notes),
                  completed, updater, admin
  platform/lockdown  Dart interface over MethodChannel + no-op + violation monitor
windows/runner/   lockdown_channel.{h,cpp} (native kiosk), single-instance mutex
installer/        mynine.iss (Inno Setup 6)
assets/fonts/     Inter (SIL OFL 1.1)
test/             unit, widget, flow and golden tests
```

## Development

Requirements: Flutter 3.47 (Dart 3.13). On Windows also Visual Studio 2022 with
"Desktop development with C++".

```bash
flutter pub get
dart run build_runner build          # freezed / json_serializable / drift
flutter analyze
flutter test                          # golden tests run on macOS only (tag: golden)
```

### Demo mode (no server)

```bash
flutter run -d windows --dart-define=API_FAKE=true     # or -d macos
```

The Setup screen asks for the center password: **`mynine`** in demo mode (also used
for unlock and the admin menu); the demo PC is approved right away as "PC 7". Then
use any code starting with **DEMO** (e.g. `DEMO1234`). Extra flags:
`--dart-define=FAKE_UPDATE=true` (offers an update), `--dart-define=FAKE_UNAPPROVED=true`
(PC stays on "Waiting for administrator approval").
Lockdown is disabled in demo mode.

### Against a server

```bash
flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1 --dart-define=KIOSK=false
```

`KIOSK=false` keeps the window normal while developing. The server URL can also
be changed at runtime in the admin menu (Ctrl+Shift+M).

### macOS notes (dev only)

The macOS build does not bundle libmpv (`media_kit_libs_macos_audio` needs
CocoaPods), so Listening audio shows an error icon on macOS; everything else
works. To hear audio on macOS: install CocoaPods and
`flutter pub add media_kit_libs_macos_audio`.

## Releasing an update

Updates are plain static files: nginx serves the server's `<site>/public/desktop/`
as `https://mynine.uz/desktop/`. The app reads `desktop/version.json`
(`?t=<epoch>` cache buster, no auth) and downloads `desktop/<file>` from the same folder.

```json
{"version":"1.2.0","file":"mynine-setup-1.2.0.exe","sha256":"<64 hex>","size":12345678,
 "mandatory":false,"min_version":null,"notes":"…","published_at":"2026-11-10T12:00:00Z"}
```

1. Bump `version:` in `pubspec.yaml` (semver, e.g. `1.2.0+12`).
2. Push an annotated tag `git tag -a desktop-v1.2.0 -m "Release notes"` (or run the
   `desktop-windows-build` workflow manually; it lives in the repo root `.github/workflows/`).
3. Download the artifact `mynine-setup-1.2.0`: installer, `.sha256` and a ready
   `version.json` (sha256, size, notes from the tag message, `mandatory: false`,
   `min_version: null`).
4. Upload `mynine-setup-1.2.0.exe` to `<site>/public/desktop/` on the server.
   **Keep the previous installers there**: before installing an update, a PC
   downloads `mynine-setup-<its current version>.exe` from that folder as its
   rollback copy (if it does not already have one in `%LOCALAPPDATA%\Mynine\previous\`).
   Installers are not committed to git (`public/desktop/*.exe` is ignored).
5. Update `public/desktop/version.json` last (after the exe is fully uploaded) with the
   values from the CI `version.json`. Set `"mandatory": true` to make the update dialog
   non-dismissable; set `"min_version"` to block older apps from starting an exam (the
   server answers 426 `client_outdated` to `/exam/*` for versions below it). The server
   copy of `version.json` is tracked in git, so commit the change (or edit it on the
   server and commit later; both must agree).
6. Done. All PCs pick it up within ~30–40 min on the code screen (or immediately with
   "Check for updates"). A PC never updates during an exam.

A missing/invalid `version.json`, an empty `sha256`, `size: 0` or a missing `file` means
"no update" on the PCs — never an error that blocks an exam. A download whose size or
SHA-256 differs from `version.json` is discarded.

**Rollback.** A PC only installs when `version.json`'s `version` is **higher** than the
installed one, so pointing `version.json` back to an older file does nothing on PCs that
already updated. Options:

- Automatic: if the new version cannot reach the server and render the code screen within
  2 minutes after the update, the PC reinstalls the installer kept in
  `%LOCALAPPDATA%\Mynine\previous\` by itself.
- Manual: build the old (good) code with a **new, higher** version number (e.g. 1.2.1 =
  1.1.0's code), upload it and publish it in `version.json` like any release.
- Pointing `version.json` back to the old installer only stops PCs that have not
  updated yet from taking the bad version.

## Installing on a centre PC (checklist)

- [ ] Windows 10 **2004 (build 19041) or newer** / Windows 11 — required for
      `WDA_EXCLUDEFROMCAPTURE` (older builds fall back to `WDA_MONITOR`).
- [ ] Sign in as the **exam account** (a standard, non-admin user) and run
      `mynine-setup-<version>.exe` (per-user install to
      `%LOCALAPPDATA%\Programs\Mynine Exam`, no admin rights or UAC needed; creates the
      desktop/start-menu shortcuts and the auto-start shortcut for that account).
- [ ] **Microsoft Defender**: the app is not code-signed. Add allow-list entries for
      `%LOCALAPPDATA%\Programs\Mynine Exam\mynine_desktop.exe` and
      `%LOCALAPPDATA%\Mynine\updates\` (Windows Security → Virus & threat protection →
      Exclusions), and allow the app in SmartScreen once.
- [ ] Silent updates install per-user, so they need no elevation and show no UAC prompt.
      Keep the exam account a **standard user** (not an administrator).
- [ ] Auto-start: the installer adds a Startup shortcut (task "Start automatically").
      Optionally enable automatic sign-in of the exam account.
- [ ] **OS-level lockdown (strongest layer).** Ctrl+Alt+Del (and Win+L) cannot be
      blocked by any application. The app removes Task Manager / Lock / Change password
      from that screen for the exam account while it runs, but for real exams also:
  - use a **dedicated standard (non-admin) exam Windows account** with automatic
    sign-in (`netplwiz` or Sysinternals Autologon), used for nothing else;
  - preferably **Assigned Access / Shell Launcher** (Windows 10/11 Pro/Enterprise/
    Education) so the exam account's shell *is* the Mynine app;
  - or at least **Group Policy** on the exam account (User Configuration →
    Administrative Templates → System → Ctrl+Alt+Del Options: Remove Task Manager,
    Remove Lock Computer, Remove Change Password; System → Logon → "Hide entry points
    for Fast User Switching"). Keep **Sign out** available so staff can always recover
    a PC. Win+L is disabled by `DisableLockWorkstation`.
- [ ] Touchpad laptops: after the first exam session sign out and back in once, so the
      disabled 3/4-finger gestures take effect on builds that need it.
- [ ] Single monitor only (a second monitor is reported as a violation).
- [ ] Set the **center password** on the server first (admin panel → Desktop settings,
      or `php artisan desktop:center-password <password>`).
- [ ] First start: the app shows **Set up this PC** → enter the center password and,
      optionally, the PC name (e.g. `PC-07`). Then approve the PC in the mynine.uz admin
      device list and give it its **number** (the free one is prefilled); the app
      leaves "Waiting for administrator approval" within 30 s and shows "PC 7".
- [ ] Check "Version x.y.z" and "Online" on the code screen; run a demo code exam.

Local data: `%LOCALAPPDATA%\Mynine\` (`data\mynine.sqlite` = queued answers, highlights,
notes; `exam\` = cached exam/audio; `updates\`, `previous\` = installers).
