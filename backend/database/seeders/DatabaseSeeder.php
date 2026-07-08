<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Check if admin user already exists
        if (!User::where('email', 'admin@findme.com')->exists()) {
            User::create([
                'name' => 'Admin FindMe',
                'email' => 'admin@findme.com',
                'nim' => '0000000000',
                'batch' => '2026',
                'phone_number' => '081234567890',
                'password' => \Illuminate\Support\Facades\Hash::make('adminpassword'),
                'is_admin' => true,
                'email_verified_at' => now(),
            ]);
        }

        if (!User::where('email', 'test@example.com')->exists()) {
            User::create([
                'name' => 'Test User',
                'email' => 'test@example.com',
                'nim' => '1234567890',
                'batch' => '2023',
                'phone_number' => '089876543210',
                'password' => \Illuminate\Support\Facades\Hash::make('password'),
                'is_admin' => false,
                'email_verified_at' => now(),
            ]);
        }
    }
}
