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
        Schema::create('options', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('question_id')->nullable();
            $table->foreign('question_id')->on('questions')->references('id')
                ->onDelete('restrict')
                ->onUpdate('cascade');
            $table->unsignedBigInteger('section_id')->nullable();
            $table->foreign('section_id')->on('sections')->references('id')
                ->onDelete('restrict')
                ->onUpdate('cascade');
            $table->mediumText('textarea');
            $table->tinyInteger('is_correct')->default(0);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('options');
    }
};
