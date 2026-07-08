<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\Item;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Auth;
use Illuminate\Validation\ValidationException;
use Illuminate\Support\Facades\Mail;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'nim' => 'required|string|max:50|unique:users',
            'batch' => 'required|string|max:10',
            'phone_number' => 'required|string|max:20',
            'password' => 'required|string|min:6',
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'nim' => $validated['nim'],
            'batch' => $validated['batch'],
            'phone_number' => $validated['phone_number'],
            'password' => Hash::make($validated['password']),
            'is_admin' => false,
            'email_verified_at' => now(), // Auto-verified
        ]);

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Registrasi berhasil.',
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => $user
        ], 201);
    }

    public function login(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|string|email',
            'password' => 'required|string',
        ]);

        $user = User::where('email', $validated['email'])->first();

        if (!$user || !Hash::check($validated['password'], $user->password)) {
            return response()->json([
                'message' => 'Email atau password salah'
            ], 401);
        }

        // Auto-verify if null (just in case)
        if (is_null($user->email_verified_at)) {
            $user->email_verified_at = now();
            $user->save();
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Login successful',
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => $user
        ]);
    }

    public function verifyOtp(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|string|email',
            'otp' => 'required|string|size:6',
            'type' => 'required|string|in:register',
        ]);

        $otp = \App\Models\Otp::where('email', $validated['email'])
            ->where('code', $validated['otp'])
            ->where('type', $validated['type'])
            ->where('expires_at', '>', now())
            ->first();

        if (!$otp) {
            return response()->json([
                'message' => 'Kode OTP tidak valid atau telah kedaluwarsa'
            ], 400);
        }

        $user = User::where('email', $validated['email'])->first();
        if (!$user) {
            return response()->json([
                'message' => 'User tidak ditemukan'
            ], 404);
        }

        if ($validated['type'] === 'register') {
            $user->email_verified_at = now();
            $user->save();
        }

        // Delete used OTP
        $otp->delete();

        // Issue token
        $token = $user->createToken('auth_token')->plainTextToken;

        return response()->json([
            'message' => 'Verifikasi berhasil',
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => $user
        ]);
    }

    public function forgotPassword(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|string|email',
        ]);

        $user = User::where('email', $validated['email'])->first();

        if (!$user) {
            return response()->json([
                'message' => 'Email tidak terdaftar di sistem kami'
            ], 404);
        }

        // Generate OTP code
        $otpCode = str_pad(random_int(100000, 999999), 6, '0', STR_PAD_LEFT);
        
        // Clear any old reset OTPs
        \App\Models\Otp::where('email', $user->email)->where('type', 'password_reset')->delete();

        \App\Models\Otp::create([
            'email' => $user->email,
            'code' => $otpCode,
            'type' => 'password_reset',
            'expires_at' => now()->addMinutes(15),
        ]);

        try {
            Mail::raw("Halo {$user->name},\n\nKode OTP untuk reset password akun Anda adalah: {$otpCode}\n\nKode ini berlaku selama 15 menit. Jika Anda tidak merasa meminta reset password, abaikan email ini.", function ($message) use ($user) {
                $message->to($user->email)
                    ->subject('Reset Password Akun FindMe Kampus');
            });
        } catch (\Exception $e) {
            \Illuminate\Support\Facades\Log::error("Failed sending forgot password email: " . $e->getMessage());
        }

        return response()->json([
            'message' => 'Kode OTP reset password telah dikirim ke email Anda.'
        ]);
    }

    public function resetPassword(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|string|email',
            'otp' => 'required|string|size:6',
            'password' => 'required|string|min:6',
        ]);

        $otp = \App\Models\Otp::where('email', $validated['email'])
            ->where('code', $validated['otp'])
            ->where('type', 'password_reset')
            ->where('expires_at', '>', now())
            ->first();

        if (!$otp) {
            return response()->json([
                'message' => 'Kode OTP tidak valid atau telah kedaluwarsa'
            ], 400);
        }

        $user = User::where('email', $validated['email'])->first();
        if (!$user) {
            return response()->json([
                'message' => 'User tidak ditemukan'
            ], 404);
        }

        // Reset password
        $user->password = Hash::make($validated['password']);
        $user->save();

        // Delete used OTP
        $otp->delete();

        return response()->json([
            'message' => 'Password Anda telah berhasil direset. Silakan login kembali.'
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logged out successfully'
        ]);
    }

    public function profile(Request $request)
    {
        $user = $request->user();
        
        $totalReports = Item::where('user_id', $user->id)->count();
        $lostReports = Item::where('user_id', $user->id)->where('type', 'lost')->count();
        $foundReports = Item::where('user_id', $user->id)->where('type', 'found')->count();
        $returnedReports = Item::where('user_id', $user->id)->where('status', 'returned')->count();

        return response()->json([
            'user' => $user,
            'stats' => [
                'total_reports' => $totalReports,
                'lost_reports' => $lostReports,
                'found_reports' => $foundReports,
                'returned_reports' => $returnedReports,
            ]
        ]);
    }

    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users,email,' . $user->id,
            'nim' => 'required|string|max:50|unique:users,nim,' . $user->id,
            'phone_number' => 'required|string|max:20',
            'image' => 'nullable|image|max:2048', // Max 2MB image
        ]);

        $user->name = $validated['name'];
        $user->email = $validated['email'];
        $user->nim = $validated['nim'];
        $user->phone_number = $validated['phone_number'];

        if ($request->hasFile('image')) {
            // Delete old profile image if exists
            if ($user->image_path) {
                \Illuminate\Support\Facades\Storage::disk('public')->delete($user->image_path);
            }
            // Store new image
            $path = $request->file('image')->store('profile', 'public');
            $user->image_path = $path;
        }

        $user->save();

        return response()->json([
            'message' => 'Profil berhasil diperbarui.',
            'user' => $user
        ]);
    }
}
