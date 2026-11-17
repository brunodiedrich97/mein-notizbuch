import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../decks/presentation/deck_navigation.dart';
import '../../../writing/presentation/sentence_actions.dart';
import '../../../writing/providers/sentence_provider.dart';
import '../../providers/vocabulary_provider.dart';
import '../widgets/delete_word_dialog.dart';
import '../widgets/flashcard_card.dart';

/// Uma ficha sozinha, aberta a partir do índice ou do resumo da sessão.
class WordDetailScreen extends ConsumerWidget {
  const WordDetailScreen({super.key, required this.wordId});

  final int wordId;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    WordEntry word,
  ) async {
    final confirmed = await DeleteWordDialog.show(context, word);
    if (!confirmed || !context.mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(databaseProvider).deleteWord(word.id);
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text('"${word.germanWord}" foi excluída.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppPalette.of(context);
    final words = ref.watch(wordListProvider).valueOrNull ?? const [];
    final matches = words.where((w) => w.id == wordId);
    final WordEntry? word = matches.isEmpty ? null : matches.first;

    return Scaffold(
      backgroundColor: p.page,
      appBar: ScreenHeader(
        eyebrow: 'FICHA',
        title: word?.germanWord ?? '',
        trailing: word == null
            ? null
            : HeaderIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Excluir ficha',
                onPressed: () => _delete(context, ref, word),
              ),
      ),
      body: word == null
          ? const Center(child: CircularProgressIndicator())
          : FlashcardCard(
              word: word,
              sentences: ref.watch(sentencesOfWordProvider(word.id)),
              onWriteSentence: () => openWriteSentence(context, word.id),
              onSentenceLongPress: (s) =>
                  confirmDeleteSentence(context, ref, s),
            ),
    );
  }
}
