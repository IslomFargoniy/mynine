<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * When the person chose their own password. Null: they have none they know (Google / Telegram / GitHub sign-up,
     * or a center account handed over by "Replace admin"), so Settings → Password sets one without the current one.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->timestamp('password_set_at')->nullable()->after('password');
        });

        // Existing accounts: a password and no social sign-in → they know it (registered with it, or were given it).
        DB::table('users')
            ->whereNotNull('password')
            ->whereNull('google_id')->whereNull('telegram_id')->whereNull('github_id')
            ->update(['password_set_at' => DB::raw('COALESCE(updated_at, created_at)')]);
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('password_set_at');
        });
    }
};
