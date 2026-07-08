import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('Syarat & Ketentuan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 18, color: AppTheme.textPrimary)),
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
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Terakhir diperbarui: 12 Juli 2026', style: AppTheme.caption),
              const SizedBox(height: 24),
              _buildSection('1. Penggunaan Aplikasi', 'Dengan menggunakan FindMe Kampus, Anda setuju untuk memberikan informasi yang akurat dan jujur terkait barang hilang atau temuan. Aplikasi ini bertujuan membantu komunitas kampus dalam menemukan kembali barang yang hilang.'),
              _buildSection('2. Pelaporan Barang', 'Pengguna dilarang melaporkan informasi palsu. Setiap barang temuan yang tidak diklaim dalam jangka waktu 3 bulan dapat diserahkan ke pihak keamanan kampus sesuai prosedur yang berlaku.'),
              _buildSection('3. Privasi Data', 'Kami menjaga privasi data Anda. Informasi pribadi seperti email dan nomor telepon hanya digunakan untuk keperluan verifikasi dan komunikasi terkait barang hilang/temuan.'),
              _buildSection('4. Tanggung Jawab', 'FindMe Kampus hanya bertindak sebagai perantara informasi. Kami tidak bertanggung jawab atas kerusakan atau kehilangan lebih lanjut pada barang yang telah dilaporkan atau diserahkan antar pengguna.'),
              _buildSection('5. Pembekuan Akun', 'Administrator berhak membekukan atau menghapus akun yang terbukti menyalahgunakan platform, memanipulasi klaim, atau melanggar norma komunitas kampus.'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.heading3),
          const SizedBox(height: 8),
          Text(content, style: AppTheme.body.copyWith(color: AppTheme.textSecondary, height: 1.6)),
        ],
      ),
    );
  }
}
