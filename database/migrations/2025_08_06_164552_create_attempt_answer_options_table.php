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
        Schema::create('attempt_answer_options', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('attempt_answer_id');
            $table->foreign('attempt_answer_id')->on('attempt_answers')->references('id')
                ->onDelete('restrict')
                ->onUpdate('cascade');
            $table->unsignedBigInteger('option_id');
            $table->foreign('option_id')->on('options')->references('id')
                ->onDelete('restrict')
                ->onUpdate('cascade');
            $table->tinyInteger('is_correct')->default(0);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('attempt_answer_options');
    }
};
