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
        Schema::create('parts', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->unsignedBigInteger('test_type_id');
            $table->foreign('test_type_id')->on('test_types')->references('id')
                ->onDelete('restrict')
                ->onUpdate('cascade');
            $table->mediumText('textarea')->nullable();
            $table->string('audio_path')->nullable();
            $table->integer('minute')->nullable()->default(0);
            $table->string('comment')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('parts');
    }
};
