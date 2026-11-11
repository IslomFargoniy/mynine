<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Mynine desktop exam client
    |--------------------------------------------------------------------------
    | See docs/desktop/ARCHITECTURE.md and docs/desktop/API.md.
    */

    // Offline answers whose changed_at is before the module end are accepted this long after it.
    'answer_grace_seconds' => 30,

    // A remote unlock from the monitor is delivered to the PC only within this window.
    'unlock_ttl_minutes' => 15,

    // Exam token lifetime when the mock has no end time (legacy, v1.0).
    'token_fallback_hours' => 6,

    // v1.1 token: expires at max(mock end, now) + module durations + this many hours, and every exam
    // heartbeat of a running attempt keeps it valid for at least this many hours.
    'token_sliding_hours' => 2,

    // v1.1: answers changed before a module ended are still accepted this long after the end when the
    // PC was offline at the end (marked attempt_answers.late_synced).
    'offline_late_sync_minutes' => (int) env('DESKTOP_OFFLINE_LATE_SYNC_MINUTES', 120),

    // v1.1: login on another PC is refused (409 session_active_elsewhere) while the bound PC sent an exam
    // heartbeat within this many seconds; the invigilator can release the PC from the monitor.
    'active_elsewhere_seconds' => 90,

    // Serve exam audio through nginx (X-Accel-Redirect to an internal location) instead of PHP.
    // nginx: location /_protected_audio/ { internal; alias <storage/app/private/audio/>; }
    'x_accel_audio' => (bool) env('DESKTOP_X_ACCEL_AUDIO', false),
    'x_accel_audio_location' => env('DESKTOP_X_ACCEL_AUDIO_LOCATION', '/_protected_audio/'),

    'heartbeat_seconds' => 20,

    // Web admin: a Mock Bank module is not auto-picked again for this many days (manual pick warns).
    'module_reuse_days' => 14,

    // Web admin: a PC / attempt counts as online when it was seen within this many seconds.
    'online_seconds' => 60,

    'violation_batch_seconds' => 10,

    // Processes the desktop app closes (same-user ones) and reports during an exam (sent via GET /device/config).
    // Override with DESKTOP_BANNED_PROCESSES="a.exe,b.exe" (comma separated, replaces the list).
    // System processes (csrss, winlogon, explorer, dwm, svchost, lsass, …) are never terminated by the app.
    'banned_processes' => env('DESKTOP_BANNED_PROCESSES')
        ? array_values(array_filter(array_map(fn ($p) => strtolower(trim($p)), explode(',', (string) env('DESKTOP_BANNED_PROCESSES')))))
        : [
            'taskmgr.exe',
            'processhacker.exe',
            'procexp.exe',
            'procexp64.exe',
            'cmd.exe',
            'powershell.exe',
            'pwsh.exe',
            'windowsterminal.exe',
            'mstsc.exe',
            'teams.exe',
            'ms-teams.exe',
            'slack.exe',
            'whatsapp.exe',
            'skype.exe',
            'zoom.exe',
            'chrome.exe',
            'msedge.exe',
            'firefox.exe',
            'opera.exe',
            'brave.exe',
            'yandex.exe',
            'browser.exe',
            'anydesk.exe',
            'teamviewer.exe',
            'rustdesk.exe',
            'discord.exe',
            'telegram.exe',
            'obs64.exe',
            'obs32.exe',
            'snippingtool.exe',
            'screenclippinghost.exe',
            'notepad.exe',
            'wordpad.exe',
            'winword.exe',
        ],

    // Numbered questions in a full Listening / Reading paper (Mock Bank readiness check).
    'questions_per_paper' => 40,

];
