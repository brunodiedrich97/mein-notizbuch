import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/grammar_colors.dart';

/// Lista de palavras num cartão: alemão em serifa, na cor da classe, e a
/// tradução à direita.
class WordListCard extends StatelessWidget {
  const WordListCard({super.key, required this.words});

  final List<WordEntry> words;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.cardBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < words.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                border: i == words.length - 1
                    ? null
                    : Border(bottom: BorderSide(color: p.divider)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      words[i].germanWord,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.serif(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: GrammarColors.titleOf(
                          words[i].category,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      words[i].portugueseTranslation,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 13, color: p.text500),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
