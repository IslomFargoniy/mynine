<?php

namespace Database\Seeders;

use App\Models\CenterSetting;
use App\Models\User\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $users = [
            [
                'name' => 'Admin',
                'email' => 'admin@gmail.com',
                'phone' => '998901234567',
                'password' => Hash::make('123456'), // Always hash passwords
            ],
        ];

        foreach ($users as $user) {
            $new_user = User::updateOrCreate(
                ['email' => $user['email']], // unique condition
                $user
            );

            // Development: the seeded admin is the platform owner and the Admin of the Mynine center.
            $new_user->assignRole(['Admin', 'SuperAdmin']);
            CenterSetting::firstOrCreate(
                ['owner_id' => $new_user->id],
                ['name' => 'Mynine', 'code' => CenterSetting::MYNINE_CODE, 'status' => CenterSetting::STATUS_ACTIVE],
            );
        }
    }
}
