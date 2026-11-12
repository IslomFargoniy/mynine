<?php

namespace App\Providers;

use App\Models\Attempt;
use App\Models\Folder;
use App\Models\Mock;
use App\Models\Section;
use App\Models\Test;
use App\Models\User\User;
use App\Observers\AttemptObserver;
use App\Observers\FolderObserver;
use App\Observers\MockObserver;
use App\Observers\SectionObserver;
use App\Observers\TestObserver;
use App\Observers\UserObserver;
use App\Support\AiUsage;
use App\Support\CurrentCenter;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->singleton(CurrentCenter::class);
        $this->app->singleton(AiUsage::class);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {

        User::observe(UserObserver::class);
        Section::observe(SectionObserver::class);
        Attempt::observe(AttemptObserver::class);
        Mock::observe(MockObserver::class);
        Folder::observe(FolderObserver::class);
        Test::observe(TestObserver::class);

        $this->configureDesktopRateLimits();

        // The SuperAdmin passes every check (any center's records), except taking part in someone's exam.
        Gate::before(function ($user, string $ability) {
            if ($user instanceof User && $user->isSuperAdmin() && $ability !== 'participate') {
                return true;
            }

            return null;
        });

        // Settings of the current center (center password, background, name, logo): its Admin.
        Gate::define('manage-desktop-settings', fn (User $user) => $user->isCenterAdmin() && $user->centerId() === $user->homeCenterId());
        Gate::define('manage-center-settings', fn (User $user) => $user->isCenterAdmin() && $user->centerId() === $user->homeCenterId());
        // Practice tests, folders and the website's users: the platform owner (SuperAdmin) only.
        Gate::define('manage-content', fn (User $user) => false);
        // Centers page (create, suspend, replace admin, switch): SuperAdmin only.
        Gate::define('manage-centers', fn (User $user) => false);
    }

    /**
     * Desktop API limits are keyed by device token: all exam PCs share the center's public IP.
     */
    private function configureDesktopRateLimits(): void
    {
        $deviceKey = fn (Request $request) => hash('sha256', (string) ($request->header('X-Device-Token') ?: $request->ip()));

        RateLimiter::for('desktop', fn (Request $request) => Limit::perMinute(300)->by('desktop:'.$deviceKey($request)));

        RateLimiter::for('desktop-register', fn (Request $request) => Limit::perMinute(30)->by('desktop-register:'.$request->ip()));

        RateLimiter::for('desktop-login', fn (Request $request) => [
            Limit::perMinute(10)->by('desktop-login:'.$deviceKey($request)),
            Limit::perMinute(60)->by('desktop-login-ip:'.$request->ip()),
        ]);

        RateLimiter::for('desktop-unlock', fn (Request $request) => Limit::perMinute(5)->by('desktop-unlock:'.$deviceKey($request)));

        // Web exam audio: per listener (user, candidate session), not per IP — a whole exam hall can share one IP.
        // Players send a few Range requests per file; enumeration of guessed file names is what this limits.
        RateLimiter::for('media-audio', function (Request $request) {
            $session = $request->hasSession() ? $request->session() : null;
            $key = $request->user()?->getAuthIdentifier()
                ? 'u'.$request->user()->getAuthIdentifier()
                : ($session?->get('mock_student_id') ? 'c'.$session->get('mock_student_id') : 's'.($session?->getId() ?? $request->ip()));

            return [
                Limit::perMinute(120)->by('media-audio:'.$key),
                Limit::perMinute(1200)->by('media-audio-ip:'.$request->ip()),
            ];
        });
    }
}
