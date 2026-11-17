import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../word_classes/presentation/word_appearance.dart';

/// Uma classe presente nas palavras: rótulo, cor e quantidade.
class ClassCount {
  const ClassCount(this.label, this.color, this.count);
  final String label;
  final Color color;
  final int count;
}

/// Quantas palavras de cada classe, com as do método primeiro (na ordem do
/// enum) e as criadas pelo usuário depois.
List<ClassCount> countByClass(BuildContext context, List<WordEntry> words) {
  final counts = <String, int>{};
  final first = <String, ClassCount>{};
  final order = <String, int>{};
  for (final w in words) {
    final look = appearanceOf(context, w);
    final custom = look.customClass;
    final key = custom == null ? 'c${w.category.index}' : 'u${custom.id}';
    counts[key] = (counts[key] ?? 0) + 1;
    // Rótulo curto: artigo para substantivos ("der"), senão o nome.
    final label = custom == null
        ? (w.category.article ?? w.category.label)
        : look.label;
    first[key] = ClassCount(label, look.color, 0);
    order[key] = custom == null ? w.category.index : 1000 + custom.id;
  }
  final keys = counts.keys.toList()
    ..sort((a, b) => order[a]!.compareTo(order[b]!));
  return [
    for (final k in keys) ClassCount(first[k]!.label, first[k]!.color, counts[k]!),
  ];
}

/// Barra com a proporção de cada classe gramatical, nas cores das classes.
class CategoryBar extends StatelessWidget {
  const CategoryBar({super.key, required this.words, this.height = 4});

  final List<WordEntry> words;
  final double height;

  @override
  Widget build(BuildContext context) {
    final counts = countByClass(context, words);
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
                flex: counts[i].count,
                child: ColoredBox(color: counts[i].color),
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
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        for (final e in countByClass(context, words))
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: e.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                e.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: e.color,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
