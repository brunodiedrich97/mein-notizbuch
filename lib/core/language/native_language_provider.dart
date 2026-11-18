import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'native_language.dart';

/// Código do idioma nativo ativo ("pt", "en", "es"). As fichas já
/// cadastradas não mudam ao trocar: só os rótulos, os exemplos dos campos e
/// as fichas iniciais criadas dali em diante.
final nativeLanguageProvider =
    NotifierProvider<NativeLanguageController, String>(
  NativeLanguageController.new,
);

class NativeLanguageController extends Notifier<String> {
  static const _key = 'native.language';

  @override
  String build() => NativeLanguages.active.code;

  /// Lê o idioma salvo. Chamado no início do app, antes de abrir o banco
  /// (as fichas iniciais usam o idioma nativo).
  static Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) NativeLanguages.setActive(code);
  }

  Future<void> select(String code) async {
    if (code == state) return;
    NativeLanguages.setActive(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
    state = code;
  }
}
