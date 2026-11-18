import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import 'study_language.dart';

/// Código do idioma de estudo ativo ("de", "en"). As listas de fichas e de
/// decks observam este provider e recarregam quando o idioma muda.
final studyLanguageProvider =
    NotifierProvider<StudyLanguageController, String>(
  StudyLanguageController.new,
);

class StudyLanguageController extends Notifier<String> {
  static const _key = 'study.language';

  @override
  String build() => StudyLanguages.active.code;

  /// Lê o idioma salvo e prepara o deck "Geral" dele. Chamado no início do
  /// app, antes da primeira tela.
  static Future<void> restore(AppDatabase db) async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) StudyLanguages.setActive(code);
    await db.ensureGeneralDeck(StudyLanguages.active.code);
  }

  /// Idioma escolhido na primeira abertura: cria o banco, o deck "Geral" e
  /// as fichas iniciais desse idioma.
  Future<void> start(AppDatabase db, String code) async {
    StudyLanguages.setActive(code);
    await db.ensureGeneralDeck(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
    state = code;
  }

  /// Troca o idioma de estudo. Na primeira vez de um idioma, cria o deck
  /// "Geral" dele com algumas fichas iniciais.
  Future<void> select(AppDatabase db, String code) async {
    if (code == state) return;
    StudyLanguages.setActive(code);
    await db.ensureGeneralDeck(code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
    state = code;
  }
}
