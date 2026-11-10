<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;

class RoleSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $roles = ['Admin', 'Reception', 'Student'];

        foreach ($roles as $roleName) {
            Role::findOrCreate($roleName);
        }
    }
}
