import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// FindMe Kampus - Centralized Design System
/// Upgraded to a Vibrant, Bright Blue & Indigo Premium Palette with Plus Jakarta Sans
class AppTheme {
  AppTheme._();

  // ─── PRIMARY PALETTE (Lively & Bright) ───
  static const Color background = Color(0xFF1E3A8A); // Vibrant Royal Blue / Navy
  static const Color primary = Color(0xFF3B82F6); // Vibrant Blue
  static const Color accent = Color(0xFF06B6D4); // Bright Cyan
  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [
          Color(0xFF1E3A8A), // Deep Royal Blue
          Color(0xFF3B82F6), // Vibrant Blue
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color danger = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981); // Bright Emerald Green

  // ─── ADDITIONAL COLORS ───
  static const Color textPrimary = Color(0xFF111827); // Dark Slate for main text
  static const Color inputBackground = Color(0xFFF9FAFB);

  // ─── STATUS COLORS ───
  static const Color statusLost = danger;
  static const Color statusFound = success;
  static const Color statusSecurity = Color(0xFF3B82F6); // Blue
  static const Color statusLabAssistant = Color(0xFFF59E0B); // Amber
  static const Color statusReturned = success;
  static const Color warning = Color(0xFFF59E0B);

  // ─── BORDER RADIUS ───
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusPill = 30.0;

  // ─── SHADOWS ───
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get primaryShadow => [
        BoxShadow(
          color: primary.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  // ─── TYPOGRAPHY (Plus Jakarta Sans) ───
  static TextStyle get heading1 => GoogleFonts.plusJakartaSans(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle get heading2 => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.3,
        height: 1.3,
      );

  static TextStyle get heading3 => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.2,
        height: 1.4,
      );

  static TextStyle get body => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        letterSpacing: 0.1,
        height: 1.5,
      );

  static TextStyle get caption => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        letterSpacing: 0.2,
        height: 1.4,
      );

  // ─── INPUT DECORATION ───
  static InputDecoration inputDecoration({
    required String label,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: caption.copyWith(color: textSecondary),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: textSecondary, size: 20) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusPill),
        borderSide: const BorderSide(color: border, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusPill),
        borderSide: const BorderSide(color: border, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusPill),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusPill),
        borderSide: const BorderSide(color: danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusPill),
        borderSide: const BorderSide(color: danger, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  // ─── BUTTON STYLES ───
  static ButtonStyle get primaryButton => ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
        elevation: 4,
        shadowColor: primary.withValues(alpha: 0.4),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      );

  static ButtonStyle get outlineButton => OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        backgroundColor: surface,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        side: const BorderSide(color: border, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusPill),
        ),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      );

  // ─── STATUS HELPERS ───
  static Color getStatusColor(String status) {
    switch (status) {
      case 'lost':
        return danger;
      case 'found':
        return success;
      case 'security':
        return statusSecurity;
      case 'lab_assistant':
        return statusLabAssistant;
      case 'returned':
        return success;
      default:
        return textSecondary;
    }
  }

  static Widget typeBadge(String type) {
    final isLost = type == 'lost';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isLost ? danger : success,
        borderRadius: BorderRadius.circular(radiusSmall),
      ),
      child: Text(
        isLost ? 'HILANG' : 'DITEMUKAN',
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static Widget statusBadge(String status, {double fontSize = 10}) {
    Color color;
    String text;
    switch (status) {
      case 'lost':
        color = danger;
        text = 'HILANG';
        break;
      case 'found':
        color = success;
        text = 'DITEMUKAN';
        break;
      case 'returned':
        color = success;
        text = 'DISERAHKAN';
        break;
      case 'approved':
        color = success;
        text = 'DISETUJUI';
        break;
      case 'rejected':
        color = danger;
        text = 'DITOLAK';
        break;
      case 'pending':
        color = warning;
        text = 'MENUNGGU';
        break;
      default:
        color = textSecondary;
        text = status.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ─── THEME DATA ───
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: surface,
      ),
      scaffoldBackgroundColor: surface,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: heading2.copyWith(color: surface),
        iconTheme: const IconThemeData(color: surface),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButton),
      outlinedButtonTheme: OutlinedButtonThemeData(style: outlineButton),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: caption.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: caption,
        elevation: 16,
      ),
      tabBarTheme: TabBarTheme(
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: body.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: body,
      ),
    );
  }
}
