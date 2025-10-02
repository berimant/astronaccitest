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
    Schema::table('users', function (Blueprint $table) {
        // Tambahkan kolom baru
        $table->string('avatar_path')->nullable()->after('password'); 
    });
}

public function down(): void
{
    Schema::table('users', function (Blueprint $table) {
        // Rollback: hapus kolom jika migration di-rollback
        $table->dropColumn('avatar_path');
    });
}
};
