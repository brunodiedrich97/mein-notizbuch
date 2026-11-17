import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../review/presentation/review_session_screen.dart';
import '../../vocabulary/presentation/screens/add_word_screen.dart';
import '../../vocabulary/presentation/screens/flashcards_screen.dart';
import '../../vocabulary/presentation/screens/word_detail_screen.dart';
import '../../vocabulary/presentation/screens/word_index_screen.dart';
import '../../study/providers/study_provider.dart';
import '../../vocabulary/providers/vocabulary_provider.dart';
import 'deck_screen.dart';

// Atalhos de navegação. As fichas e a revisão leem o deck em
// `deckScopeProvider`, que é definido aqui, antes de abrir a tela.

Future<void> _push(BuildContext context, Widget screen) {
  return Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => screen));
}

/// Sessão de estudo de um deck (ou de todos, com `deckId` nulo).
/// Ordem e tamanho da sessão são mantidos; o filtro de classe volta a
/// "Todos".
Future<void> openFlashcards(
  BuildContext context,
  WidgetRef ref, {
  int? deckId,
}) {
  ref.read(deckScopeProvider.notifier).state = deckId;
  final settings = ref.read(studySettingsProvider);
  ref.read(studySettingsProvider.notifier).state =
      settings.copyWith(filter: WordFilter.all);
  return _push(context, const FlashcardsScreen());
}

/// Revisão de um deck (ou de todos, com `deckId` nulo).
Future<void> openReview(BuildContext context, WidgetRef ref, {int? deckId}) {
  ref.read(deckScopeProvider.notifier).state = deckId;
  return _push(context, const ReviewSessionScreen());
}

Future<void> openDeck(BuildContext context, int deckId) =>
    _push(context, DeckScreen(deckId: deckId));

/// Registrar Palavra, já com o deck escolhido (se houver).
Future<void> openAddWord(BuildContext context, {int? deckId}) =>
    _push(context, AddWordScreen(initialDeckId: deckId));

/// Índice de palavras de um deck (ou de todas, com `deckId` nulo).
Future<void> openWordIndex(BuildContext context, {int? deckId}) =>
    _push(context, WordIndexScreen(deckId: deckId));

/// Uma ficha sozinha.
Future<void> openWordDetail(BuildContext context, int wordId) =>
    _push(context, WordDetailScreen(wordId: wordId));
