<?php

namespace App\Http\Controllers;

use App\Models\Attempt;
use App\Models\AttemptAnswer;
use App\Models\AttemptType;
use App\Models\AttemptViolation;
use App\Models\Device;
use App\Models\Mock;
use App\Services\ExamService;
use App\Services\MockBankService;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Inertia\Inertia;
use Inertia\Response;

/**
 * Live monitor of a mock (view: Admin + Reception) and actions on a running attempt.
 * Admin: extra time, pause/resume, force submit. Admin + Reception: remote unlock of the PC.
 *
 * Actions answer JSON for fetch/axios requests (Accept: application/json, not Inertia) and
 * redirect back with a flash message otherwise.
 */
class MonitorController extends Controller
{
    public function __construct(private readonly ExamService $exam) {}

    public function index(Request $request): Response
    {
        $this->authorize('operate', Mock::class);

        $columns = ['id', 'name', 'started_at', 'finished_at', 'active', 'require_desktop'];
        $runningAttempts = fn ($q) => $q->whereNull('finished_at');

        // Current mocks (±1 day), plus any mock a candidate is still writing (resumed after the mock's end).
        $mocks = Mock::query()
            ->withoutEagerLoads()
            ->where(fn ($q) => $q
                ->where(fn ($w) => $w
                    ->where(fn ($f) => $f->where('finished_at', '>=', now()->subDay())->orWhereNull('finished_at'))
                    ->where('started_at', '<=', now()->addDay()))
                ->orWhereHas('attempts', $runningAttempts))
            ->withCount(['attempts', 'attempts as running_count' => $runningAttempts])
            ->orderByDesc('started_at')
            ->get($columns);

        $mockId = $request->integer('mock_id') ?: null;
        $mock = $mockId ? Mock::withoutEagerLoads()->find($mockId) : null;
        if ($mock && ! $mocks->contains('id', $mock->id)) {
            // Opened from an older mock's page: keep it in the dropdown so the selection matches the list.
            $mocks->push(Mock::withoutEagerLoads()->withCount('attempts')->find($mock->id, $columns));
        }
        // Default: the mock candidates are writing right now, then today's / an open / the latest mock.
        $mock ??= $mocks->first(fn (Mock $m) => $m->running_count > 0) ?? Mock::pickDefault($mocks);

        return Inertia::render('monitor/index', [
            'mocks' => $mocks->map(fn (Mock $m) => [
                'id' => $m->id,
                'name' => $m->name,
                'started_at' => $m->started_at,
                'finished_at' => $m->finished_at,
                'status' => $m->status,
                'attempts_count' => $m->attempts_count,
            ]),
            'mock' => $mock?->only(['id', 'name', 'started_at', 'finished_at', 'require_desktop']),
            'attempts' => $mock ? $this->attemptRows($mock) : [],
            'serverTime' => now()->toIso8601String(),
            'canControl' => $request->user()->isCenterAdmin(),
            'violationTypes' => AttemptViolation::TYPES,
        ]);
    }

    public function extraTime(Request $request, Attempt $attempt): JsonResponse|RedirectResponse
    {
        $this->authorizeAttempt('examine', $attempt);

        $data = $request->validate([
            'minutes' => ['required', 'integer', 'min:1', 'max:120'],
        ]);

        if ($attempt->finished_at !== null) {
            return $this->respond($request, $attempt, false, __('exam_already_finished'));
        }

        $extended = $this->exam->addTime($attempt, (int) $data['minutes']);

        return $extended > 0
            ? $this->respond($request, $attempt, true, __('extra_time_added', ['minutes' => $data['minutes']]))
            : $this->respond($request, $attempt, false, __('no_running_module'));
    }

    public function pause(Request $request, Attempt $attempt): JsonResponse|RedirectResponse
    {
        $this->authorizeAttempt('examine', $attempt);

        if ($attempt->finished_at !== null) {
            return $this->respond($request, $attempt, false, __('exam_already_finished'));
        }

        $this->exam->pause($attempt);

        return $this->respond($request, $attempt, true, __('exam_paused'));
    }

    public function resume(Request $request, Attempt $attempt): JsonResponse|RedirectResponse
    {
        $this->authorizeAttempt('examine', $attempt);

        $this->exam->resume($attempt);

        return $this->respond($request, $attempt, true, __('exam_resumed'));
    }

    public function forceSubmit(Request $request, Attempt $attempt): JsonResponse|RedirectResponse
    {
        $this->authorizeAttempt('examine', $attempt);

        $this->exam->forceSubmit($attempt);

        return $this->respond($request, $attempt, true, __('exam_force_submitted'));
    }

    public function unlock(Request $request, Attempt $attempt): JsonResponse|RedirectResponse
    {
        $this->authorizeAttempt('operate', $attempt);

        $attempt->forceFill(['unlock_requested_at' => now()])->save();

        return $this->respond($request, $attempt, true, __('unlock_requested'));
    }

