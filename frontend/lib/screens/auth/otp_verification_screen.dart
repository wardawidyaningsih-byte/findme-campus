import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/particle_background.dart';
import '../../utils/wave_clipper.dart';
import '../../utils/page_transitions.dart';
import '../home_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String type; // 'register' or 'password_reset'

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.type,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.verifyOtp(
        email: widget.email,
        otp: _otpController.text.trim(),
        type: widget.type,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (res.containsKey('access_token')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verifikasi berhasil! Selamat datang.'),
              backgroundColor: AppTheme.success,
            ),
          );
          
          Navigator.pushAndRemoveUntil(
            context,
            FadeRoute(page: const HomeScreen()),
            (route) => false,
          );
        } else {
          setState(() {
            _errorMessage = res['message'] ?? 'Verifikasi gagal. Silakan periksa kode Anda.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Terjadi kesalahan jaringan. Coba lagi.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final topHeight = screenSize.height * 0.35;

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
                    height: topHeight > 220 ? topHeight : 220,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Verifikasi Akun',
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
                            'Masukkan 6 digit kode OTP yang dikirimkan ke email Anda:\n${widget.email}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.mark_email_unread_outlined,
                            size: 40,
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
                    padding: const EdgeInsets.fromLTRB(28, 56, 28, 60),
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
                            const SizedBox(height: 24),
                          ],

                          // OTP Input Field
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 6,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 8,
                              color: AppTheme.textPrimary,
                            ),
                            decoration: AppTheme.inputDecoration(
                              label: 'Kode OTP',
                            ).copyWith(
                              counterText: '',
                              hintText: '000000',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                color: AppTheme.textSecondary.withValues(alpha: 0.5),
                                letterSpacing: 8,
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Kode OTP wajib diisi';
                              if (val.length != 6) return 'Kode OTP harus 6 digit';
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          // Verify Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _verify,
                            style: AppTheme.primaryButton,
                            child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Verifikasi'),
                          ),
                          const SizedBox(height: 24),

                          // Return to Login Link
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
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
