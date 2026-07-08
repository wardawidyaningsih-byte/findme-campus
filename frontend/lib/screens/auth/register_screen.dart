import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/particle_background.dart';
import '../../utils/wave_clipper.dart';
import '../../utils/page_transitions.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _nimController = TextEditingController();
  final _batchController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _nimController.dispose();
    _batchController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      setState(() => _errorMessage = 'Anda harus menyetujui syarat & ketentuan');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        nim: _nimController.text.trim(),
        batch: _batchController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (res.containsKey('needs_verification') && res['needs_verification'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Verifikasi OTP dikirim ke email Anda.'),
              backgroundColor: AppTheme.primary,
            ),
          );
          
          // Open OTP verification page
          Navigator.push(
            context,
            FadeSlideRoute(
              page: OtpVerificationScreen(
                email: _emailController.text.trim(),
                type: 'register',
              ),
            ),
          );
        } else if (res.containsKey('access_token')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registrasi berhasil!'),
              backgroundColor: AppTheme.primary,
            ),
          );
          Navigator.pop(context); // Go back to login
        } else {
          setState(() {
            _errorMessage = res['message'] ?? 'Registrasi gagal. Coba email lain.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Terjadi kesalahan jaringan atau server. Silakan coba lagi.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final topHeight = screenSize.height * 0.32;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: ParticleBackground(
        particleCount: 50,
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
                          'Buat Akun Baru',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Daftar untuk mulai melapor',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              const Icon(Icons.location_on, size: 48, color: Colors.white),
                              Positioned(top: 10, child: Icon(Icons.favorite, color: AppTheme.primary, size: 16)),
                            ],
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
                    padding: const EdgeInsets.fromLTRB(28, 56, 28, 40),
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
                            const SizedBox(height: 16),
                          ],

                          // Name
                          TextFormField(
                            controller: _nameController,
                            style: AppTheme.body,
                            decoration: AppTheme.inputDecoration(
                              label: 'Nama Lengkap',
                              prefixIcon: Icons.person_outline,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'Nama wajib diisi';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: AppTheme.body,
                            decoration: AppTheme.inputDecoration(
                              label: 'Email',
                              prefixIcon: Icons.mail_outline,
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Email wajib diisi';
                              if (!val.contains('@')) return 'Email tidak valid';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // NIM
                          TextFormField(
                            controller: _nimController,
                            keyboardType: TextInputType.number,
                            style: AppTheme.body,
                            decoration: AppTheme.inputDecoration(
                              label: 'NIM',
                              prefixIcon: Icons.badge_outlined,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) return 'NIM wajib diisi';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Batch & Phone in a row
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: _batchController,
                                  keyboardType: TextInputType.number,
                                  style: AppTheme.body,
                                  decoration: AppTheme.inputDecoration(
                                    label: 'Angkatan',
                                    prefixIcon: Icons.calendar_today_outlined,
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'Wajib';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: AppTheme.body,
                                  decoration: AppTheme.inputDecoration(
                                    label: 'No WhatsApp',
                                    prefixIcon: Icons.phone_outlined,
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) return 'No WA wajib diisi';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: AppTheme.body,
                            decoration: AppTheme.inputDecoration(
                              label: 'Password',
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
                              if (val == null || val.isEmpty) return 'Password wajib diisi';
                              if (val.length < 6) return 'Password minimal 6 karakter';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            style: AppTheme.body,
                            decoration: AppTheme.inputDecoration(
                              label: 'Konfirmasi Password',
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
                          const SizedBox(height: 20),

                          // Terms
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _agreeToTerms,
                                  onChanged: (val) {
                                    setState(() => _agreeToTerms = val ?? false);
                                  },
                                  activeColor: AppTheme.accent,
                                  side: const BorderSide(color: AppTheme.textSecondary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Wrap(
                                  children: [
                                    Text('Saya setuju dengan ', style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13)),
                                    Text(
                                      'syarat & ketentuan',
                                      style: GoogleFonts.plusJakartaSans(color: AppTheme.accent, fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Register Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: AppTheme.primaryButton,
                            child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Daftar'),
                          ),
                          const SizedBox(height: 24),

                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Sudah punya akun? ', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 13)),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Text(
                                  'Masuk sekarang',
                                  style: GoogleFonts.plusJakartaSans(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13),
                                ),
                              ),
                            ],
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
