import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/item_model.dart';
import '../utils/app_theme.dart';
import '../utils/page_transitions.dart';
import '../utils/particle_background.dart';
import 'report/create_report_screen.dart';
import 'report/detail_report_screen.dart';
import 'profile/profile_screen.dart';
import 'history/history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      final profile = await ApiService.getProfile();
      if (profile != null && mounted) {
        setState(() {
          _userName = profile['user']['name'] ?? '';
        });
      }
    } catch (_) {}
  }

  void _onNavTap(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        SlideUpRoute(page: const CreateReportScreen()),
      ).then((value) {
        if (value == true) {
          setState(() => _currentNavIndex = 0);
        }
      });
      return;
    }
    setState(() => _currentNavIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Light icons for dark header
      ),
    );

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: IndexedStack(
        index: _currentNavIndex == 1 ? 0 : _currentNavIndex > 1 ? _currentNavIndex - 1 : _currentNavIndex,
        children: [
          _HomeTab(userName: _userName, onRefreshName: _loadUserName),
          const HistoryScreen(embedded: true),
          const ProfileScreen(embedded: true),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _navItem(Icons.home_filled, Icons.home_outlined, 'Beranda', 0),
                _navItem(Icons.add_box, Icons.add_box_outlined, 'Lapor', 1),
                _navItem(Icons.history_rounded, Icons.history_outlined, 'Riwayat', 2),
                _navItem(Icons.person, Icons.person_outline, 'Akun', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData activeIcon, IconData inactiveIcon, String label, int index) {
    final isActive = _currentNavIndex == index;
    return InkWell(
      onTap: () => _onNavTap(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              color: isActive ? AppTheme.primary : AppTheme.textSecondary,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: isActive ? AppTheme.primary : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  final String userName;
  final VoidCallback onRefreshName;
  const _HomeTab({required this.userName, required this.onRefreshName});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  List<ItemModel> _items = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String? _selectedCategory;
  String? _selectedType;
  String? _selectedLocation;
  String? _selectedStatus;
  DateTime? _selectedDate;

  final List<Map<String, dynamic>> _categoriesList = [
    {'name': 'Semua', 'icon': Icons.grid_view_rounded},
    {'name': 'Elektronik', 'icon': Icons.devices_rounded},
    {'name': 'Aksesoris', 'icon': Icons.watch_rounded},
    {'name': 'Kunci', 'icon': Icons.vpn_key_rounded},
    {'name': 'Lainnya', 'icon': Icons.category_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);
    try {
      final dateStr = _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : null;
      final data = await ApiService.getItems(
        search: _searchController.text.trim(),
        type: _selectedType,
        category: _selectedCategory == 'Semua' ? null : _selectedCategory,
        location: _selectedLocation,
        date: dateStr,
        status: _selectedStatus,
      );

      if (mounted) {
        setState(() {
          _items = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedType = null;
      _selectedCategory = null;
      _selectedLocation = null;
      _selectedStatus = null;
      _selectedDate = null;
      _searchController.clear();
    });
    _fetchItems();
  }

  void _showFilterSheet() {
    // Show standard filter modal (simplified for brevity, matching old logic but new colors)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filter Laporan', style: AppTheme.heading3),
                  TextButton(
                    onPressed: () {
                      _clearFilters();
                      Navigator.pop(context);
                    },
                    child: Text('Reset', style: GoogleFonts.plusJakartaSans(color: AppTheme.danger, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const Divider(color: AppTheme.border),
              const SizedBox(height: 16),
              
              // Keep simple for now, can be fully customized later
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    _fetchItems();
                    Navigator.pop(context);
                  },
                  style: AppTheme.primaryButton,
                  child: const Text('Terapkan Filter'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit yang lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam yang lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari yang lalu';
    return DateFormat('dd MMM yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchItems,
      color: AppTheme.primary,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Header Section
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                child: Stack(
                  children: [
                    const Positioned.fill(
                      child: ParticleBackground(
                        particleCount: 40, // Lighter snow effect for header
                        child: SizedBox.expand(),
                      ),
                    ),
                    SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FindMe Kampus',
                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Halo, ${widget.userName.isNotEmpty ? widget.userName.split(' ').first : 'User'}!',
                        style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ayo bantu temukan barang yang hilang',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                              ),
                              child: TextField(
                                controller: _searchController,
                                onSubmitted: (_) => _fetchItems(),
                                style: AppTheme.body,
                                decoration: InputDecoration(
                                  hintText: 'Cari barang hilang...',
                                  hintStyle: AppTheme.caption,
                                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 22),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: _showFilterSheet,
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.filter_list_rounded, color: Colors.white, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Filter',
                                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ), // closes GestureDetector
                        ], // closes Row children
                      ), // closes Row
                    ], // closes Column children
                  ), // closes Column
                ), // closes Padding
              ), // closes SafeArea
            ], // closes Stack children
          ), // closes Stack
        ), // closes ClipRRect
      ), // closes Container
    ), // closes SliverToBoxAdapter

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Categories Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Kategori', style: AppTheme.heading3),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Categories Row
          SliverToBoxAdapter(
            child: SizedBox(
              height: 72,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _categoriesList.length,
                itemBuilder: (context, index) {
                  final cat = _categoriesList[index];
                  final isSelected = (_selectedCategory == cat['name']) || (_selectedCategory == null && cat['name'] == 'Semua');

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat['name'] == 'Semua' ? null : cat['name'];
                      });
                      _fetchItems();
                    },
                    child: Container(
                      width: 68,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primary : AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.border),
                        boxShadow: isSelected ? AppTheme.primaryShadow : [],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            cat['icon'],
                            color: isSelected ? Colors.white : AppTheme.textSecondary,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cat['name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.white : AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),

          // Barang Terbaru Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Barang Terbaru', style: AppTheme.heading3),
                  Text(
                    'Lihat semua',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Items List
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_items.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: AppTheme.border),
                    const SizedBox(height: 16),
                    Text('Belum ada laporan barang', style: AppTheme.body.copyWith(color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _items[index];
                    return ScrollAnimatedTile(
                      scrollController: _scrollController,
                      child: _buildItemCard(item),
                    );
                  },
                  childCount: _items.length,
                ),
              ),
            ),
            
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildItemCard(ItemModel item) {
    final isLost = item.type == 'lost';
    final accentColor = isLost ? AppTheme.danger : AppTheme.success;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailReportScreen(item: item)),
        ).then((_) => _fetchItems());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Vertical Accent Bar
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: accentColor,
                  ),
                ),
                const SizedBox(width: 8),
                // Image
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: item.imagePath != null && item.imagePath!.isNotEmpty
                          ? Image.network(
                              '${ApiConfig.hostUrl}/${item.imagePath}',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholderImage(item.type),
                            )
                          : _buildPlaceholderImage(item.type),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            AppTheme.typeBadge(item.type),
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
                                style: AppTheme.caption,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _timeAgo(item.createdAt),
                          style: AppTheme.caption,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(String type) {
    final isLost = type == 'lost';
    final tintColor = isLost ? AppTheme.danger : AppTheme.success;
    return Container(
      width: 80,
      height: 80,
      color: tintColor.withValues(alpha: 0.05),
      child: Icon(
        Icons.image_outlined,
        color: tintColor.withValues(alpha: 0.5),
        size: 32,
      ),
    );
  }
}

