<?php

namespace Database\Factories;

use App\Models\Device;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<Device>
 */
class DeviceFactory extends Factory
{
    protected $model = Device::class;

    public function definition(): array
    {
        return [
            'machine_id' => (string) Str::uuid(),
            'name' => 'PC-'.str_pad((string) fake()->numberBetween(1, 99), 2, '0', STR_PAD_LEFT),
            'token_hash' => Device::hashToken(Str::random(64)),
            'app_version' => '1.0.0',
            'os_version' => 'Windows 11 23H2',
            'is_blocked' => false,
            'number' => null,
        ];
    }

    /**
     * An approved PC with its exam-room number.
     */
    public function approved(int $number): static
    {
        return $this->state(fn () => ['is_approved' => true, 'approved_at' => now(), 'number' => $number]);
    }
}
