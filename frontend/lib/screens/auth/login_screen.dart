import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/particle_background.dart';
import '../../utils/page_transitions.dart';
import '../../utils/wave_clipper.dart';
import '../home_screen.dart';
import 'register_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'otp_verification_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (res.containsKey('needs_verification') && res['needs_verification'] == true) {
          // Blocked due to unverified email, redirect to OTP Screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(res['message'] ?? 'Akun belum diverifikasi.'),
              backgroundColor: AppTheme.warning,
            ),
          );
          
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
          Navigator.pushAndRemoveUntil(
            context,
            FadeRoute(page: const HomeScreen()),
            (route) => false,
          );
        } else {
          setState(() {
            _errorMessage = res['message'] ?? 'Login gagal. Email atau password salah.';
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

  Future<void> _showIpConfigDialog() async {
    final ipController = TextEditingController();
    final prefs = await SharedPreferences.getInstance();
    
    // Set current host value to field
    ipController.text = ApiConfig.hostUrl
        .replaceAll('http://', '')
        .replaceAll('https://', '')
        .replaceAll(':8000', '')
        .replaceAll('/api', '');

    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
          title: Text('Pengaturan IP Server', style: AppTheme.heading3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Masukkan alamat IP lokal server Laravel Anda (tanpa http:// dan port 8000).',
                style: AppTheme.caption,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ipController,
                decoration: AppTheme.inputDecoration(
                  label: 'Host IP / Domain',
                ).copyWith(
                  hintText: '192.168.1.52',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final host = ipController.text.trim();
                if (host.isNotEmpty) {
                  final formattedHost = host.contains('://') ? host : 'http://$host:8000';
                  await prefs.setString('custom_host_url', formattedHost);
                  ApiConfig.setCustomIp(host);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('IP Server berhasil diubah ke: ${ApiConfig.hostUrl}'),
                        backgroundColor: AppTheme.success,
                      ),
                    );
                    Navigator.pop(context);
                  }
                }
              },
              style: AppTheme.primaryButton,
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final topHeight = screenSize.height * 0.35;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 48,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: 'Pengaturan IP',
            onPressed: _showIpConfigDialog,
          ),
        ],
      ),
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
                // Top Section (Dark Teal, fixed responsive height)
                SafeArea(
                  bottom: false,
                  child: Container(
                    height: topHeight > 220 ? topHeight : 220,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Selamat Datang Kembali!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Login untuk melanjutkan',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Logo icon
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 48,
                                color: Colors.white,
                              ),
                              Positioned(
                                top: 10,
                                child: Icon(
                                  Icons.favorite,
                                  color: AppTheme.primary,
                                  size: 16,
                                ),
                              ),
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

                          // Email Input
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: AppTheme.body,
                            decoration: AppTheme.inputDecoration(
                              label: 'Email',
                              prefixIcon: Icons.person_outline,
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Email wajib diisi';
                              if (!val.contains('@')) return 'Email tidak valid';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Password Input
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
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  FadeSlideRoute(page: const ForgotPasswordScreen()),
                                );
                              },
                              child: Text(
                                'Lupa password?',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.accent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Login Button
                          ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: AppTheme.primaryButton,
                            child: _isLoading
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Masuk'),
                          ),
                          const SizedBox(height: 32),

                          // Register Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Belum punya akun? ', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 13)),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(context, FadeSlideRoute(page: const RegisterScreen()));
                                },
                                child: Text(
                                  'Daftar sekarang',
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
