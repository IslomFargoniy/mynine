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

    // Exam token lifetime when the mock has no end time.
    'token_fallback_hours' => 6,

    'heartbeat_seconds' => 20,

    // Web admin: a Mock Bank module is not auto-picked again for this many days (manual pick warns).
    'module_reuse_days' => 14,

    // Web admin: a PC / attempt counts as online when it was seen within this many seconds.
    'online_seconds' => 60,

    'violation_batch_seconds' => 10,

    'banned_processes' => [
        'anydesk.exe',
        'teamviewer.exe',
        'discord.exe',
        'obs64.exe',
        'telegram.exe',
        'chrome.exe',
        'msedge.exe',
        'firefox.exe',
        'zoom.exe',
        'skype.exe',
    ],

];
