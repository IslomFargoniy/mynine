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
        Schema::create('attempt_answers', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('attempt_part_id');
            $table->foreign('attempt_part_id')->on('attempt_parts')->references('id')
                ->onDelete('restrict')
                ->onUpdate('cascade');
            $table->unsignedBigInteger('question_id');
            $table->foreign('question_id')->on('questions')->references('id')
                ->onDelete('restrict')
                ->onUpdate('cascade');
            $table->mediumText('answer_text')->nullable();
            $table->string('audio_path')->nullable();
            $table->string('transcript')->nullable();
            $table->mediumText('review_note')->nullable();
            $table->mediumText('review_note_ai')->nullable();
            $table->tinyInteger('is_correct')->nullable();
            $table->integer('score')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('attempt_answers');
    }
};
