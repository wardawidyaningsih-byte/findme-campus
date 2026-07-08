import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  Future<void> _savePassword() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kata sandi berhasil diubah', style: GoogleFonts.plusJakartaSans()), backgroundColor: AppTheme.success),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('Ubah Password', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 18, color: AppTheme.textPrimary)),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_reset_rounded, size: 80, color: AppTheme.primary),
              const SizedBox(height: 24),
              Text(
                'Buat Kata Sandi Baru',
                textAlign: TextAlign.center,
                style: AppTheme.heading3,
              ),
              const SizedBox(height: 8),
              Text(
                'Pastikan kata sandi baru Anda panjang dan kuat untuk keamanan akun.',
                textAlign: TextAlign.center,
                style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 40),
              
              TextFormField(
                controller: _oldController,
                style: AppTheme.body,
                obscureText: _obscureOld,
                decoration: AppTheme.inputDecoration(
                  label: 'Kata Sandi Lama',
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureOld ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppTheme.textSecondary),
                    onPressed: () => setState(() => _obscureOld = !_obscureOld),
                  ),
                ),
                validator: (v) => v!.isEmpty ? 'Kata sandi lama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _newController,
                style: AppTheme.body,
                obscureText: _obscureNew,
                decoration: AppTheme.inputDecoration(
                  label: 'Kata Sandi Baru',
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppTheme.textSecondary),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (v) => v!.length < 6 ? 'Minimal 6 karakter' : null,
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _confirmController,
                style: AppTheme.body,
                obscureText: _obscureConfirm,
                decoration: AppTheme.inputDecoration(
                  label: 'Konfirmasi Kata Sandi',
                  prefixIcon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppTheme.textSecondary),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v != _newController.text) return 'Kata sandi tidak cocok';
                  return null;
                },
              ),
              const SizedBox(height: 40),
              
              ElevatedButton(
                onPressed: _isSaving ? null : _savePassword,
                style: AppTheme.primaryButton,
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Simpan Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
