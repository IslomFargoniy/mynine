<?php

namespace Database\Factories;

use App\Models\AppRelease;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<AppRelease>
 */
class AppReleaseFactory extends Factory
{
    protected $model = AppRelease::class;

    public function definition(): array
    {
        $version = fake()->unique()->numerify('1.#.#');

        return [
            'version' => $version,
            'notes' => 'Release '.$version,
            'mandatory' => false,
            'file_path' => AppRelease::DIRECTORY.'/mynine-setup-'.$version.'.exe',
            'file_size' => 1024,
            'sha256' => hash('sha256', $version),
            'is_active' => true,
        ];
    }
}
