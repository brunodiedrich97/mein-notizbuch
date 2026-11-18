import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/language/study_language.dart';
import '../../../core/language/study_language_provider.dart';
import '../../../l10n/app_strings.dart';
import '../models/grammar_type.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// Fichas do idioma de estudo ativo, em ordem de cadastro. Atualiza
/// sozinha a cada mudança.
final wordListProvider = StreamProvider<List<WordEntry>>((ref) {
  final language = ref.watch(studyLanguageProvider);
  return ref.watch(databaseProvider).watchAllWords(language);
});

enum WordFilter {
  all,
  nouns,
  masculine,
  feminine,
  neuter,
  verbs,
  adjectives,
  prepositions,
  others;

  String get _fallbackLabel => switch (this) {
        WordFilter.all => tr.filterAll,
        WordFilter.nouns => tr.filterNouns,
        WordFilter.masculine => tr.filterMasculine,
        WordFilter.feminine => tr.filterFeminine,
        WordFilter.neuter => tr.filterNeuter,
        WordFilter.verbs => tr.filterVerbs,
        WordFilter.adjectives => tr.filterAdjectives,
        WordFilter.prepositions => tr.filterPrepositions,
        WordFilter.others => tr.filterOthers,
      };

  /// Rótulo do chip: o artigo do idioma de estudo para os gêneros ("der",
  /// "die", "das"); sem artigo no idioma, o nome do gênero.
  String get label => switch (this) {
        WordFilter.masculine =>
          GrammarCategory.masculineNoun.article ?? _fallbackLabel,
        WordFilter.feminine =>
          GrammarCategory.feminineNoun.article ?? _fallbackLabel,
        WordFilter.neuter =>
          GrammarCategory.neuterNoun.article ?? _fallbackLabel,
        _ => _fallbackLabel,
      };

  bool matches(GrammarCategory c) => switch (this) {
        WordFilter.all => true,
        WordFilter.nouns => c.isNoun,
        WordFilter.masculine => c == GrammarCategory.masculineNoun,
        WordFilter.feminine => c == GrammarCategory.feminineNoun,
        WordFilter.neuter => c == GrammarCategory.neuterNoun,
        WordFilter.verbs => c == GrammarCategory.verb,
        WordFilter.adjectives => c == GrammarCategory.adjective,
        WordFilter.prepositions => c == GrammarCategory.preposition,
        WordFilter.others =>
          c == GrammarCategory.adverb || c == GrammarCategory.other,
      };
}

/// Filtros de classe do idioma de estudo: os gêneros (der, die, das) quando
/// o idioma tem gênero; senão, "Substantivos".
List<WordFilter> filtersFor(StudyLanguageProfile language) => [
      WordFilter.all,
      if (language.hasGender) ...[
        WordFilter.masculine,
        WordFilter.feminine,
        WordFilter.neuter,
      ] else
        WordFilter.nouns,
      WordFilter.verbs,
      WordFilter.adjectives,
      WordFilter.prepositions,
      WordFilter.others,
    ];

/// Deck aberto nas fichas e na revisão. `null` = todos os decks.
///
/// Defina antes de abrir a tela (veja `openFlashcards` e `openReview` em
/// `deck_navigation.dart`), e não durante o build.
final deckScopeProvider = StateProvider<int?>((ref) => null);

/// Deck de uma palavra, tratando `null` como o "Geral".
int deckOf(WordEntry w) => w.deckId ?? AppDatabase.generalDeckId;
