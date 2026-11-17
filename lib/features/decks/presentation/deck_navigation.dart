import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../review/presentation/review_session_screen.dart';
import '../../vocabulary/presentation/screens/add_word_screen.dart';
import '../../vocabulary/presentation/screens/flashcards_screen.dart';
import '../../vocabulary/providers/vocabulary_provider.dart';
import 'deck_screen.dart';

// Atalhos de navegação. As fichas e a revisão leem o deck em
// `deckScopeProvider`, que é definido aqui, antes de abrir a tela.

Future<void> _push(BuildContext context, Widget screen) {
  return Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => screen));
}

/// Fichas de um deck (ou de todos, com `deckId` nulo), sem filtro de classe.
Future<void> openFlashcards(
  BuildContext context,
  WidgetRef ref, {
  int? deckId,
}) {
  ref.read(deckScopeProvider.notifier).state = deckId;
  ref.read(wordFilterProvider.notifier).state = WordFilter.all;
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
