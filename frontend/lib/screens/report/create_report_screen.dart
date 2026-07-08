import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedType = 'lost';
  final _nameController = TextEditingController();
  String? _selectedCategory;
  String? _selectedLocation;
  DateTime? _selectedDate;
  final _descriptionController = TextEditingController();

  // Found-specific fields
  final _verificationController = TextEditingController();
  bool _isCustody = false;
  String? _custodianType;
  final _custodianNameController = TextEditingController();

  File? _imageFile;
  final _picker = ImagePicker();
  bool _isLoading = false;

  final List<String> _categories = [
    'Elektronik',
    'Dokumen',
    'Aksesoris',
    'Kunci',
    'Peralatan Kuliah',
    'Lainnya'
  ];

  final List<String> _locations = [
    'Laboratorium Multimedia',
    'Laboratorium Jaringan',
    'Laboratorium Pemrograman',
    'Perpustakaan',
    'Ruang Kelas',
    'Kantin',
    'Lainnya'
  ];

  Future<void> _pickImage() async {
    try {
      final picked =
          await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null) {
        setState(() => _imageFile = File(picked.path));
      }
    } catch (_) {}
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silakan pilih tanggal kejadian',
              style: GoogleFonts.plusJakartaSans()),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);

      final res = await ApiService.createItem(
        type: _selectedType,
        name: _nameController.text.trim(),
        category: _selectedCategory!,
        location: _selectedLocation!,
        date: dateStr,
        description: _descriptionController.text.trim(),
        verificationQuestion:
            _selectedType == 'found' ? _verificationController.text.trim() : null,
        custodianType:
            _selectedType == 'found' && _isCustody ? _custodianType : null,
        custodianName: _selectedType == 'found' && _isCustody
            ? _custodianNameController.text.trim()
            : null,
        imageFile: _imageFile,
      );

      setState(() => _isLoading = false);

      if (mounted) {
        if (res.containsKey('item')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Laporan berhasil dibuat!',
                  style: GoogleFonts.plusJakartaSans()),
              backgroundColor: AppTheme.success,
            ),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(res['message'] ?? 'Gagal membuat laporan.',
                    style: GoogleFonts.plusJakartaSans()),
                backgroundColor: AppTheme.danger),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Terjadi kesalahan jaringan.',
                  style: GoogleFonts.plusJakartaSans()),
              backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Buat Laporan',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            Text('Laporkan barang yang hilang atau ditemukan',
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Type Toggle (Pill Shape)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          _typeToggle('Barang Hilang', 'lost', AppTheme.danger),
                          _typeToggle('Barang Ditemukan', 'found', AppTheme.success),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Photo label
                    _buildLabel('Foto Barang', required: true),
                    const SizedBox(height: 12),

                    // Image Picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 160,
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
                                    bottom: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(Icons.edit_rounded,
                                          color: Colors.white, size: 16),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_a_photo_outlined,
                                      size: 32, color: AppTheme.textSecondary),
                                  const SizedBox(height: 12),
                                  Text('Ketuk untuk upload foto',
                                      style: GoogleFonts.plusJakartaSans(
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Text('Maks. 5MB',
                                      style: GoogleFonts.plusJakartaSans(
                                          color: AppTheme.textSecondary,
                                          fontSize: 11)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Name Field
                    _buildLabel('Nama Barang', required: true),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      style: AppTheme.body,
                      decoration: AppTheme.inputDecoration(
                        label: 'Contoh: Laptop ASUS',
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 20),

                    // Category Dropdown
                    _buildLabel('Kategori', required: true),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      style: AppTheme.body,
                      decoration: AppTheme.inputDecoration(
                        label: 'Pilih Kategori',
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
                      items: _categories
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      validator: (val) => val == null ? 'Kategori wajib dipilih' : null,
                      onChanged: (val) => setState(() => _selectedCategory = val),
                    ),
                    const SizedBox(height: 20),

                    // Location Dropdown (For UI exactness, I will use textfield or dropdown. User ref shows dropdown)
                    _buildLabel('Lokasi Kejadian', required: true),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedLocation,
                      style: AppTheme.body,
                      decoration: AppTheme.inputDecoration(
                        label: 'Contoh: Laboratorium TI Lt. 3',
                      ),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
                      items: _locations
                          .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                          .toList(),
                      validator: (val) => val == null ? 'Lokasi wajib dipilih' : null,
                      onChanged: (val) => setState(() => _selectedLocation = val),
                    ),
                    const SizedBox(height: 20),

                    // Date Picker
                    _buildLabel('Tanggal Kejadian', required: true),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                          border: Border.all(color: AppTheme.border, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedDate == null
                                    ? 'dd/mm/yyyy'
                                    : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                                style: GoogleFonts.plusJakartaSans(
                                  color: _selectedDate == null
                                      ? AppTheme.textSecondary
                                      : AppTheme.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const Icon(Icons.calendar_today_outlined, color: AppTheme.textSecondary, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    _buildLabel('Deskripsi', required: true),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      style: AppTheme.body,
                      decoration: InputDecoration(
                        hintText: 'Jelaskan ciri-ciri barang secara detail...',
                        hintStyle: AppTheme.caption.copyWith(color: AppTheme.textSecondary),
                        filled: true,
                        fillColor: AppTheme.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusLarge), // Not pill for multiline
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
                      validator: (val) => val == null || val.isEmpty
                          ? 'Deskripsi wajib diisi'
                          : null,
                    ),

                    // Found-specific fields
                    if (_selectedType == 'found') ...[
                      const SizedBox(height: 28),
                      const Divider(color: AppTheme.border),
                      const SizedBox(height: 24),
                      Text('Verifikasi & Penitipan',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary)),
                      const SizedBox(height: 20),

                      _buildLabel('Pertanyaan Verifikasi', required: true),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _verificationController,
                        style: AppTheme.body,
                        decoration: AppTheme.inputDecoration(
                          label: 'Contoh: Merek charger atau warna botol minum',
                        ),
                        validator: (val) {
                          if (_selectedType == 'found' &&
                              (val == null || val.trim().isEmpty)) {
                            return 'Pertanyaan verifikasi wajib dibuat';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Custody toggle
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: SwitchListTile(
                          title: Text('Dititipkan ke petugas?',
                              style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  color: AppTheme.textPrimary)),
                          subtitle: Text('Satpam / Laboran',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, color: AppTheme.textSecondary)),
                          value: _isCustody,
                          activeColor: AppTheme.primary,
                          onChanged: (val) {
                            setState(() {
                              _isCustody = val;
                              if (val && _custodianType == null) {
                                _custodianType = 'security';
                              }
                            });
                          },
                        ),
                      ),

                      if (_isCustody) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              Radio<String>(
                                value: 'security',
                                groupValue: _custodianType,
                                activeColor: AppTheme.primary,
                                onChanged: (val) =>
                                    setState(() => _custodianType = val),
                              ),
                              Text('Satpam',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textPrimary)),
                              const SizedBox(width: 32),
                              Radio<String>(
                                value: 'lab_assistant',
                                groupValue: _custodianType,
                                activeColor: AppTheme.primary,
                                onChanged: (val) =>
                                    setState(() => _custodianType = val),
                              ),
                              Text('Laboran',
                                  style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textPrimary)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        _buildLabel('Nama Petugas Penerima', required: true),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _custodianNameController,
                          style: AppTheme.body,
                          decoration: AppTheme.inputDecoration(
                            label: 'Contoh: Budi Santoso',
                          ),
                          validator: (val) {
                            if (_selectedType == 'found' &&
                                _isCustody &&
                                (val == null || val.trim().isEmpty)) {
                              return 'Nama petugas wajib diisi';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],

                    const SizedBox(height: 40),

                    // Submit
                    ElevatedButton(
                      onPressed: _submitReport,
                      style: AppTheme.primaryButton,
                      child: const Text('Simpan Laporan'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _typeToggle(String label, String type, Color activeColor) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
            ),
          ),
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
