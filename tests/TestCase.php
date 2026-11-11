<?php

namespace Tests;

use App\Services\Desktop\ReleaseManifest;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        // Inertia pages render app.blade.php, which needs a Vite manifest; tests must not depend on a build.
        $this->withoutVite();

        // The real public/desktop/version.json (uploaded on release, not in git) must not leak into tests:
        // by default there is no release; tests opt in with useReleaseManifest().
        $this->app->instance(ReleaseManifest::class, new ReleaseManifest(sys_get_temp_dir().'/mynine-no-release-manifest.json'));
    }
}
