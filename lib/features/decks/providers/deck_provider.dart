import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/language/study_language_provider.dart';
import '../../vocabulary/providers/vocabulary_provider.dart';

/// Decks do idioma de estudo ativo. Atualiza sozinha a cada mudança.
final deckListProvider = StreamProvider<List<Deck>>((ref) {
  final language = ref.watch(studyLanguageProvider);
  return ref.watch(databaseProvider).watchDecks(language);
});

/// Um deck com as palavras dele.
class DeckSummary {
  const DeckSummary(this.deck, this.words);

  final Deck deck;
  final List<WordEntry> words;

  bool get isGeneral => AppDatabase.isGeneralDeck(deck.id);
}

/// Decks com as palavras de cada um. Os decks criados vêm primeiro, na
/// ordem de criação, e o "Geral" fica por último.
final deckSummariesProvider = Provider<AsyncValue<List<DeckSummary>>>((ref) {
  final words = ref.watch(wordListProvider).valueOrNull ?? const <WordEntry>[];
  return ref.watch(deckListProvider).whenData((decks) {
    final byDeck = <int, List<WordEntry>>{};
    for (final w in words) {
      byDeck.putIfAbsent(deckOf(w), () => []).add(w);
    }
    final summaries = [
      for (final d in decks) DeckSummary(d, byDeck[d.id] ?? const []),
    ];
    summaries.sort((a, b) {
      if (a.isGeneral != b.isGeneral) return a.isGeneral ? 1 : -1;
      return a.deck.id.compareTo(b.deck.id);
    });
    return summaries;
  });
});

/// Um deck pelo id, ou `null` se não existir (ou ainda estiver carregando).
final deckByIdProvider = Provider.family<DeckSummary?, int>((ref, id) {
  final summaries = ref.watch(deckSummariesProvider).valueOrNull;
  if (summaries == null) return null;
  for (final s in summaries) {
    if (s.deck.id == id) return s;
  }
  return null;
});
