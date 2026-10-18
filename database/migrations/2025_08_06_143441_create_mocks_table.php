<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('mocks', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('comment')->nullable();
            $table->datetime('started_at');
            $table->datetime('finished_at');
            $table->unsignedBigInteger('test_id');
            $table->foreign('test_id')->on('tests')->references('id')
                ->onDelete('restrict')
                ->onUpdate('cascade');
            $table->unsignedBigInteger('user_id');
            $table->foreign('user_id')->on('users')->references('id')
                ->onDelete('restrict')
                ->onUpdate('cascade');
            $table->string('slug')->unique();
            $table->tinyInteger('active')->default(0);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('mocks');
    }
};
