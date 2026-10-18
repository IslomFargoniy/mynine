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
    }
}
