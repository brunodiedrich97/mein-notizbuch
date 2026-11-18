import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_strings.dart';

/// Idioma da interface: "system" (o do aparelho) ou "pt", "en", "es".
final uiLanguageProvider =
    NotifierProvider<UiLanguageController, String>(UiLanguageController.new);

class UiLanguageController extends Notifier<String> {
  static const _key = 'ui.language';
  static const system = 'system';

  static String _saved = system;

  @override
  String build() => _saved;

  /// Idioma do aparelho, se o app tiver; senão, inglês.
  static String deviceLanguage() {
    final code = PlatformDispatcher.instance.locale.languageCode;
    return AppStrings.all.containsKey(code) ? code : 'en';
  }

  /// Código efetivo ("pt", "en", "es") de uma escolha.
  static String resolve(String choice) =>
      choice == system ? deviceLanguage() : choice;

  /// Locale do MaterialApp (datas e horários dos seletores do sistema).
  static Locale localeOf(String code) => switch (code) {
        'pt' => const Locale('pt', 'BR'),
        'es' => const Locale('es'),
        _ => const Locale('en'),
      };

  /// Lê a escolha salva e ativa os textos. Chamado antes da primeira tela.
  static Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    _saved = prefs.getString(_key) ?? system;
    AppStrings.current = AppStrings.all[resolve(_saved)]!;
  }

  Future<void> select(String choice) async {
    if (choice == state) return;
    _saved = choice;
    AppStrings.current = AppStrings.all[resolve(choice)]!;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, choice);
    state = choice;
  }
}
