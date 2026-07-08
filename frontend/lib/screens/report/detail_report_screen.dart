import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../models/item_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/page_transitions.dart';
import '../claims/manage_claims_screen.dart';
import '../claims/claim_screen.dart';

class DetailReportScreen extends StatefulWidget {
  final ItemModel item;
  const DetailReportScreen({super.key, required this.item});

  @override
  State<DetailReportScreen> createState() => _DetailReportScreenState();
}

class _DetailReportScreenState extends State<DetailReportScreen> {
  ItemModel? _item;
  bool _isLoading = true;
  int? _currentUserId;
  String? _currentUserName;
  String? _currentUserNim;
  bool _hasClaimed = false;
  String _claimStatus = '';

  @override
  void initState() {
    super.initState();
    _item = widget.item; // initial data
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final profile = await ApiService.getProfile();
      if (profile != null && mounted) {
        setState(() {
          _currentUserId = profile['user']['id'];
          _currentUserName = profile['user']['name'];
          _currentUserNim = profile['user']['nim'];
        });
      }

      final data = await ApiService.getItemDetail(widget.item.id);
      if (data != null && mounted) {
        setState(() => _item = data);

        final myClaims = await ApiService.getMyClaims();
        final match = myClaims.where((c) => c.itemId == widget.item.id);
        if (match.isNotEmpty) {
          setState(() {
            _hasClaimed = true;
            _claimStatus = match.first.status;
          });
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _isLoading = false);
  }



  Future<void> _launchWhatsApp(String phone) async {
    var cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '62${cleanPhone.substring(1)}';
    }

    final claimantName = _currentUserName ?? 'Pengguna';
    final claimantNim = _currentUserNim ?? '-';

    final message = Uri.encodeComponent(
        'Halo, saya $claimantName (NIM: $claimantNim). Saya mengajukan klaim atas barang "${_item!.name}" yang Anda temukan di FindMe Kampus. Klaim kepemilikan saya telah disetujui. Bagaimana saya bisa menghubungi Anda untuk mengambil barang tersebut?');

    final url = Uri.parse('https://wa.me/$cleanPhone?text=$message');

    if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // launched
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Tidak dapat membuka WhatsApp',
                  style: GoogleFonts.plusJakartaSans()),
              backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  Future<void> _deleteReport() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        title: Text('Hapus Laporan', style: AppTheme.heading3),
        content: Text('Tindakan ini tidak dapat dibatalkan.',
            style: AppTheme.body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: Text('Hapus', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final ok = await ApiService.deleteItem(_item!.id);
      if (mounted) {
        setState(() => _isLoading = false);
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Laporan berhasil dihapus',
                    style: GoogleFonts.plusJakartaSans()),
                backgroundColor: AppTheme.success),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Gagal menghapus laporan',
                    style: GoogleFonts.plusJakartaSans()),
                backgroundColor: AppTheme.danger),
          );
        }
      }
    }
  }

  Future<void> _markAsReturned() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        title: Text('Barang Sudah Dikembalikan?', style: AppTheme.heading3),
        content: Text(
            'Tindakan ini akan mengarsipkan laporan.',
            style: AppTheme.body),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            child: Text('Ya, Sudah', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.updateItemStatus(
          itemId: _item!.id, status: 'returned');
      if (mounted) {
        setState(() => _isLoading = false);
        if (res.containsKey('item')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Status diperbarui!',
                    style: GoogleFonts.plusJakartaSans()),
                backgroundColor: AppTheme.success),
          );
          _fetchDetail();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(res['message'] ?? 'Gagal memperbarui.',
                    style: GoogleFonts.plusJakartaSans()),
                backgroundColor: AppTheme.danger),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Terjadi kesalahan jaringan',
                  style: GoogleFonts.plusJakartaSans()),
              backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari yang lalu';
    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  Widget _buildApprovedBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.success),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppTheme.success),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Klaim Anda telah disetujui. Silakan hubungi pemilik barang.',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.success, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: AppTheme.body.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _item == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    final item = _item!;
    final imageUrl = item.imagePath != null && item.imagePath!.isNotEmpty
        ? '${ApiConfig.hostUrl}/${item.imagePath}'
        : null;
    final isOwner = _currentUserId == item.userId;
    final isApproved = _claimStatus == 'approved';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image with curved bottom
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                      child: Container(
                        height: 320,
                        width: double.infinity,
                        color: AppTheme.inputBackground,
                        child: imageUrl != null
                            ? Image.network(imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.image_not_supported_outlined,
                                        size: 64, color: AppTheme.textSecondary)))
                            : const Center(
                                child: Icon(Icons.image_outlined,
                                    size: 64, color: AppTheme.textSecondary)),
                      ),
                    ),
                    Positioned(
                      right: 24,
                      bottom: -16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: item.type == 'lost' ? AppTheme.danger : AppTheme.success,
                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Text(
                          item.type == 'lost' ? 'HILANG' : 'DITEMUKAN',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Name & Time
                      Text(
                        item.name,
                        style: AppTheme.heading1,
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          text: 'Dilaporkan oleh: ',
                          style: AppTheme.caption.copyWith(fontSize: 13),
                          children: [
                            TextSpan(
                              text: item.user?.name ?? 'Anonim',
                              style: AppTheme.caption.copyWith(
                                  fontSize: 13,
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _timeAgo(item.createdAt),
                        style: AppTheme.caption,
                      ),
                      const SizedBox(height: 24),
                      
                      // Claim Status Banner (If Approved)
                      if (isApproved) ...[
                        _buildApprovedBanner(),
                        const SizedBox(height: 24),
                      ],

                      // Location & Date
                      _buildInfoRow('Lokasi Kejadian', item.location),
                      const SizedBox(height: 16),
                      _buildInfoRow('Tanggal Kejadian', '${DateFormat('dd MMM yyyy, HH:mm').format(item.date)} WIB'),
                      const SizedBox(height: 24),

                      // Description
                      Text('Deskripsi', style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      const SizedBox(height: 8),
                      Text(
                        item.description,
                        style: AppTheme.body,
                      ),
                      const SizedBox(height: 32),

                      // Custody info
                      if (item.custodianType != null && item.custodianName != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.inputBackground,
                            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.security_rounded, color: AppTheme.textSecondary, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Informasi Penitipan',
                                        style: GoogleFonts.plusJakartaSans(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: AppTheme.textPrimary)),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Dititipkan kepada ${item.custodianType == 'security' ? 'Satpam' : 'Laboran'}: ${item.custodianName}',
                                      style: AppTheme.caption,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Action section
                      if (isOwner) ...[
                        if (item.type == 'found' && item.status != 'returned') ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  FadeSlideRoute(
                                    page: ManageClaimsScreen(
                                      itemId: item.id,
                                      itemName: item.name,
                                    ),
                                  ),
                                ).then((_) => _fetchDetail());
                              },
                              style: AppTheme.primaryButton,
                              child: const Text('Manajemen Klaim'),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _markAsReturned,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.success,
                                side: const BorderSide(color: AppTheme.success, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Barang Sudah Dikembalikan', style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ] else ...[
                        if (item.type == 'found') ...[
                          if (item.status != 'returned' || _hasClaimed) ...[
                            if (!_hasClaimed) ...[
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      FadeSlideRoute(page: ClaimScreen(item: item)),
                                    ).then((res) {
                                      if (res == true) _fetchDetail();
                                    });
                                  },
                                  style: AppTheme.primaryButton,
                                  child: const Text('Ajukan Klaim'),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ] else if (!isApproved) ...[
                              _buildClaimFeedback(),
                              const SizedBox(height: 16),
                            ]
                          ],
                        ],
                      ],

                      // WhatsApp / Share buttons
                      if (!isOwner) ...[
                        if (isApproved) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                              label: const Text('Hubungi via WhatsApp'),
                              onPressed: () => _launchWhatsApp(item.user!.phoneNumber!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
                                elevation: 4,
                                textStyle: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ] else if (item.type == 'lost') ...[
                           SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.share_outlined, size: 20, color: AppTheme.accent),
                              label: Text('Bagikan', style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary)),
                              onPressed: () {},
                              style: AppTheme.outlineButton,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        if (!_hasClaimed && item.type == 'found') ...[
                           SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.share_outlined, size: 20, color: AppTheme.accent),
                              label: Text('Bagikan', style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary)),
                              onPressed: () {},
                              style: AppTheme.outlineButton,
                            ),
                          ),
                        ]
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Custom App Bar (Transparent to white gradient, or just floating back button)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppTheme.cardShadow,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          if (isOwner && item.status != 'returned')
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.cardShadow,
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
                  onPressed: _deleteReport,
                ),
              ),
            ),
        ],
      ),
    );
  }



  Widget _buildClaimFeedback() {
    final isRejected = _claimStatus == 'rejected';
    final color = isRejected ? AppTheme.danger : const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isRejected ? Icons.cancel_rounded : Icons.pending_rounded,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRejected ? 'Klaim Ditolak' : 'Menunggu Persetujuan',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 14, color: color),
                ),
                const SizedBox(height: 2),
                Text(
                  isRejected ? 'Pembuktian tidak sesuai.' : 'Menunggu verifikasi dari penemu.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
