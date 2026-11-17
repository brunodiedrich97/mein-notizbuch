import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/grammar_colors.dart';
import '../../../vocabulary/models/grammar_type.dart';

/// Quantas palavras de cada classe, na ordem do enum (só as que existem).
List<MapEntry<GrammarCategory, int>> countByCategory(List<WordEntry> words) {
  final counts = <GrammarCategory, int>{};
  for (final w in words) {
    counts[w.category] = (counts[w.category] ?? 0) + 1;
  }
  return [
    for (final c in GrammarCategory.values)
      if (counts[c] != null) MapEntry(c, counts[c]!),
  ];
}

/// Rótulo curto da classe na legenda: artigo para substantivos.
String _legendLabel(GrammarCategory c) => c.article ?? c.label;

/// Barra com a proporção de cada classe gramatical, nas cores das classes.
class CategoryBar extends StatelessWidget {
  const CategoryBar({super.key, required this.words, this.height = 4});

  final List<WordEntry> words;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final counts = countByCategory(words);
    if (counts.isEmpty) return SizedBox(height: height);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Row(
          // Sem "stretch", os ColoredBox (sem filho) ficam com altura zero.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < counts.length; i++) ...[
              if (i > 0) const SizedBox(width: 1.5),
              Expanded(
                flex: counts[i].value,
                child: ColoredBox(
                  color: GrammarColors.of(counts[i].key, isDark: isDark),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Legenda da [CategoryBar]: "● der  ● die  ● verbo".
class CategoryLegend extends StatelessWidget {
  const CategoryLegend({super.key, required this.words});

  final List<WordEntry> words;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final e in countByCategory(words))
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: GrammarColors.of(e.key, isDark: isDark),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _legendLabel(e.key),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: GrammarColors.of(e.key, isDark: isDark),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
