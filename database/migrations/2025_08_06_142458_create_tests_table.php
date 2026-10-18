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
        Schema::create('tests', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('folder_id');
            $table->foreign('folder_id')->on('folders')->references('id')
                ->onDelete('restrict')
                ->onUpdate('cascade');
            $table->string('name');
            $table->string('comment')->nullable();
            $table->string('audio_path')->nullable();
            $table->double('playtime_seconds')->nullable();
            $table->tinyInteger('active')->default(0);
            $table->tinyInteger('open')->default(0);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('tests');
    }
};
