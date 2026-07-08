import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nimController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _currentImagePath;
  String? _pickedImagePath;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final data = await ApiService.getProfile();
      if (data != null && mounted) {
        final user = UserModel.fromJson(data['user']);
        _nameController.text = user.name;
        _nimController.text = user.nim;
        _emailController.text = user.email;
        _phoneController.text = user.phoneNumber ?? '';
        _currentImagePath = user.imagePath;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image != null) {
        setState(() {
          _pickedImagePath = image.path;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Image picking error: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      final res = await ApiService.updateProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        nim: _nimController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        imagePath: _pickedImagePath,
      );
      
      if (res != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              res['message'] ?? 'Profil berhasil diperbarui',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: AppTheme.success,
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Terjadi kesalahan saat memperbarui profil',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) print('Profile save exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal terhubung ke server',
              style: GoogleFonts.plusJakartaSans(),
            ),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
    
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? avatarImage;
    if (_pickedImagePath != null) {
      avatarImage = FileImage(File(_pickedImagePath!));
    } else if (_currentImagePath != null && _currentImagePath!.isNotEmpty) {
      avatarImage = NetworkImage('${ApiConfig.hostUrl}/storage/$_currentImagePath');
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          'Edit Profil',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.primary, width: 2),
                                image: avatarImage != null
                                    ? DecorationImage(
                                        image: avatarImage,
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: avatarImage == null
                                  ? const Icon(
                                      Icons.person_rounded,
                                      size: 50,
                                      color: AppTheme.primary,
                                    )
                                  : null,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      style: AppTheme.body,
                      decoration: AppTheme.inputDecoration(
                        label: 'Nama Lengkap',
                        prefixIcon: Icons.person_outline_rounded,
                      ),
                      validator: (v) => v!.isEmpty ? 'Nama tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nimController,
                      style: AppTheme.body,
                      decoration: AppTheme.inputDecoration(
                        label: 'NIM',
                        prefixIcon: Icons.badge_outlined,
                      ),
                      validator: (v) => v!.isEmpty ? 'NIM tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      style: AppTheme.body,
                      decoration: AppTheme.inputDecoration(
                        label: 'Email',
                        prefixIcon: Icons.email_outlined,
                      ),
                      validator: (v) => v!.isEmpty ? 'Email tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _phoneController,
                      style: AppTheme.body,
                      keyboardType: TextInputType.phone,
                      decoration: AppTheme.inputDecoration(
                        label: 'Nomor WhatsApp',
                        prefixIcon: Icons.phone_outlined,
                      ),
                      validator: (v) => v!.isEmpty ? 'Nomor telepon tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: AppTheme.primaryButton,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Simpan Perubahan'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
