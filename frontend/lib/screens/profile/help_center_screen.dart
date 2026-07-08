import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text('Pusat Bantuan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 18, color: AppTheme.textPrimary)),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              ),
              child: Column(
                children: [
                  const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Bagaimana kami dapat membantu Anda?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('FAQ', style: AppTheme.heading3),
            const SizedBox(height: 16),
            _buildFaqItem('Bagaimana cara melaporkan barang hilang?', 'Gunakan tombol + di menu bawah, lalu pilih tab Hilang. Isi detail form selengkapnya lalu simpan.'),
            _buildFaqItem('Bagaimana cara mengklaim barang temuan?', 'Masuk ke detail barang temuan, lalu tekan tombol Ajukan Klaim. Anda akan diminta menjawab pertanyaan verifikasi kepemilikan.'),
            _buildFaqItem('Apa yang terjadi setelah klaim disetujui?', 'Anda akan melihat tombol WhatsApp untuk menghubungi penemu barang secara langsung dan mengatur tempat pengambilan.'),
            
            const SizedBox(height: 32),
            Text('Hubungi Kami', style: AppTheme.heading3),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.cardShadow,
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.email_outlined, color: AppTheme.primary),
                ),
                title: Text('Email Support', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text('support@findmekampus.id', style: AppTheme.caption),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.border),
      ),
      child: ExpansionTile(
        title: Text(question, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 14)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        iconColor: AppTheme.primary,
        collapsedIconColor: AppTheme.textSecondary,
        shape: const Border(),
        children: [
          Text(answer, style: AppTheme.body.copyWith(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
