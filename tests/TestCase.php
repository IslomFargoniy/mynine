<?php

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        // Inertia pages render app.blade.php, which needs a Vite manifest; tests must not depend on a build.
        $this->withoutVite();
    }
}
