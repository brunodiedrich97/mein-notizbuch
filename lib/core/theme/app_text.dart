import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Escala de texto da interface (sans), para as telas falarem a mesma
/// língua. As palavras em alemão continuam em [AppTheme.serif].
///
/// Espaçamentos seguem a grade de 4: 4 · 8 · 12 · 16 · 24 · 32.
class AppText {
  AppText._();

  /// Título de seção em caixa alta: "MEUS DECKS", "PALAVRAS".
  static TextStyle section(AppPalette p) => TextStyle(
        fontFamily: AppTheme.sansFamily,
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: p.text600,
      );

  /// Rótulo pequeno em caixa alta dentro de cartões: "EXEMPLO".
  static TextStyle caption(AppPalette p) => TextStyle(
        fontFamily: AppTheme.sansFamily,
        fontSize: 11,
        height: 14 / 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: p.text400,
      );

  /// Texto auxiliar: contagens, "Opcional", "Ver todas".
  static TextStyle meta(AppPalette p) => TextStyle(
        fontFamily: AppTheme.sansFamily,
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        color: p.text500,
      );

  /// Texto corrido.
  static TextStyle body(AppPalette p) => TextStyle(
        fontFamily: AppTheme.sansFamily,
        fontSize: 14,
        height: 20 / 14,
        color: p.text600,
      );

  /// Item de lista ou opção.
  static TextStyle item(AppPalette p) => TextStyle(
        fontFamily: AppTheme.sansFamily,
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w500,
        color: p.text900,
      );

  /// Rótulo de botão.
  static const TextStyle button = TextStyle(
    fontFamily: AppTheme.sansFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
  );

  /// Título grande em serifa: "Gut gemacht!".
  static TextStyle display(AppPalette p, {double fontSize = 36}) =>
      AppTheme.serif(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        height: 1.1,
        color: p.text900,
      );
}