    /**
     * Release the PC binding of an attempt (PC broken / candidate moved): the old PC's exam token stops
     * working (401 session_revoked) and the candidate can log in on another PC right away.
     */
    public function releaseDevice(Request $request, Attempt $attempt): JsonResponse|RedirectResponse
    {
        $this->authorizeAttempt('operate', $attempt);

        if ($attempt->finished_at !== null) {
            return $this->respond($request, $attempt, false, __('device_release_finished'));
        }

        DB::transaction(function () use ($attempt) {
            Device::where('current_attempt_id', $attempt->id)->update(['current_attempt_id' => null]);
            $attempt->forceFill(['device_id' => null])->save();
            $attempt->mockStudent?->tokens()->delete();
            // The next PC counts `seq` from 1 again: drop the old counters so changed_at decides.
            AttemptAnswer::whereHas('attempt_part', fn ($q) => $q->where('attempt_id', $attempt->id))
                ->whereNotNull('client_seq')
                ->update(['client_seq' => null]);
        });

        return $this->respond($request, $attempt, true, __('device_released'));
    }

    /**
     * Monitor actions work on mock attempts of the current center only ({attempt} is already limited to the
     * current center by the Attempt scope; the policy checks the mock's center again).
     */
    private function authorizeAttempt(string $ability, Attempt $attempt): void
    {
        $mock = $attempt->mock_id ? Mock::withoutEagerLoads()->find($attempt->mock_id) : null;
        abort_unless($mock, 404);
        $this->authorize($ability, $mock);
    }

    private function respond(Request $request, Attempt $attempt, bool $ok, string $message): JsonResponse|RedirectResponse
    {
        if ($request->expectsJson() && ! $request->header('X-Inertia')) {
            $attempt->refresh();

            return response()->json([
                'ok' => $ok,
                'message' => $message,
                'attempt' => $this->attemptRow($attempt->load(['attempt_types.type', 'device:id,name,number,last_seen_at', 'mockStudent'])),
            ], $ok ? 200 : 409);
        }

        return back()->with($ok ? 'success' : 'error', $message);
    }

    /**
     * @return array<int, array<string, mixed>>
     */
    private function attemptRows(Mock $mock): array
    {
        return Attempt::query()
            ->where('mock_id', $mock->id)
            ->with([
                'attempt_types.type',
                'device:id,name,number,last_seen_at',
                'mockStudent' => fn ($q) => $q->withoutEagerLoads(),
                'violations' => fn ($q) => $q->latest('occurred_at')->limit(500),
            ])
            ->orderBy('name')
            ->get()
            // Exam-room order: PCs by their number, then attempts without a numbered PC by name.
            ->sortBy([
                fn (Attempt $a, Attempt $b) => ($a->device?->number === null) <=> ($b->device?->number === null),
                fn (Attempt $a, Attempt $b) => ($a->device?->number ?? 0) <=> ($b->device?->number ?? 0),
            ])
            ->values()
            ->map(fn (Attempt $a) => $this->attemptRow($a))
            ->all();
    }

    /**
     * @return array<string, mixed>
     */
    private function attemptRow(Attempt $attempt): array
    {
        $online = (int) config('desktop.online_seconds', 60);
        $now = $attempt->paused_at ? Carbon::parse($attempt->paused_at) : now();

        $modules = $attempt->attempt_types
            ->filter(fn (AttemptType $t) => in_array($t->type?->name, MockBankService::MODULE_TYPES, true))
            ->sortBy(fn (AttemptType $t) => array_search($t->type?->name, MockBankService::MODULE_TYPES, true));

        $current = $attempt->finished_at === null
            ? $modules->filter(fn (AttemptType $t) => ! $t->is_submitted)->sortByDesc('started_at')->first()
            : null;

        $violations = $attempt->relationLoaded('violations') ? $attempt->violations : $attempt->violations()->latest('occurred_at')->get();

        return [
            'id' => $attempt->id,
            'name' => $attempt->mockStudent?->name ?? $attempt->name,
            'code' => $attempt->mockStudent?->code,
            'device' => $attempt->device?->name,
            'device_number' => $attempt->device?->number,
            'module' => $current?->type?->name,
            'modules_done' => $modules->filter(fn (AttemptType $t) => $t->is_submitted)->map(fn (AttemptType $t) => $t->type?->name)->values(),
            'time_left' => $current?->finished_at ? max(0, (int) $now->diffInSeconds(Carbon::parse($current->finished_at), false)) : null,
            'online' => $attempt->last_heartbeat_at !== null && $attempt->last_heartbeat_at->gt(now()->subSeconds($online)),
            'last_heartbeat_at' => $attempt->last_heartbeat_at?->toIso8601String(),
            'paused' => $attempt->paused_at !== null,
            'finished' => $attempt->finished_at !== null,
            'unlock_requested' => $attempt->unlock_requested_at !== null,
            'violations_count' => $violations->count(),
            'violation_counts' => $violations->countBy('type'),
            'violations' => $violations->take(50)->map(fn (AttemptViolation $v) => [
                'id' => $v->id,
                'type' => $v->type,
                'occurred_at' => $v->occurred_at?->toIso8601String(),
                'detail' => $v->detail,
            ])->values(),
        ];
    }
}
