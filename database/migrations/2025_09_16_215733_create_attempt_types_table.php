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
        Schema::create('attempt_types', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('attempt_id');
            $table->foreign('attempt_id')->on('attempts')->references('id')
                ->onDelete('restrict')
                ->onUpdate('cascade');
            $table->unsignedBigInteger('type_id');
            $table->foreign('type_id')->on('types')->references('id')
                ->onDelete('restrict')
                ->onUpdate('cascade');
            $table->double('score')->default(0);
            $table->mediumText('comment')->nullable();
            $table->datetime('started_at');
            $table->datetime('finished_at')->nullable();
            $table->timestamps();

            $table->unique(['attempt_id', 'type_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('attempt_types');
    }
};
