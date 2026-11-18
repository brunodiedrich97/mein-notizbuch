import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/language/native_language.dart';
import '../../../core/language/study_language.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_strings.dart';
import '../../vocabulary/presentation/screens/word_index_screen.dart'
    show foldForSearch;
import '../../vocabulary/providers/vocabulary_provider.dart';
import '../../word_classes/presentation/word_appearance.dart';

/// Escolha da palavra fixa no widget: "Nenhuma" (palavra do dia) ou uma
/// das palavras do idioma de estudo, com busca. Devolve `(id,)`, com
/// `(null,)` para "Nenhuma".
class PinnedWordSheet extends ConsumerStatefulWidget {
  const PinnedWordSheet({super.key, required this.selected});

  final int? selected;

  @override
  ConsumerState<PinnedWordSheet> createState() => _PinnedWordSheetState();
}

class _PinnedWordSheetState extends ConsumerState<PinnedWordSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final words = ref.watch(wordListProvider).valueOrNull ?? const <WordEntry>[];
    final query = foldForSearch(_search.text.trim());
    final shown = [
      for (final w in words.reversed)
        if (query.isEmpty ||
            foldForSearch(w.germanWord).contains(query) ||
            foldForSearch(w.portugueseTranslation).contains(query))
          w,
    ];

    final options = <Widget>[
      if (query.isEmpty)
        _Option(
          title: Text(tr.none, style: AppText.item(p)),
          subtitle: tr.newWordEachDay,
          selected: widget.selected == null,
          onTap: () => Navigator.of(context).pop((null,)),
        ),
      for (final w in shown)
        _Option(
          title: Text(
            w.germanWord,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.serif(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: appearanceOf(context, w).titleColor,
            ),
          ),
          subtitle: w.portugueseTranslation,
          selected: w.id == widget.selected,
          onTap: () => Navigator.of(context).pop((w.id,)),
        ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(tr.pinnedSheetTitle, style: AppText.section(p)),
        const SizedBox(height: 8),
        Text(tr.pinnedSheetText, style: AppText.body(p)),
        const SizedBox(height: 14),
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.search,
          style: AppText.item(p),
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: Icon(Icons.search_rounded, color: p.text400),
            hintText: tr.searchIn(
              tr.languageName(StudyLanguages.active.code),
              tr.languageName(NativeLanguages.active.code),
            ),
            hintStyle: AppText.item(p).copyWith(
              color: p.text400,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: p.page,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: p.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: p.outline),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.cardBorder),
          ),
          child: Column(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0) Divider(height: 1, color: p.divider),
                options[i],
              ],
              if (shown.isEmpty && query.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    tr.noWordsFoundFor(_search.text.trim()),
                    textAlign: TextAlign.center,
                    style: AppText.meta(p),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final Widget title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Material(
      color: selected ? p.pronBox : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.meta(p),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? p.ink : null,
                  border: selected
                      ? null
                      : Border.all(color: p.text400, width: 1.5),
                ),
                child: selected
                    ? Icon(Icons.check_rounded, size: 15, color: p.onInk)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
