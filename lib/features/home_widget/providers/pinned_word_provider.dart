import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/app_database.dart';
import '../../../core/language/study_language_provider.dart';
import '../../vocabulary/providers/vocabulary_provider.dart';
import 'widget_invite_provider.dart';

/// Palavra fixa no widget, por idioma de estudo ("de" → id da palavra).
/// Enquanto houver uma, o widget mostra sempre ela, em vez da palavra do
/// dia. A notificação não muda.
final pinnedWordIdsProvider =
    NotifierProvider<PinnedWordController, Map<String, int>>(
  PinnedWordController.new,
);

class PinnedWordController extends Notifier<Map<String, int>> {
  static const _prefix = 'widget.pinned.';

  @override
  Map<String, int> build() {
    _load();
    return const {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = {
      for (final key in prefs.getKeys())
        if (key.startsWith(_prefix) && prefs.getInt(key) != null)
          key.substring(_prefix.length): prefs.getInt(key)!,
    };
  }

  /// Id salvo para o idioma [language], direto das preferências (usado ao
  /// atualizar o widget, que pode rodar antes de [build] terminar).
  static Future<int?> savedFor(String language) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_prefix$language');
  }

  /// Fixa [wordId] no idioma de estudo ativo; `null` volta à palavra do dia.
  Future<void> set(int? wordId) async {
    final language = ref.read(studyLanguageProvider);
    final prefs = await SharedPreferences.getInstance();
    final next = {...state};
    if (wordId == null) {
      next.remove(language);
      await prefs.remove('$_prefix$language');
    } else {
      next[language] = wordId;
      await prefs.setInt('$_prefix$language', wordId);
    }
    state = next;
  }
}

/// Palavra fixa do idioma ativo, se ela ainda existir (uma palavra
/// excluída deixa de valer e o widget volta à palavra do dia).
final pinnedWordProvider = Provider<WordEntry?>((ref) {
  final language = ref.watch(studyLanguageProvider);
  final id = ref.watch(pinnedWordIdsProvider)[language];
  if (id == null) return null;
  final words = ref.watch(wordListProvider).valueOrNull ?? const <WordEntry>[];
  for (final w in words) {
    if (w.id == id) return w;
  }
  return null;
});

/// Fixa (ou solta, com `null`) a palavra e atualiza o widget.
Future<void> setPinnedWord(WidgetRef ref, int? wordId) async {
  await ref.read(pinnedWordIdsProvider.notifier).set(wordId);
  await refreshDailyWordWidget(ref);
}
