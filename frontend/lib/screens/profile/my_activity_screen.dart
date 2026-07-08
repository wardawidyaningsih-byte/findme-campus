import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../models/item_model.dart';
import '../../models/claim_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/shimmer_loading.dart';
import '../../utils/page_transitions.dart';
import '../report/detail_report_screen.dart';

class MyActivityScreen extends StatefulWidget {
  const MyActivityScreen({super.key});

  @override
  State<MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends State<MyActivityScreen> with SingleTickerProviderStateMixin {
  List<ItemModel> _myItems = [];
  List<ClaimModel> _myClaims = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final items = await ApiService.getMyItems();
      final claims = await ApiService.getMyClaims();

      if (mounted) {
        setState(() {
          _myItems = items;
          _myClaims = claims;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aktivitas Saya', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            Text('Pantau laporan dan klaim Anda', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w400, color: AppTheme.textSecondary)),
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
          tabs: const [
            Tab(text: 'Laporan Saya'),
            Tab(text: 'Klaim Saya'),
          ],
        ),
      ),
      body: _isLoading
          ? ShimmerLoading.itemListShimmer()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildItemList(_myItems, 'Belum ada laporan barang yang Anda buat.'),
                _buildClaimList(_myClaims, 'Belum ada klaim kepemilikan yang Anda ajukan.'),
              ],
            ),
    );
  }

  Widget _buildItemList(List<ItemModel> items, String emptyMessage) {
    if (items.isEmpty) {
      return _buildEmptyState(emptyMessage, Icons.list_alt_rounded);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final imageUrl = item.imagePath != null ? '${ApiConfig.hostUrl}/${item.imagePath}' : null;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: AppTheme.cardShadow,
              border: Border.all(color: AppTheme.border),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                onTap: () {
                  Navigator.push(
                    context,
                    FadeSlideRoute(page: DetailReportScreen(item: item)),
                  ).then((_) => _loadData());
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'my-item-${item.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          child: Container(
                            width: 64,
                            height: 64,
                            color: AppTheme.inputBackground,
                            child: imageUrl != null
                                ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: AppTheme.textSecondary))
                                : const Icon(Icons.image_outlined, color: AppTheme.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                AppTheme.typeBadge(item.type),
                                AppTheme.statusBadge(item.status, fontSize: 9),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildClaimList(List<ClaimModel> claims, String emptyMessage) {
    if (claims.isEmpty) {
      return _buildEmptyState(emptyMessage, Icons.assignment_outlined);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: claims.length,
        itemBuilder: (context, index) {
          final claim = claims[index];
          if (claim.item == null) return const SizedBox.shrink();
          final item = claim.item!;
          final imageUrl = item.imagePath != null ? '${ApiConfig.hostUrl}/${item.imagePath}' : null;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              boxShadow: AppTheme.cardShadow,
              border: Border.all(color: AppTheme.border),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                onTap: () {
                  Navigator.push(
                    context,
                    FadeSlideRoute(page: DetailReportScreen(item: item)),
                  ).then((_) => _loadData());
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        child: Container(
                          width: 64,
                          height: 64,
                          color: AppTheme.inputBackground,
                          child: imageUrl != null
                              ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, color: AppTheme.textSecondary))
                              : const Icon(Icons.image_outlined, color: AppTheme.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                            const SizedBox(height: 4),
                            Text('Penemu: ${item.user?.name ?? 'Anonim'}', style: AppTheme.caption),
                            const SizedBox(height: 6),
                            _claimStatusBadge(claim.status),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _claimStatusBadge(String status) {
    Color color;
    String text;
    if (status == 'approved') {
      color = AppTheme.success;
      text = 'Disetujui';
    } else if (status == 'rejected') {
      color = AppTheme.danger;
      text = 'Ditolak';
    } else {
      color = AppTheme.warning;
      text = 'Menunggu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
      child: Text(text, style: GoogleFonts.plusJakartaSans(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: AppTheme.cardShadow),
            child: Icon(icon, size: 48, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(message, textAlign: TextAlign.center, style: AppTheme.body),
          ),
        ],
      ),
    );
  }
}
