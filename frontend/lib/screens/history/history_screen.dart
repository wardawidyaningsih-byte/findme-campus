import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../models/item_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/shimmer_loading.dart';
import '../../utils/page_transitions.dart';
import '../report/detail_report_screen.dart';

class HistoryScreen extends StatefulWidget {
  final bool embedded;

  const HistoryScreen({super.key, this.embedded = false});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  List<ItemModel> _historyItems = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getHistory();
      if (mounted) {
        setState(() {
          _historyItems = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Currently API doesn't distinguish between my lost items returned vs my found items returned
    // We'll just split them by type 'lost' vs 'found' for demonstration of the tabs as per reference
    final asOwner = _historyItems.where((i) => i.type == 'lost').toList();
    final asFinder = _historyItems.where((i) => i.type == 'found').toList();

    final content = Column(
      children: [
        // Header
        Container(
          color: Colors.white,
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!widget.embedded)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Riwayat',
                    style: AppTheme.heading1,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Riwayat pelaporan barang Anda',
                    style: AppTheme.caption,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Tabs
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.inputBackground,
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                    labelColor: AppTheme.textPrimary,
                    unselectedLabelColor: AppTheme.textSecondary,
                    labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 13),
                    unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 13),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Sebagai Pemilik'),
                      Tab(text: 'Sebagai Penemu'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),

        // Body
        Expanded(
          child: _isLoading
              ? ShimmerLoading.itemListShimmer()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildHistoryList(asOwner, 'Belum ada riwayat sebagai pemilik.'),
                    _buildHistoryList(asFinder, 'Belum ada riwayat sebagai penemu.'),
                  ],
                ),
        ),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: content,
    );
  }

  Widget _buildHistoryList(List<ItemModel> items, String emptyMessage) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: AppTheme.cardShadow),
              child: const Icon(Icons.history_rounded, size: 56, color: AppTheme.textSecondary),
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

    return RefreshIndicator(
      onRefresh: _fetchHistory,
      color: AppTheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Image
                      Hero(
                        tag: 'history-image-${item.id}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          child: Container(
                            width: 80,
                            height: 80,
                            color: AppTheme.inputBackground,
                            child: imageUrl != null
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported_outlined, size: 32, color: AppTheme.textSecondary),
                                  )
                                : const Icon(Icons.image_outlined, size: 32, color: AppTheme.textSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                  ),
                                  child: Text(
                                    'Diserahkan',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.success,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.location,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTheme.caption,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_month_outlined, size: 14, color: AppTheme.textSecondary),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('dd MMM yyyy').format(item.date),
                                  style: AppTheme.caption,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
}
