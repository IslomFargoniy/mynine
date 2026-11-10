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
        //
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

        Gate::define('manage-desktop-settings', fn (User $user) => $user->hasRole('Admin'));
    }

    /**
     * Desktop API limits are keyed by device token: all exam PCs share the center's public IP.
     */
    private function configureDesktopRateLimits(): void
    {
        $deviceKey = fn (Request $request) => hash('sha256', (string) ($request->header('X-Device-Token') ?: $request->ip()));

        RateLimiter::for('desktop', fn (Request $request) => Limit::perMinute(300)->by('desktop:'.$deviceKey($request)));

        RateLimiter::for('desktop-public', fn (Request $request) => Limit::perMinute(300)->by('desktop-public:'.$request->ip()));

        RateLimiter::for('desktop-register', fn (Request $request) => Limit::perMinute(30)->by('desktop-register:'.$request->ip()));

        RateLimiter::for('desktop-login', fn (Request $request) => [
            Limit::perMinute(10)->by('desktop-login:'.$deviceKey($request)),
            Limit::perMinute(60)->by('desktop-login-ip:'.$request->ip()),
        ]);

        RateLimiter::for('desktop-unlock', fn (Request $request) => Limit::perMinute(5)->by('desktop-unlock:'.$deviceKey($request)));
    }
}
