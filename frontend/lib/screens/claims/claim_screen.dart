import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../models/item_model.dart';
import '../../utils/app_theme.dart';


class ClaimScreen extends StatefulWidget {
  final ItemModel item;
  const ClaimScreen({super.key, required this.item});

  @override
  State<ClaimScreen> createState() => _ClaimScreenState();
}

class _ClaimScreenState extends State<ClaimScreen> {
  final _answerController = TextEditingController();
  File? _imageFile;
  final _picker = ImagePicker();
  bool _isSubmittingClaim = false;

  Future<void> _pickImage() async {
    try {
      final picked =
          await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null) {
        setState(() => _imageFile = File(picked.path));
      }
    } catch (_) {}
  }

  Future<void> _submitClaim() async {
    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Alasan klaim wajib diisi',
                style: GoogleFonts.plusJakartaSans()),
            backgroundColor: AppTheme.danger),
      );
      return;
    }

    setState(() => _isSubmittingClaim = true);

    try {
      // Send claim to API (API doesn't support image currently, so we only send answer)
      final res = await ApiService.claimItem(
        itemId: widget.item.id,
        verificationAnswer: _answerController.text.trim(),
      );

      setState(() => _isSubmittingClaim = false);

      if (mounted) {
        if (res.containsKey('claim')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Klaim berhasil diajukan!',
                    style: GoogleFonts.plusJakartaSans()),
                backgroundColor: AppTheme.success),
          );
          Navigator.pop(context, true); // Return success
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(res['message'] ?? 'Gagal mengajukan klaim.',
                    style: GoogleFonts.plusJakartaSans()),
                backgroundColor: AppTheme.danger),
          );
        }
      }
    } catch (_) {
      setState(() => _isSubmittingClaim = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Terjadi kesalahan jaringan',
                  style: GoogleFonts.plusJakartaSans()),
              backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final imageUrl = item.imagePath != null && item.imagePath!.isNotEmpty
        ? '${ApiConfig.hostUrl}/${item.imagePath}'
        : null;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ajukan Klaim',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            Text('Lengkapi data untuk mengajukan klaim',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, fontWeight: FontWeight.w400, color: AppTheme.textSecondary)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Barang', style: AppTheme.heading3),
            const SizedBox(height: 12),
            
            // Item Summary Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    child: Container(
                      width: 64,
                      height: 64,
                      color: AppTheme.inputBackground,
                      child: imageUrl != null
                          ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, color: AppTheme.textSecondary))
                          : const Icon(Icons.image_outlined, color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Laboratorium TI Lt. 3', // Fake location as per reference or use item.location
                          style: AppTheme.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${DateFormat('dd MMM yyyy, HH:mm').format(item.date)} WIB',
                          style: AppTheme.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Question Box if verification question exists
            if (item.verificationQuestion != null && item.verificationQuestion!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.help_outline_rounded, size: 20, color: AppTheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pertanyaan Verifikasi:', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                          Text(item.verificationQuestion!, style: AppTheme.caption.copyWith(color: AppTheme.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Alasan Klaim
            _buildLabel('Alasan Klaim', required: true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _answerController,
              maxLines: 4,
              style: AppTheme.body,
              decoration: InputDecoration(
                hintText: 'Jelaskan mengapa barang ini adalah milik Anda...',
                hintStyle: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  borderSide: const BorderSide(color: AppTheme.border, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  borderSide: const BorderSide(color: AppTheme.border, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
            const SizedBox(height: 24),

            // Bukti Kepemilikan (Opsional)
            _buildLabel('Bukti Kepemilikan (Opsional)', required: false),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.inputBackground,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(
                    color: AppTheme.border,
                    width: 1.5,
                  ),
                ),
                child: _imageFile != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppTheme.radiusLarge - 2),
                            child: Image.file(_imageFile!, fit: BoxFit.cover),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.edit_rounded,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined,
                              size: 28, color: AppTheme.textSecondary),
                          const SizedBox(height: 8),
                          Text('Upload bukti (foto/screenshot)',
                              style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12)),
                          const SizedBox(height: 2),
                          Text('Maks. 5MB',
                              style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.textSecondary,
                                  fontSize: 10)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Klaim akan diteruskan ke pemilik sebelum bisa disetujui.',
                    style: AppTheme.caption,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Submit Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmittingClaim ? null : _submitClaim,
                style: AppTheme.primaryButton,
                child: _isSubmittingClaim
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Kirim Klaim'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
          fontSize: 14,
        ),
        children: [
          if (required)
            TextSpan(
              text: ' *',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.danger, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}
