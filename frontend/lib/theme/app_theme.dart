import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Cores Principais
  static const Color background = Color(0xFFF6F7F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color primary = Color(0xFF0F6B5C);
  static const Color primaryHover = Color(0xFF0B564A);
  
  // Cores de Linha e Borda
  static const Color border = Color(0xFFE1E4E9);
  
  // Tipografia Cores
  static const Color textMain = Color(0xFF1A1D23);
  static const Color textSecondary = Color(0xFF5C6470);
  static const Color textDisabled = Color(0xFF9AA1AC);

  // Cores Semânticas
  static const Color statusPending = Color(0xFFB76E00);
  static const Color statusApproved = Color(0xFF1E7D4F);
  static const Color statusRejected = Color(0xFFB3261E);
  static const Color statusInProgress = Color(0xFF3457A6);
  static const Color statusArchived = Color(0xFF8A8F98);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        surface: surface,
        onSurface: textMain,
        background: background,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        bodyLarge: GoogleFonts.inter(color: textMain, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: textMain, fontSize: 14),
        bodySmall: GoogleFonts.inter(color: textSecondary, fontSize: 12),
        titleLarge: GoogleFonts.inter(color: textMain, fontSize: 24, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.inter(color: textMain, fontSize: 20, fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.inter(color: textMain, fontSize: 16, fontWeight: FontWeight.w600),
        labelLarge: GoogleFonts.inter(color: textMain, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: GoogleFonts.inter(color: textDisabled),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: statusRejected),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        space: 1,
        thickness: 1,
      ),
    );
  }

  // Estilo utilitário para textos monoespaçados (Hashes, IDs)
  static TextStyle get monoTextStyle => GoogleFonts.ibmPlexMono(
        color: textMain,
        fontSize: 14,
      );
}
