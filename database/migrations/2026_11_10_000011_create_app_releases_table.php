<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('app_releases', function (Blueprint $table) {
            $table->id();
            $table->string('version', 40)->unique();
            $table->text('notes')->nullable();
            $table->boolean('mandatory')->default(false);
            $table->string('file_path');
            $table->unsignedBigInteger('file_size');
            $table->char('sha256', 64);
            $table->boolean('is_active')->default(true);
            $table->foreignId('published_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('app_releases');
    }
};
