import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import '../../../models/item_model.dart';
import '../../../models/claim_model.dart';
import '../../../utils/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // Stats
  Map<String, dynamic>? _stats;

  // Data lists
  List<dynamic> _users = [];
  List<ItemModel> _items = [];
  List<ClaimModel> _claims = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _loadTabContent(_tabController.index);
      }
    });
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchStats(),
      _fetchUsers(),
      _fetchItems(),
      _fetchClaims(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadTabContent(int index) async {
    setState(() => _isLoading = true);
    if (index == 0) await _fetchStats();
    if (index == 1) await _fetchUsers();
    if (index == 2) await _fetchItems();
    if (index == 3) await _fetchClaims();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchStats() async {
    try {
      final data = await ApiService.getAdminStats();
      if (mounted) _stats = data;
    } catch (_) {}
  }

  Future<void> _fetchUsers() async {
    try {
      final data = await ApiService.getAdminUsers();
      if (mounted) _users = data;
    } catch (_) {}
  }

  Future<void> _fetchItems() async {
    try {
      final data = await ApiService.getAdminItems();
      if (mounted) _items = data;
    } catch (_) {}
  }

  Future<void> _fetchClaims() async {
    try {
      final data = await ApiService.getAdminClaims();
      if (mounted) _claims = data;
    } catch (_) {}
  }

  Future<void> _deleteUser(int id, String name) async {
    final confirm = await _showConfirmDialog(
      title: 'Hapus Pengguna',
      content: 'Apakah Anda yakin ingin menghapus pengguna "$name" beserta seluruh laporan dan klaim miliknya? Tindakan ini tidak dapat dibatalkan.',
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await ApiService.deleteAdminUser(id);
      if (success) {
        _showSnackBar('Pengguna berhasil dihapus', AppTheme.success);
        await _loadAllData();
      } else {
        _showSnackBar('Gagal menghapus pengguna', AppTheme.danger);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteItem(int id, String name) async {
    final confirm = await _showConfirmDialog(
      title: 'Hapus Laporan',
      content: 'Apakah Anda yakin ingin menghapus laporan "$name" secara permanen?',
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await ApiService.deleteAdminItem(id);
      if (success) {
        _showSnackBar('Laporan berhasil dihapus', AppTheme.success);
        await _loadAllData();
      } else {
        _showSnackBar('Gagal menghapus laporan', AppTheme.danger);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateClaimStatus(int id, String status) async {
    final confirm = await _showConfirmDialog(
      title: status == 'approved' ? 'Setujui Klaim' : 'Tolak Klaim',
      content: status == 'approved'
          ? 'Apakah Anda yakin ingin MENYETUJUI klaim ini? Laporan barang ini akan otomatis ditandai selesai dan klaim lain akan ditolak.'
          : 'Apakah Anda yakin ingin MENOLAK klaim ini?',
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await ApiService.updateAdminClaimStatus(id, status);
      if (success) {
        _showSnackBar(
          status == 'approved' ? 'Klaim disetujui' : 'Klaim ditolak',
          status == 'approved' ? AppTheme.success : AppTheme.danger,
        );
        await _loadAllData();
      } else {
        _showSnackBar('Gagal memperbarui status klaim', AppTheme.danger);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool?> _showConfirmDialog({required String title, required String content}) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        title: Text(title, style: AppTheme.heading3),
        content: Text(content, style: AppTheme.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: Text('Ya, Lanjutkan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          'Dashboard Admin',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          indicatorColor: AppTheme.accent,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded, size: 20), text: 'Stats'),
            Tab(icon: Icon(Icons.people_alt_rounded, size: 20), text: 'User'),
            Tab(icon: Icon(Icons.assignment_rounded, size: 20), text: 'Laporan'),
            Tab(icon: Icon(Icons.verified_user_rounded, size: 20), text: 'Klaim'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildUsersTab(),
                _buildReportsTab(),
                _buildClaimsTab(),
              ],
            ),
    );
  }

  // --- TAB BUILDERS ---

  Widget _buildOverviewTab() {
    if (_stats == null) {
      return const Center(child: Text('Data tidak tersedia'));
    }

    final claimsMap = _stats!['claims'] as Map<String, dynamic>;

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ringkasan Platform', style: AppTheme.heading3),
            const SizedBox(height: 16),
            
            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Total Pengguna',
                    value: _stats!['users_count'].toString(),
                    icon: Icons.people_alt_outlined,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'Laporan Selesai',
                    value: _stats!['returned_count'].toString(),
                    icon: Icons.check_circle_outline_rounded,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Barang Hilang',
                    value: _stats!['lost_count'].toString(),
                    icon: Icons.error_outline_rounded,
                    color: AppTheme.danger,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    title: 'Barang Ditemukan',
                    value: _stats!['found_count'].toString(),
                    icon: Icons.inventory_2_outlined,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            Text('Statistik Klaim Barang', style: AppTheme.heading3),
            const SizedBox(height: 16),
            
            // Claim details card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                border: Border.all(color: AppTheme.border),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                children: [
                  _buildClaimStatsRow('Menunggu Persetujuan', claimsMap['pending'].toString(), AppTheme.warning),
                  const Divider(color: AppTheme.border, height: 24),
                  _buildClaimStatsRow('Disetujui', claimsMap['approved'].toString(), AppTheme.success),
                  const Divider(color: AppTheme.border, height: 24),
                  _buildClaimStatsRow('Ditolak', claimsMap['rejected'].toString(), AppTheme.danger),
                  const Divider(color: AppTheme.border, height: 24),
                  _buildClaimStatsRow('Total Seluruh Klaim', claimsMap['total'].toString(), AppTheme.textPrimary, isBold: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    if (_users.isEmpty) {
      return const Center(child: Text('Tidak ada pengguna terdaftar'));
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: AppTheme.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final u = _users[index] as Map<String, dynamic>;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(color: AppTheme.border),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: AppTheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u['name'] ?? '', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text('${u['nim']} • Angkatan ${u['batch']}', style: AppTheme.caption),
                      Text(u['email'] ?? '', style: AppTheme.caption),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteUser(u['id'], u['name'] ?? 'User'),
                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportsTab() {
    if (_items.isEmpty) {
      return const Center(child: Text('Tidak ada laporan barang'));
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: AppTheme.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          final formattedDate = DateFormat('dd MMM yyyy').format(item.date);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(color: AppTheme.border),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image or icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  child: item.imagePath != null
                      ? Image.network(
                          '${ApiConfig.hostUrl}/${item.imagePath}',
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildIconPlaceholder(item.type),
                        )
                      : _buildIconPlaceholder(item.type),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AppTheme.typeBadge(item.type),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Dilaporkan oleh: ${item.user?.name ?? 'Anonim'}', style: AppTheme.caption),
                      Text('Lokasi: ${item.location} • $formattedDate', style: AppTheme.caption),
                      const SizedBox(height: 6),
                      AppTheme.statusBadge(item.status),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteItem(item.id, item.name),
                  icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildClaimsTab() {
    if (_claims.isEmpty) {
      return const Center(child: Text('Tidak ada klaim pengajuan'));
    }

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: AppTheme.primary,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: _claims.length,
        itemBuilder: (context, index) {
          final claim = _claims[index];
          final isPending = claim.status == 'pending';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(color: AppTheme.border),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        claim.item?.name ?? 'Barang Hilang',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                      ),
                    ),
                    AppTheme.statusBadge(claim.status),
                  ],
                ),
                const Divider(color: AppTheme.border, height: 20),
                
                Text('Pemilik Laporan (Finder):', style: AppTheme.caption.copyWith(fontWeight: FontWeight.bold)),
                Text('${claim.item?.user?.name ?? 'Anonim'} (${claim.item?.user?.email ?? '-'})', style: AppTheme.body.copyWith(fontSize: 13)),
                const SizedBox(height: 10),

                Text('Pengaju Klaim (Claimant):', style: AppTheme.caption.copyWith(fontWeight: FontWeight.bold)),
                Text('${claim.claimant?.name ?? 'Anonim'} (${claim.claimant?.email ?? '-'})', style: AppTheme.body.copyWith(fontSize: 13)),
                const SizedBox(height: 12),

                // Question and Answer section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.inputBackground,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pertanyaan Verifikasi:',
                        style: AppTheme.caption.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primary),
                      ),
                      Text(
                        claim.item?.verificationQuestion ?? 'Deskripsikan barang ini.',
                        style: AppTheme.body.copyWith(fontSize: 13, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Jawaban Pengaju:',
                        style: AppTheme.caption.copyWith(fontWeight: FontWeight.bold, color: AppTheme.accent),
                      ),
                      Text(
                        claim.verificationAnswer,
                        style: AppTheme.body.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                
                if (isPending) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _updateClaimStatus(claim.id, 'rejected'),
                        icon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.danger),
                        label: const Text('Tolak'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.danger,
                          side: const BorderSide(color: AppTheme.danger),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => _updateClaimStatus(claim.id, 'approved'),
                        icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                        label: const Text('Setujui'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // --- STAT CARD WIDGETS ---

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(title, style: AppTheme.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildClaimStatsRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconPlaceholder(String type) {
    return Container(
      width: 64,
      height: 64,
      color: AppTheme.inputBackground,
      child: Icon(
        type == 'lost' ? Icons.search_rounded : Icons.inventory_2_outlined,
        color: AppTheme.textSecondary,
        size: 28,
      ),
    );
  }
}
