<?php

namespace App\Http\Controllers;

use App\Models\Attempt;
use App\Models\Mock;
use App\Models\User\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Inertia\Inertia;

class HomeController extends Controller
{
    public function index(Request $request)
    {
        // Reception works from the reception desk; it has no dashboard.
        if ($request->user()?->hasRole('Reception') && ! $request->user()->hasRole('Admin')) {
            return redirect()->route('reception.index');
        }

        $user = User::query()
            ->with([
                'last_attempt.attempt_types',
                'attempts' => function ($query) {
                    // Filters to last 30 days finished attempts for the chart.
                    // NOTE: 'attempts.attempt_types.type' is intentionally merged
                    // here to avoid a conflict that would bypass this constraint.
                    $query->whereNotNull('finished_at')
                        ->where('finished_at', '>=', now()->subDays(30))
                        ->with(['attempt_types.type'])
                        ->orderBy('finished_at', 'asc');
                },
            ])
            ->withCount([
                'attempts as attempts_count_this_month' => function ($query) {
                    $query->whereNotNull('finished_at')
                        ->whereYear('finished_at', now()->year)
                        ->whereMonth('finished_at', now()->month);
                },
                'attempts as total_attempts_count' => function ($query) {
                    $query->whereNotNull('finished_at');
                },
            ])
            ->find(Auth::id());

        // Get recent 5 attempts
        $recent_attempts = Attempt::with(['test', 'attempt_types'])
            ->where('user_id', Auth::id())
            ->whereNotNull('finished_at')
            ->orderBy('finished_at', 'desc')
            ->limit(5)
            ->get();

        $isAdmin = Auth::user()->hasRole('Admin');

        $daily_users = collect();
        $daily_attempts = collect();
        $hourly_attempts = collect();
        $today_hourly_attempts = collect();
        $weekly_attempts = collect();

        if ($isAdmin) {
            $startDate = now()->subDays(30)->toDateString();
            $daily_users = User::query()
                ->selectRaw('DATE(created_at) as day_date, count(*) as items_count')
                ->whereDate('created_at', '>=', $startDate)
                ->groupBy('day_date')
                ->havingRaw('count(*) > 0')
                ->orderBy('day_date', 'asc')
                ->get();

            // NOTE: DB::table() is used intentionally here instead of Attempt::query()
            // to bypass the Attempt model's $with (attempt_types, test, user, mock)
            // which can interfere with COUNT(*) aggregations and return inflated numbers.
            $daily_attempts = DB::table('attempts')
                ->selectRaw('DATE(finished_at) as day_date, count(*) as items_count, count(distinct user_id) as unique_users_count')
                ->whereNotNull('finished_at')
                ->whereDate('finished_at', '>=', $startDate)
                ->groupByRaw('DATE(finished_at)')
                ->havingRaw('count(*) > 0')
                ->orderBy('day_date', 'asc')
                ->get();

            $hourly_attempts = DB::table('attempts')
                ->selectRaw('HOUR(finished_at) as hour, count(*) as items_count')
                ->whereNotNull('finished_at')
                ->groupByRaw('HOUR(finished_at)')
                ->havingRaw('count(*) > 0')
                ->orderByRaw('HOUR(finished_at) asc')
                ->get();

            $today_hourly_attempts = DB::table('attempts')
                ->selectRaw('HOUR(finished_at) as hour, count(*) as items_count')
                ->whereNotNull('finished_at')
                ->whereDate('finished_at', now()->toDateString())
                ->groupByRaw('HOUR(finished_at)')
                ->havingRaw('count(*) > 0')
                ->orderByRaw('HOUR(finished_at) asc')
                ->get();

            $weekly_attempts = DB::table('attempts')
                ->selectRaw('(WEEKDAY(finished_at) + 1) as weekday, count(*) as items_count')
                ->whereNotNull('finished_at')
                ->groupByRaw('WEEKDAY(finished_at)')
                ->havingRaw('count(*) > 0')
                ->orderByRaw('WEEKDAY(finished_at) asc')
                ->get();
        }

        return Inertia::render('dashboard', [
            'user' => $user,
            'recent_attempts' => $recent_attempts,
            'daily_users' => $daily_users,
            'daily_attempts' => $daily_attempts,
            'hourly_attempts' => $hourly_attempts,
            'today_hourly_attempts' => $today_hourly_attempts,
            'weekly_attempts' => $weekly_attempts,
            'isAdmin' => $isAdmin,
        ]);

    }

    public function home(Request $request)
    {
        return Inertia::render('welcome');
    }
}
