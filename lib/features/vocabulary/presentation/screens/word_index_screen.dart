import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../decks/presentation/deck_navigation.dart';
import '../../../decks/providers/deck_provider.dart';
import '../../../study/models/study_settings.dart';
import '../../../study/presentation/widgets/study_filter_sheet.dart';
import '../../models/grammar_type.dart';
import '../../providers/vocabulary_provider.dart';
import '../../../word_classes/presentation/word_appearance.dart';
import '../widgets/word_list_card.dart';

/// Ordenações do índice.
enum IndexSort {
  az('A–Z'),
  recent('Recentes'),
  mistakes('Mais erradas'),
  article('der · die · das');

  const IndexSort(this.label);
  final String label;
}

/// Índice de palavras de um deck (ou de todos): busca, ordenação, filtro
/// de classe e acesso à ficha de cada palavra.
class WordIndexScreen extends ConsumerStatefulWidget {
  const WordIndexScreen({super.key, this.deckId});

  /// `null` = todas as palavras.
  final int? deckId;

  @override
  ConsumerState<WordIndexScreen> createState() => _WordIndexScreenState();
}

class _WordIndexScreenState extends ConsumerState<WordIndexScreen> {
  final _search = TextEditingController();
  IndexSort _sort = IndexSort.az;
  /// Só o filtro de classe é usado aqui (ordem e tamanho são da sessão).
  StudySettings _filter = const StudySettings();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Minúsculas e sem trema/ß, para buscar e ordenar ("Ärzte" ~ "arzte").
  static String _fold(String s) => s
      .toLowerCase()
      .replaceAll('ä', 'a')
      .replaceAll('ö', 'o')
      .replaceAll('ü', 'u')
      .replaceAll('ß', 'ss')
      .replaceAll(RegExp('[áàâã]'), 'a')
      .replaceAll(RegExp('[éê]'), 'e')
      .replaceAll('í', 'i')
      .replaceAll(RegExp('[óôõ]'), 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ç', 'c');

  /// Chave de ordenação alfabética: a palavra sem o artigo.
  static String _sortKey(WordEntry w) => _fold(stripArticle(w.germanWord));

  int _compareAz(WordEntry a, WordEntry b) => _sortKey(a).compareTo(_sortKey(b));

  /// Grupos (título, palavras) conforme a ordenação.
  List<(String?, List<WordEntry>)> _group(List<WordEntry> words) {
    switch (_sort) {
      case IndexSort.az:
        final sorted = [...words]..sort(_compareAz);
        final groups = <String, List<WordEntry>>{};
        for (final w in sorted) {
          final key = _sortKey(w);
          final letter = key.isEmpty ? '#' : key[0].toUpperCase();
          groups.putIfAbsent(letter, () => []).add(w);
        }
        return [for (final e in groups.entries) (e.key, e.value)];
      case IndexSort.recent:
        final sorted = [...words]..sort((a, b) {
            final byDate = b.createdAt.compareTo(a.createdAt);
            return byDate != 0 ? byDate : b.id.compareTo(a.id);
          });
        return [(null, sorted)];
      case IndexSort.mistakes:
        final sorted = [...words]..sort((a, b) {
            final byWrong = b.wrongCount.compareTo(a.wrongCount);
            if (byWrong != 0) return byWrong;
            final byRight = a.correctCount.compareTo(b.correctCount);
            return byRight != 0 ? byRight : _compareAz(a, b);
          });
        return [(null, sorted)];
      case IndexSort.article:
        String label(WordEntry w) => w.category.article ?? 'Outras classes';
        const order = ['der', 'die', 'das', 'Outras classes'];
        final groups = <String, List<WordEntry>>{};
        for (final w in [...words]..sort(_compareAz)) {
          groups.putIfAbsent(label(w), () => []).add(w);
        }
        return [
          for (final key in order)
            if (groups[key] != null) (key, groups[key]!),
        ];
    }
  }

  Future<void> _openFilter() async {
    final result = await showStudyFilterSheet(
      context,
      _filter,
      sessionOptions: false,
    );
    if (result != null && mounted) setState(() => _filter = result);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final deckId = widget.deckId;
    final deck = deckId == null ? null : ref.watch(deckByIdProvider(deckId));
    final all = ref.watch(wordListProvider).valueOrNull ?? const <WordEntry>[];

    final query = _fold(_search.text.trim());
    final words = all.where((w) {
      if (deckId != null && deckOf(w) != deckId) return false;
      if (!_filter.matches(w)) return false;
      if (query.isEmpty) return true;
      return _fold(w.germanWord).contains(query) ||
          _fold(w.portugueseTranslation).contains(query);
    }).toList();
    final groups = _group(words);

    final countText = switch (words.length) {
      0 => 'Nenhuma palavra',
      1 => '1 palavra',
      _ => '${words.length} palavras',
    };
    final filterText =
        _filter.filter == WordFilter.all && _filter.customClassId == null
            ? ''
            : ' · ${_filter.filterLabel(WordClassScope.of(context))}';

    return Scaffold(
      backgroundColor: p.page,
      appBar: ScreenHeader(
        eyebrow: (deck?.deck.namePt ?? 'Mein Notizbuch').toUpperCase(),
        title: 'Palavras',
        trailing: HeaderIconButton(
          icon: Icons.tune_rounded,
          tooltip: 'Filtrar por classe',
          onPressed: _openFilter,
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverList.list(
                  children: [
                    _SearchField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final s in IndexSort.values) ...[
                            if (s != IndexSort.values.first)
                              const SizedBox(width: 8),
                            _SortPill(
                              label: s.label,
                              selected: s == _sort,
                              onTap: () => setState(() => _sort = s),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('$countText$filterText', style: AppText.meta(p)),
                  ],
                ),
              ),
              if (words.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(32),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      query.isNotEmpty
                          ? 'Nenhuma palavra encontrada para '
                              '"${_search.text.trim()}".'
                          : 'Nenhuma palavra por aqui ainda.',
                      textAlign: TextAlign.center,
                      style: AppText.body(p),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList.builder(
                    itemCount: groups.length,
                    itemBuilder: (context, i) {
                      final (title, groupWords) = groups[i];
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (title != null) ...[
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Text(
                                  title.toUpperCase(),
                                  style: AppText.caption(p),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            WordListCard(
                              words: groupWords,
                              onTap: (w) => openWordDetail(context, w.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 44),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.outline),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 18, color: p.text400),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.search,
              style: AppText.item(p),
              decoration: InputDecoration(
                hintText: 'Buscar em alemão ou português',
                hintStyle: AppText.item(p).copyWith(
                  color: p.text400,
                  fontWeight: FontWeight.w400,
                ),
                isDense: true,
                filled: false,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            InkResponse(
              radius: 16,
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: Icon(Icons.close_rounded, size: 18, color: p.text400),
            ),
        ],
      ),
    );
  }
}

class _SortPill extends StatelessWidget {
  const _SortPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final radius = BorderRadius.circular(10);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? p.ink : p.card,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: selected ? p.ink : p.outline),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              style: AppText.meta(p).copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? p.onInk : p.text700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
