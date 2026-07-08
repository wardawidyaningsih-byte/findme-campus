import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../models/claim_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/shimmer_loading.dart';

class ManageClaimsScreen extends StatefulWidget {
  final int itemId;
  final String itemName;

  const ManageClaimsScreen({super.key, required this.itemId, required this.itemName});

  @override
  State<ManageClaimsScreen> createState() => _ManageClaimsScreenState();
}

class _ManageClaimsScreenState extends State<ManageClaimsScreen> with SingleTickerProviderStateMixin {
  List<ClaimModel> _claims = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchClaims();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchClaims() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getItemClaims(widget.itemId);
      if (mounted) {
        setState(() {
          _claims = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processClaim(int claimId, String status) async {
    final actionText = status == 'approved' ? 'menyetujui' : 'menolak';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        title: Text('Konfirmasi ${status == 'approved' ? 'Persetujuan' : 'Penolakan'}', style: AppTheme.heading3),
        content: Text(
          'Apakah Anda yakin ingin $actionText klaim kepemilikan ini? ${status == 'approved' ? 'Tindakan ini akan menyetujui klaim dan menolak klaim lain yang tertunda.' : ''}',
          style: AppTheme.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: status == 'approved' ? AppTheme.primary : AppTheme.danger,
            ),
            child: Text(status == 'approved' ? 'Setujui' : 'Tolak', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.updateClaimStatus(claimId: claimId, status: status);
      if (mounted) {
        if (res.containsKey('claim')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(status == 'approved' ? 'Klaim berhasil disetujui!' : 'Klaim berhasil ditolak', style: GoogleFonts.plusJakartaSans()),
              backgroundColor: status == 'approved' ? AppTheme.success : AppTheme.danger,
            ),
          );
          if (status == 'approved') {
            Navigator.pop(context, true);
          } else {
            _fetchClaims();
          }
        } else {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Gagal memproses klaim', style: GoogleFonts.plusJakartaSans()), backgroundColor: AppTheme.danger),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan jaringan', style: GoogleFonts.plusJakartaSans()), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final pendingClaims = _claims.where((c) => c.status == 'pending').toList();
    final approvedClaims = _claims.where((c) => c.status == 'approved').toList();
    final rejectedClaims = _claims.where((c) => c.status == 'rejected').toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manajemen Klaim', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            Text('Kelola klaim barang yang Anda temukan', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w400, color: AppTheme.textSecondary)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelColor: AppTheme.primary,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 13),
          dividerColor: AppTheme.border,
          tabs: [
            Tab(text: 'Menunggu (${pendingClaims.length})'),
            Tab(text: 'Disetujui (${approvedClaims.length})'),
            Tab(text: 'Ditolak (${rejectedClaims.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? ShimmerLoading.itemListShimmer()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildClaimList(pendingClaims, emptyMessage: 'Tidak ada klaim yang menunggu persetujuan.'),
                _buildClaimList(approvedClaims, emptyMessage: 'Belum ada klaim yang disetujui.'),
                _buildClaimList(rejectedClaims, emptyMessage: 'Tidak ada klaim yang ditolak.'),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppTheme.textSecondary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Setelah disetujui, informasi kontak Anda akan dibagikan ke pemilik barang.',
                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontSize: 12, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClaimList(List<ClaimModel> claimsList, {required String emptyMessage}) {
    if (claimsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: AppTheme.cardShadow),
              child: const Icon(Icons.assignment_outlined, size: 56, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            Text('Kosong', style: AppTheme.heading3),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(emptyMessage, textAlign: TextAlign.center, style: AppTheme.body),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: claimsList.length,
      itemBuilder: (context, index) {
        final claim = claimsList[index];
        final claimant = claim.claimant;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: AppTheme.cardShadow,
            border: Border.all(color: AppTheme.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(color: AppTheme.inputBackground, shape: BoxShape.circle),
                      child: const Icon(Icons.person_rounded, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.itemName, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          const SizedBox(height: 4),
                          RichText(
                            text: TextSpan(
                              text: 'Oleh: ',
                              style: AppTheme.caption.copyWith(fontSize: 13),
                              children: [
                                TextSpan(
                                  text: claimant?.name ?? 'Anonim',
                                  style: AppTheme.caption.copyWith(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Klaim diajukan ${_timeAgo(claim.createdAt)}', style: AppTheme.caption.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.inputBackground,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Jawaban Verifikasi:', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      const SizedBox(height: 8),
                      Text(claim.verificationAnswer, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
                if (claim.status == 'pending') ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _processClaim(claim.id, 'rejected'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.danger,
                            side: const BorderSide(color: AppTheme.danger, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusPill)),
                          ),
                          child: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _processClaim(claim.id, 'approved'),
                          style: AppTheme.primaryButton,
                          child: const Text('Setujui'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
