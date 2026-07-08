import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/particle_background.dart';
import '../../utils/wave_clipper.dart';

import '../../utils/page_transitions.dart';
import '../auth/login_screen.dart';
import 'my_activity_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'help_center_screen.dart';
import 'terms_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool embedded;
  const ProfileScreen({super.key, this.embedded = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getProfile();
      if (data != null && mounted) {
        setState(() {
          _user = UserModel.fromJson(data['user']);
        });
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        title: Text('Keluar', style: AppTheme.heading3),
        content: Text('Apakah Anda yakin ingin keluar dari aplikasi?', style: AppTheme.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: Text('Keluar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      await ApiService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          FadeRoute(page: const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _user == null) {
      return Scaffold(
        backgroundColor: AppTheme.surface,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    final content = SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        children: [
          // Header with Wave and Particle
          ClipPath(
            clipper: WaveClipper(),
            child: Container(
              height: 280,
              width: double.infinity,
              color: AppTheme.primary,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: ParticleBackground(
                      particleCount: 20,
                      child: SizedBox.expand(),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Profil Saya',
                                style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              // Optional Edit Icon at top right if needed, but image doesn't show one
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  image: _user?.imagePath != null && _user!.imagePath!.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage('${ApiConfig.hostUrl}/storage/${_user!.imagePath}'),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: _user?.imagePath == null || _user!.imagePath!.isEmpty
                                    ? const Icon(Icons.person_rounded, size: 40, color: Colors.white)
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _user?.name ?? 'Anonim',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _user?.nim ?? '-',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                                      ),
                                      child: Text(
                                        _user?.email ?? '-',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Body Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                
                Text('Aktivitas', style: AppTheme.heading3),
                const SizedBox(height: 12),
                _buildMenuCard(
                  items: [
                    _MenuData(
                      icon: Icons.assignment_outlined,
                      title: 'Laporan & Klaim Saya',
                      onTap: () {
                        Navigator.push(context, FadeSlideRoute(page: const MyActivityScreen()));
                      },
                    ),
                    if (_user?.isAdmin == true)
                      _MenuData(
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'Dashboard Admin',
                        onTap: () {
                          Navigator.push(context, FadeSlideRoute(page: const AdminDashboardScreen()));
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                Text('Pengaturan Akun', style: AppTheme.heading3),
                const SizedBox(height: 12),
                _buildMenuCard(
                  items: [
                    _MenuData(
                      icon: Icons.edit_outlined,
                      title: 'Edit Profil',
                      onTap: () async {
                        final updated = await Navigator.push(context, FadeSlideRoute(page: const EditProfileScreen()));
                        if (updated == true) {
                          _loadProfileData();
                        }
                      },
                    ),
                    _MenuData(
                      icon: Icons.lock_outline_rounded,
                      title: 'Ubah Password',
                      onTap: () {
                        Navigator.push(context, FadeSlideRoute(page: const ChangePasswordScreen()));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text('Bantuan & Informasi', style: AppTheme.heading3),
                const SizedBox(height: 12),
                _buildMenuCard(
                  items: [
                    _MenuData(
                      icon: Icons.help_outline_rounded,
                      title: 'Pusat Bantuan',
                      onTap: () {
                        Navigator.push(context, FadeSlideRoute(page: const HelpCenterScreen()));
                      },
                    ),
                    _MenuData(
                      icon: Icons.description_outlined,
                      title: 'Syarat & Ketentuan',
                      onTap: () {
                        Navigator.push(context, FadeSlideRoute(page: const TermsScreen()));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded, size: 20),
                    label: const Text('Keluar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.danger,
                      side: const BorderSide(color: AppTheme.danger, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
                      textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: content,
    );
  }

  Widget _buildMenuCard({required List<_MenuData> items}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: item.onTap,
                  borderRadius: index == 0
                      ? BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge))
                      : index == items.length - 1
                          ? BorderRadius.vertical(bottom: Radius.circular(AppTheme.radiusLarge))
                          : BorderRadius.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppTheme.inputBackground,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item.icon, size: 20, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            item.title,
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                      ],
                    ),
                  ),
                ),
              ),
              if (index < items.length - 1)
                const Divider(color: AppTheme.border, height: 1, indent: 64, endIndent: 16),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuData {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  _MenuData({required this.icon, required this.title, required this.onTap});
}
