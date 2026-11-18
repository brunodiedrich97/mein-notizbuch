import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/language/study_language.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/grammar_colors.dart';
import '../../../core/widgets/screen_header.dart';
import '../../vocabulary/models/grammar_type.dart';
import '../../vocabulary/providers/vocabulary_provider.dart';
import '../providers/word_class_provider.dart';
import 'word_appearance.dart';
import 'word_class_form_screen.dart';

/// Classes gramaticais: as criadas pelo usuário (editáveis) e as do método
/// (cores fixas).
class WordClassesScreen extends ConsumerWidget {
  const WordClassesScreen({super.key});

  static String _builtInName(GrammarCategory c) => switch (c) {
        GrammarCategory.noun => 'Substantivo',
        GrammarCategory.masculineNoun => 'Substantivo masculino (der)',
        GrammarCategory.feminineNoun => 'Substantivo feminino (die)',
        GrammarCategory.neuterNoun => 'Substantivo neutro (das)',
        GrammarCategory.verb => 'Verbo',
        GrammarCategory.adjective => 'Adjetivo',
        GrammarCategory.adverb => 'Advérbio',
        GrammarCategory.preposition => 'Preposição',
        GrammarCategory.other => 'Outros',
      };

  void _openForm(BuildContext context, {WordClass? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute<int>(
        builder: (_) => WordClassFormScreen(existing: existing),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final classes = ref.watch(wordClassListProvider).valueOrNull ?? const [];
    final words = ref.watch(wordListProvider).valueOrNull ?? const [];
    int countOf(int id) => words.where((w) => w.customClassId == id).length;

    return Scaffold(
      backgroundColor: p.page,
      appBar: const ScreenHeader(
        eyebrow: 'AJUSTES',
        title: 'Classes gramaticais',
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: [
              _Title(
                'MINHAS CLASSES',
                trailing: classes.length == 1
                    ? '1 classe'
                    : '${classes.length} classes',
              ),
              const SizedBox(height: 12),
              _Group(
                children: [
                  for (final c in classes)
                    _ClassRow(
                      color: customClassColor(Color(c.color), isDark: isDark),
                      name: c.name,
                      meta: countOf(c.id) == 1
                          ? '1 palavra'
                          : '${countOf(c.id)} palavras',
                      onTap: () => _openForm(context, existing: c),
                    ),
                  _AddRow(onTap: () => _openForm(context)),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Classes novas funcionam como "outros": tradução, pronúncia '
                  'e exemplo, sem campos especiais.',
                  style: AppText.meta(p),
                ),
              ),
              const SizedBox(height: 24),
              const _Title('DO MÉTODO', trailing: 'cores fixas'),
              const SizedBox(height: 12),
              _Group(
                children: [
                  for (final c in StudyLanguages.active.categories)
                    _ClassRow(
                      color: GrammarColors.of(c, isDark: isDark),
                      name: _builtInName(c),
                      locked: true,
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

class _Title extends StatelessWidget {
  const _Title(this.text, {required this.trailing});

  final String text;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Row(
      children: [
        Expanded(child: Text(text, style: AppText.section(p))),
        Text(trailing, style: AppText.meta(p).copyWith(color: p.text400)),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

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
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 50, color: p.divider),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _ClassRow extends StatelessWidget {
  const _ClassRow({
    required this.color,
    required this.name,
    this.meta,
    this.locked = false,
    this.onTap,
  });

  final Color color;
  final String name;
  final String? meta;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(7),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: AppText.item(p).copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          if (meta != null) ...[
            const SizedBox(width: 8),
            Text(meta!, style: AppTheme.mono(fontSize: 11, color: p.text400)),
          ],
          if (locked)
            Icon(Icons.lock_outline_rounded, size: 16, color: p.text400)
          else if (onTap != null) ...[
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

class _AddRow extends StatelessWidget {
  const _AddRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: Icon(Icons.add_rounded, size: 20, color: p.text700),
              ),
              const SizedBox(width: 12),
              Text(
                'Nova classe',
                style: AppText.item(p).copyWith(
                  fontWeight: FontWeight.w600,
                  color: p.text700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
