import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/screen_header.dart';
import '../../home/presentation/home_screen.dart' show HomeScreen;
import '../../vocabulary/presentation/widgets/word_list_card.dart';
import '../../vocabulary/providers/vocabulary_provider.dart';
import '../providers/deck_provider.dart';
import 'deck_icon_data.dart';
import 'deck_navigation.dart';
import 'widgets/category_bar.dart';
import 'widgets/deck_card.dart';

/// Tela de um deck: nome em português e alemão, barra de classes, botões
/// de estudo e a lista de palavras.
class DeckScreen extends ConsumerWidget {
  const DeckScreen({super.key, required this.deckId});

  final int deckId;

  /// Quantas palavras aparecem antes de "Ver todas".
  static const int previewCount = 8;

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    DeckSummary summary,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteDeckDialog(summary: summary),
    );
    if (confirmed != true || !context.mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(databaseProvider).deleteDeck(summary.deck.id);
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text('Deck "${summary.deck.namePt}" excluído.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppPalette.of(context);
    final summary = ref.watch(deckByIdProvider(deckId));

    if (summary == null) {
      return const Scaffold(
        appBar: ScreenHeader(title: '', eyebrow: 'DECK'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final deck = summary.deck;
    // Mais recentes primeiro, como na tela inicial.
    final words = summary.words.reversed.toList();
    final count = words.length;
    final canReview = count >= HomeScreen.minWordsForReview;
    return Scaffold(
      appBar: ScreenHeader(
        eyebrow: 'DECK',
        title: deck.namePt,
        trailing: summary.isGeneral
            ? null
            : _DeckMenu(onDelete: () => _confirmDelete(context, ref, summary)),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            children: [
              Row(
                children: [
                  DeckIconBox(icon: deck.icon.data, size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deck.namePt,
                          style: AppTheme.serif(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            height: 1.05,
                            color: p.text900,
                          ),
                        ),
                        if (deck.nameDe != null &&
                            deck.nameDe!.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              deck.nameDe!,
                              style: AppTheme.serif(
                                fontSize: 18,
                                fontStyle: FontStyle.italic,
                                color: p.text500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                count == 1 ? '1 ficha' : '$count fichas',
                style: AppText.meta(p),
              ),
              if (count > 0) ...[
                const SizedBox(height: 8),
                CategoryBar(words: summary.words, height: 8),
                const SizedBox(height: 8),
                CategoryLegend(words: summary.words),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Estudar fichas',
                      onPressed: count == 0
                          ? null
                          : () => openFlashcards(context, ref, deckId: deckId),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SoftButton(
                      label: 'Revisar deck',
                      onPressed: canReview
                          ? () => openReview(context, ref, deckId: deckId)
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Text('PALAVRAS', style: AppText.section(p))),
                  _LinkButton(
                    label: '+ Adicionar',
                    onTap: () => openAddWord(context, deckId: deckId),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (words.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: p.cardBorder),
                  ),
                  child: Text(
                    'Nenhuma palavra neste deck ainda. Toque em '
                    '"+ Adicionar" para cadastrar a primeira.',
                    textAlign: TextAlign.center,
                    style: AppText.body(p),
                  ),
                )
              else ...[
                WordListCard(
                  words: words.take(previewCount).toList(),
                  onTap: (w) => openWordDetail(context, w.id),
                ),
                if (count > previewCount) ...[
                  const SizedBox(height: 12),
                  SoftButton(
                    label: 'Ver todas as $count palavras',
                    onPressed: () => openWordIndex(context, deckId: deckId),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Link de texto pequeno, à direita de um título de seção.
class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text(
          label,
          style: AppText.meta(p).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

/// Botão "⋮" do cabeçalho do deck.
class _DeckMenu extends StatelessWidget {
  const _DeckMenu({required this.onDelete});

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return PopupMenuButton<VoidCallback>(
      tooltip: 'Mais opções',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      color: p.card,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: p.cardBorder),
      ),
      onSelected: (action) => action(),
      itemBuilder: (_) => [
        PopupMenuItem<VoidCallback>(
          value: onDelete,
          height: 44,
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded, size: 18, color: p.text500),
              const SizedBox(width: 12),
              Text(
                'Excluir deck',
                style: TextStyle(
                  fontFamily: AppTheme.sansFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: p.text700,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.outline),
        ),
        child: Icon(Icons.more_vert, size: 20, color: p.text700),
      ),
    );
  }
}

/// Confirmação de exclusão do deck, no estilo do diálogo de excluir ficha.
class _DeleteDeckDialog extends StatelessWidget {
  const _DeleteDeckDialog({required this.summary});

  final DeckSummary summary;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final danger = Theme.of(context).colorScheme.error;
    final count = summary.words.length;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    const label = TextStyle(
      fontFamily: AppTheme.sansFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
    const buttonSize = Size.fromHeight(44);

    final message = switch (count) {
      0 => 'O deck está vazio. Essa ação não pode ser desfeita.',
      1 => 'A palavra deste deck vai para o deck "Geral". '
          'Essa ação não pode ser desfeita.',
      _ => 'As $count palavras deste deck vão para o deck "Geral". '
          'Essa ação não pode ser desfeita.',
    };

    return Dialog(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: p.cardBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: danger.withValues(alpha: isDark ? 0.18 : 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: danger,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'EXCLUIR DECK',
                    style: TextStyle(
                      fontSize: 12,
                      height: 16 / 12,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w700,
                      color: danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                summary.deck.namePt,
                style: AppTheme.serif(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  color: p.text900,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                message,
                style: TextStyle(fontSize: 14, height: 1.45, color: p.text600),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        minimumSize: buttonSize,
                        backgroundColor: p.softButton,
                        foregroundColor: p.text700,
                        textStyle: label,
                        shape: shape,
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        minimumSize: buttonSize,
                        backgroundColor: p.ink,
                        foregroundColor: p.onInk,
                        textStyle: label,
                        shape: shape,
                        elevation: 1,
                        shadowColor: Colors.black26,
                      ),
                      child: const Text('Excluir'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
