<?php

namespace App\Http\Controllers\Center;

use App\Http\Controllers\Controller;
use App\Models\CenterSetting;
use App\Services\CenterReportService;
use App\Support\CurrentCenter;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Inertia\Inertia;
use Inertia\Response;

/**
 * Reports (SuperAdmin): per center and month, the candidates who sat the exam (billing), the mocks held and
 * the AI usage / estimated cost. Usage (center Admin): the same numbers for their own center only.
 */
class ReportController extends Controller
{
    public function __construct(private readonly CenterReportService $reports) {}

    public function index(Request $request): Response
    {
        Gate::authorize('manage-centers');
        $month = $this->month($request);

        return Inertia::render('reports/index', [
            'month' => $month,
            ...$this->reports->summary($month),
        ]);
    }

    public function usage(Request $request): Response
    {
        $centerId = $this->ownCenter($request);
        $month = $this->month($request);
        $summary = $this->reports->summary($month, $centerId);

        return Inertia::render('reports/usage', [
            'month' => $month,
            'row' => $summary['rows'][0] ?? null,
            'candidates' => $this->reports->candidates($centerId, $month),
        ]);
    }

    /**
     * Billed candidates of one center (drill-down): any center for the SuperAdmin, otherwise only the Admin's own.
     */
    public function candidates(Request $request): JsonResponse
    {
        $centerId = (int) $request->query('center', 0);

        if (! $request->user()->isSuperAdmin()) {
            abort_unless($centerId === $this->ownCenter($request), 403);
        }
        abort_unless(CenterSetting::query()->where('owner_id', $centerId)->exists(), 404);

        $month = $this->month($request);

        return response()->json(['month' => $month, 'center' => $centerId, 'data' => $this->reports->candidates($centerId, $month)]);
    }

    private function month(Request $request): string
    {
        $request->validate(['month' => ['nullable', 'date_format:Y-m']]);

        return (string) ($request->query('month') ?: CenterReportService::currentMonth());
    }

    /**
     * The Admin's own center (for the SuperAdmin: the center chosen on the Centers page).
     */
    private function ownCenter(Request $request): int
    {
        $user = $request->user();
        abort_unless($user->isCenterAdmin(), 403);

        $centerId = $user->isSuperAdmin() ? app(CurrentCenter::class)->forUser($user) : $user->homeCenterId();
        abort_unless($centerId && $centerId !== CurrentCenter::NONE, 403);

        return (int) $centerId;
    }
}
