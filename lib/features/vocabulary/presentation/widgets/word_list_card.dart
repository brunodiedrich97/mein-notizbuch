import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/grammar_colors.dart';

/// Lista de palavras num cartão: alemão em serifa, na cor da classe, e a
/// tradução à direita. Com [onTap], cada linha é tocável e ganha um "›".
class WordListCard extends StatelessWidget {
  const WordListCard({super.key, required this.words, this.onTap});

  final List<WordEntry> words;

  /// Toque numa palavra (ex.: abrir a ficha). `null` = lista só de leitura.
  final ValueChanged<WordEntry>? onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.cardBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < words.length; i++)
            WordListRow(
              word: words[i],
              showDivider: i < words.length - 1,
              onTap: onTap == null ? null : () => onTap!(words[i]),
            ),
        ],
      ),
    );
  }
}

/// Uma linha da [WordListCard] (também usada no índice de palavras).
class WordListRow extends StatelessWidget {
  const WordListRow({
    super.key,
    required this.word,
    this.showDivider = false,
    this.onTap,
  });

  final WordEntry word;
  final bool showDivider;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final row = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: p.divider))
            : null,
      ),
      child: Row(
        children: [
          // Duas colunas de largura fixa: a tradução sempre termina na
          // borda direita, curta ou longa.
          Expanded(
            flex: 5,
            child: Text(
              word.germanWord,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.serif(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: GrammarColors.titleOf(word.category, isDark: isDark),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Text(
              word.portugueseTranslation,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 13, height: 18 / 13, color: p.text500),
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            ChevronIcon.right(color: p.text400, size: 12),
          ],
        ],
      ),
    );

    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}
