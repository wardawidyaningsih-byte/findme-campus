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
        Schema::create('items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->enum('type', ['lost', 'found']);
            $table->string('image_path')->nullable();
            $table->string('name');
            $table->string('category');
            $table->string('location');
            $table->date('date');
            $table->text('description');
            $table->enum('status', ['lost', 'found', 'security', 'lab_assistant', 'returned'])->default('lost');
            $table->text('verification_question')->nullable();
            $table->enum('custodian_type', ['security', 'lab_assistant'])->nullable();
            $table->string('custodian_name')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('items');
    }
};
