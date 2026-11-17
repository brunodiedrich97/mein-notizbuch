import 'package:flutter/material.dart';

import 'grammar_colors.dart';

/// Cores neutras da interface, medidas no protótipo (paleta cinza do
/// Tailwind), com equivalentes para o modo escuro.
class AppPalette {
  const AppPalette._({
    required this.page,
    required this.card,
    required this.cardBorder,
    required this.footer,
    required this.divider,
    required this.ink,
    required this.onInk,
    required this.text900,
    required this.text800,
    required this.text700,
    required this.text600,
    required this.text500,
    required this.text400,
    required this.dots,
    required this.track,
    required this.progress,
    required this.pronBox,
    required this.softButton,
    required this.outline,
  });

  final Color page; // fundo da tela
  final Color card; // fundo da ficha
  final Color cardBorder;
  final Color footer; // faixa do rodapé
  final Color divider; // linhas sob o cabeçalho e sobre o rodapé
  final Color ink; // botão "Próximo", chip selecionado
  final Color onInk;
  final Color text900; // exemplo, aproximação em português
  final Color text800; // IPA
  final Color text700; // botões claros
  final Color text600; // título, tradução, dica
  final Color text500; // contador, ícone de som
  final Color text400; // "EXEMPLO", separadores " · "
  final Color dots; // divisor pontilhado
  final Color track; // trilho da barra de progresso
  final Color progress; // barra de progresso
  final Color pronBox; // caixa de pronúncia
  final Color softButton; // botão "Anterior"
  final Color outline; // borda do botão de som

  static const light = AppPalette._(
    page: GrammarColors.paperBgLight,
    card: Color(0xFFFFFFFF),
    cardBorder: GrammarColors.paperBorderLight,
    footer: Color(0xFFFFFFFF),
    divider: Color(0xFFF3F4F6),
    ink: Color(0xFF111827),
    onInk: Color(0xFFFFFFFF),
    text900: Color(0xFF111827),
    text800: Color(0xFF1F2937),
    text700: Color(0xFF374151),
    text600: Color(0xFF4B5563),
    text500: Color(0xFF6B7280),
    text400: Color(0xFF9CA3AF),
    dots: Color(0xFFD1D5DB),
    track: Color(0xFFECEDEF),
    progress: Color(0xFF1F2937),
    pronBox: Color(0xFFF8F9FA),
    softButton: Color(0xFFF3F4F6),
    outline: Color(0xFFE5E7EB),
  );

  static const dark = AppPalette._(
    page: GrammarColors.paperBgDark,
    card: GrammarColors.paperCardDark,
    cardBorder: Color(0xFF33312E),
    footer: Color(0xFF1F1E1C),
    divider: Color(0xFF2C2A27),
    ink: Color(0xFFF3F4F6),
    onInk: Color(0xFF111827),
    text900: Color(0xFFF9FAFB),
    text800: Color(0xFFE5E7EB),
    text700: Color(0xFFE5E7EB),
    text600: Color(0xFFC9CDD4),
    text500: Color(0xFF9CA3AF),
    text400: Color(0xFF7C828D),
    dots: Color(0xFF4B4945),
    track: Color(0xFF2F2D2A),
    progress: Color(0xFFE5E7EB),
    pronBox: Color(0xFF2A2926),
    softButton: Color(0xFF2C2A27),
    outline: Color(0xFF3A3835),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

class AppTheme {
  AppTheme._();

  static const String sansFamily = 'PlusJakartaSans';
  /// Newsreader para texto (opsz 20) e para títulos grandes (opsz 40).
  static const String serifFamily = 'Newsreader';
  static const String serifDisplayFamily = 'NewsreaderDisplay';
  static const String monoFamily = 'NotizMono';

  /// Newsreader: palavras e exemplos em alemão. A partir de 30 px usa a
  /// versão "Display", como o tamanho óptico automático do navegador.
  static TextStyle serif({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    FontStyle fontStyle = FontStyle.normal,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: fontSize >= 30 && fontStyle == FontStyle.normal
          ? serifDisplayFamily
          : serifFamily,
      fontFamilyFallback: const ['Georgia', 'Noto Serif', 'serif'],
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontStyle: fontStyle,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Monoespaçada: IPA e contador de fichas.
  static TextStyle mono({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: monoFamily,
      fontFamilyFallback: const ['Menlo', 'monospace'],
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final p = isDark ? AppPalette.dark : AppPalette.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppPalette.light.ink,
      brightness: brightness,
      primary: p.ink,
      onPrimary: p.onInk,
      surface: p.card,
      onSurface: p.text900,
      outlineVariant: p.outline,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: sansFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.page,
      textTheme: ThemeData(brightness: brightness).textTheme.apply(
            fontFamily: sansFamily,
            bodyColor: isDark ? p.text900 : const Color(0xFF2C2C2C),
            displayColor: isDark ? p.text900 : const Color(0xFF2C2C2C),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: p.text900,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: p.outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.ink,
          foregroundColor: p.onInk,
          textStyle: const TextStyle(
            fontFamily: sansFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
