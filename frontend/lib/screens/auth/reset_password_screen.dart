import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/particle_background.dart';
import '../../utils/wave_clipper.dart';
import '../../utils/page_transitions.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({
    super.key,
    required this.email,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.resetPassword(
        email: widget.email,
        otp: _otpController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (res.containsKey('message')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Password berhasil diubah. Silakan login kembali.'),
              backgroundColor: AppTheme.success,
            ),
          );

          // Clear stack and return to Login Screen
          Navigator.pushAndRemoveUntil(
            context,
            FadeRoute(page: const LoginScreen()),
            (route) => false,
          );
        } else {
          setState(() {
            _errorMessage = res['message'] ?? 'Gagal mereset password. Pastikan kode OTP benar.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Terjadi kesalahan jaringan atau kode OTP salah.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final topHeight = screenSize.height * 0.3;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: ParticleBackground(
        particleCount: 40,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                // Top Section (fixed responsive height)
                SafeArea(
                  bottom: false,
                  child: Container(
                    height: topHeight > 200 ? topHeight : 200,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Reset Password',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Masukkan OTP dan buat password baru Anda.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.vpn_key_outlined,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Section (White Card with custom Wave shape)
                ClipPath(
                  clipper: WaveClipper(),
                  child: Container(
                    width: double.infinity,
                    color: AppTheme.surface,
                    padding: const EdgeInsets.fromLTRB(28, 56, 28, 50),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.danger.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                border: Border.all(
                                  color: AppTheme.danger.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppTheme.danger,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // OTP Code
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 6,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 4,
                              color: AppTheme.textPrimary,
                            ),
                            decoration: AppTheme.inputDecoration(
                              label: 'Kode OTP 6-Digit',
                            ).copyWith(
                              counterText: '',
                              hintText: '000000',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                color: AppTheme.textSecondary.withValues(alpha: 0.5),
                                letterSpacing: 4,
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Kode OTP wajib diisi';
                              if (val.length != 6) return 'Kode OTP harus 6 digit';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // New Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: AppTheme.body,
                            decoration: AppTheme.inputDecoration(
                              label: 'Password Baru',
                              prefixIcon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: AppTheme.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Password baru wajib diisi';
                              if (val.length < 6) return 'Password minimal 6 karakter';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Confirm New Password
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            style: AppTheme.body,
                            decoration: AppTheme.inputDecoration(
                              label: 'Konfirmasi Password Baru',
                              prefixIcon: Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: AppTheme.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                                },
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Konfirmasi password wajib diisi';
                              if (val != _passwordController.text) return 'Password tidak cocok';
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),

                          // Reset Password Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _reset,
                            style: AppTheme.primaryButton,
                            child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Ubah Password'),
                          ),
                          const SizedBox(height: 24),

                          // Back to Login Link
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  FadeRoute(page: const LoginScreen()),
                                  (route) => false,
                                );
                              },
                              child: Text(
                                'Kembali ke Login',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