/// A dynamic scroll-driven animation widget that fades and scales items
/// into view smoothly as they enter the screen viewport from the bottom.
class ScrollAnimatedTile extends StatefulWidget {
  final Widget child;
  final ScrollController scrollController;

  const ScrollAnimatedTile({
    super.key,
    required this.child,
    required this.scrollController,
  });

  @override
  State<ScrollAnimatedTile> createState() => _ScrollAnimatedTileState();
}

class _ScrollAnimatedTileState extends State<ScrollAnimatedTile> {
  late final ValueNotifier<double> _ratioNotifier;

  @override
  void initState() {
    super.initState();
    _ratioNotifier = ValueNotifier<double>(0.0);
    widget.scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onScroll());
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _ratioNotifier.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;

    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject == null || !renderObject.attached) return;

    final RenderBox box = renderObject as RenderBox;
    final position = box.localToGlobal(Offset.zero);
    final double itemY = position.dy;
    final double itemHeight = box.size.height;
    final double screenHeight = MediaQuery.of(context).size.height;

    // Center of screen
    final double viewportCenter = screenHeight / 2;
    final double itemCenter = itemY + (itemHeight / 2);
    
    // Distance of this item center from viewport center
    final double distanceFromCenter = (itemCenter - viewportCenter).abs();
    
    // Normalize ratio: 0.0 at center of screen, 1.0 at top/bottom viewport bounds
    final double maxDistance = screenHeight / 2;
    final double ratio = (distanceFromCenter / maxDistance).clamp(0.0, 1.0);
    
    if (_ratioNotifier.value != ratio) {
      _ratioNotifier.value = ratio;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _ratioNotifier,
      builder: (context, ratio, child) {
        // Quad curve for smooth center focus transition
        final double curvedRatio = ratio * ratio;
        
        final double scale = 1.0 - (curvedRatio * 0.12);
        final double opacity = 1.0 - (curvedRatio * 0.55);
        
        return Opacity(
          opacity: opacity.clamp(0.5, 1.0),
          child: Transform.scale(
            scale: scale.clamp(0.88, 1.0),
            alignment: Alignment.center,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
