import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../models/grammar_type.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Todas as fichas, em ordem de cadastro. Atualiza sozinha a cada mudança.
final wordListProvider = StreamProvider<List<WordEntry>>((ref) {
  return ref.watch(databaseProvider).watchAllWords();
});

enum WordFilter {
  all('Todos'),
  der('der'),
  die('die'),
  das('das'),
  verbs('Verbos'),
  adjectives('Adjetivos'),
  prepositions('Preposições'),
  others('Outros');

  const WordFilter(this.label);
  final String label;

  bool matches(GrammarCategory c) => switch (this) {
        WordFilter.all => true,
        WordFilter.der => c == GrammarCategory.masculineNoun,
        WordFilter.die => c == GrammarCategory.feminineNoun,
        WordFilter.das => c == GrammarCategory.neuterNoun,
        WordFilter.verbs => c == GrammarCategory.verb,
        WordFilter.adjectives => c == GrammarCategory.adjective,
        WordFilter.prepositions => c == GrammarCategory.preposition,
        WordFilter.others =>
          c == GrammarCategory.adverb || c == GrammarCategory.other,
      };
}

/// Deck aberto nas fichas e na revisão. `null` = todos os decks.
///
/// Defina antes de abrir a tela (veja `openFlashcards` e `openReview` em
/// `deck_navigation.dart`), e não durante o build.
final deckScopeProvider = StateProvider<int?>((ref) => null);

/// Deck de uma palavra, tratando `null` como o "Geral".
int deckOf(WordEntry w) => w.deckId ?? AppDatabase.generalDeckId;
