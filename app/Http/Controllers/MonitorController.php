<?php

namespace App\Http\Controllers;

use App\Models\Attempt;
use App\Services\ExamService;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;

/**
 * Live-monitor actions on a running exam attempt (web, session auth).
 * Admin: extra time, pause/resume, force submit. Admin + Reception: remote unlock of the PC.
 */
class MonitorController extends Controller
{
    public function __construct(private readonly ExamService $exam) {}

    public function extraTime(Request $request, Attempt $attempt): RedirectResponse
    {
        $data = $request->validate([
            'minutes' => ['required', 'integer', 'min:1', 'max:120'],
        ]);

        if ($attempt->finished_at !== null) {
            return back()->with('error', 'Imtihon allaqachon yakunlangan.');
        }

        $extended = $this->exam->addTime($attempt, (int) $data['minutes']);

        return $extended > 0
            ? back()->with('success', "{$data['minutes']} daqiqa qo'shildi.")
            : back()->with('error', "Hozir davom etayotgan bo'lim yo'q.");
    }

    public function pause(Attempt $attempt): RedirectResponse
    {
        if ($attempt->finished_at !== null) {
            return back()->with('error', 'Imtihon allaqachon yakunlangan.');
        }

        $this->exam->pause($attempt);

        return back()->with('success', "Imtihon to'xtatildi.");
    }

    public function resume(Attempt $attempt): RedirectResponse
    {
        $this->exam->resume($attempt);

        return back()->with('success', 'Imtihon davom ettirildi.');
    }

    public function forceSubmit(Attempt $attempt): RedirectResponse
    {
        $this->exam->forceSubmit($attempt);

        return back()->with('success', 'Imtihon majburan yakunlandi.');
    }

    public function unlock(Attempt $attempt): RedirectResponse
    {
        $attempt->forceFill(['unlock_requested_at' => now()])->save();

        return back()->with('success', "Kompyuterni ochish so'rovi yuborildi.");
    }
}
