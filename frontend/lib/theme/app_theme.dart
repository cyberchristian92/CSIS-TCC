import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Identidade visual da CSIS — ver Produçao/design/csis_brand_book.html
class AppTheme {
  // Cores Principais (brand CSIS: navy + ciano, estética dark/cyber)
  static const Color background = Color(0xFF050F1C); // navy-deep
  static const Color surface = Color(0xFF091A2D); // navy
  static const Color surfaceRaised = Color(0xFF112844); // navy-mid (cards elevados, hover)
  static const Color primary = Color(0xFF49C3D1); // ciano
  static const Color primaryHover = Color(0xFF66E0EE); // ciano-bright
  static const Color primaryDim = Color(0xFF2A7E87); // ciano-dim (desabilitado)

  // Cores de Linha e Borda
  static const Color border = Color(0x1FFFFFFF); // branco 12% — borda sutil sobre navy

  // Tipografia Cores
  static const Color textMain = Color(0xFFF1F5F9); // cloud
  static const Color textSecondary = Color(0xFF9CA3AF); // gray-light
  static const Color textDisabled = Color(0xFF6B7280); // gray

  // Cores Semânticas de status (Missão/Projeto)
  static const Color statusPending = Color(0xFF64748B); // PENDENTE — neutro, ainda não iniciado
  static const Color statusInProgress = Color(0xFF49C3D1); // EM_ANDAMENTO — ciano da marca
  static const Color statusInReview = Color(0xFFF59E0B); // EM_REVISAO — âmbar
  static const Color statusApproved = Color(0xFF16A34A); // APROVADA / Concluído — verde
  static const Color statusRejected = Color(0xFFDC2626); // REJEITADA — vermelho
  static const Color statusArchived = Color(0xFF94A3B8); // Arquivado — cinza-azulado

  static const double radius = 10;

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: surface,
        onSurface: textMain,
        error: statusRejected,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(ThemeData.dark().textTheme).copyWith(
        bodyLarge: GoogleFonts.dmSans(color: textMain, fontSize: 16),
        bodyMedium: GoogleFonts.dmSans(color: textMain, fontSize: 14),
        bodySmall: GoogleFonts.dmSans(color: textSecondary, fontSize: 12),
        titleLarge: GoogleFonts.sora(color: textMain, fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.02),
        titleMedium: GoogleFonts.sora(color: textMain, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.02),
        titleSmall: GoogleFonts.sora(color: textMain, fontSize: 16, fontWeight: FontWeight.w600),
        labelLarge: GoogleFonts.dmSans(color: textMain, fontSize: 14, fontWeight: FontWeight.w500),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: background,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textMain,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceRaised,
        hintStyle: GoogleFonts.dmSans(color: textDisabled),
        labelStyle: GoogleFonts.dmSans(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: statusRejected),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        space: 1,
        thickness: 1,
      ),
      iconTheme: const IconThemeData(color: textSecondary),
    );
  }

  /// Compatibilidade com código existente que referenciava `lightTheme`.
  static ThemeData get lightTheme => darkTheme;

  // Estilo utilitário para textos monoespaçados (Hashes, IDs)
  static TextStyle get monoTextStyle => GoogleFonts.jetBrainsMono(
        color: textMain,
        fontSize: 14,
      );

  /// Tag estilo brand book: mono, uppercase, letter-spacing largo — usado em badges de status.
  static TextStyle tagStyle({Color color = primary, double fontSize = 11}) => GoogleFonts.jetBrainsMono(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      );
}
