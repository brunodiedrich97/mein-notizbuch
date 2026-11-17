import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/grammar_colors.dart';
import '../../../../core/widgets/speak_button.dart';
import '../../../review/presentation/review_session_screen.dart';
import '../../../splash/presentation/splash_screen.dart' show kLogoMark;
import '../../../decks/providers/deck_provider.dart';
import '../../providers/vocabulary_provider.dart';
import '../widgets/delete_word_dialog.dart';
import '../widgets/flashcard_card.dart';
import '../widgets/pronunciation_box.dart';
import '../widgets/tablet_notebook_view.dart';
import 'add_word_screen.dart';

class FlashcardsScreen extends ConsumerStatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen> {
  /// A partir desta largura, o caderno abre em duas páginas.
  static const double _tabletBreakpoint = 840;
  static const Duration _pageDuration = Duration(milliseconds: 300);

  PageController _pageController = PageController();
  int _currentIndex = 0;
  bool? _lastLayoutWasTablet;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Ao voltar do layout de tablet para o de celular, o PageView é criado de
  /// novo. Recriamos o controller para ele abrir na ficha atual, e não na 0.
  void _syncControllerWithLayout(bool isTablet, int index) {
    if (_lastLayoutWasTablet == isTablet) return;
    _lastLayoutWasTablet = isTablet;
    if (!isTablet && !_pageController.hasClients) {
      _pageController.dispose();
      _pageController = PageController(initialPage: index);
    }
  }

  /// Avança ou recua uma ficha (duas no tablet). Como no protótipo, depois
  /// da última volta para a primeira, e vice-versa.
  void _step(int direction, int shown, int total, bool isTablet) {
    if (total == 0) return;
    final step = isTablet ? 2 : 1;
    final lastStart = isTablet ? (total - 1) - (total - 1) % 2 : total - 1;

    var target = shown + direction * step;
    final wrapped = target > lastStart || target < 0;
    if (target > lastStart) target = 0;
    if (target < 0) target = lastStart;

    if (!isTablet && _pageController.hasClients) {
      if (wrapped) {
        _pageController.jumpToPage(target);
      } else {
        _pageController.animateToPage(
          target,
          duration: _pageDuration,
          curve: Curves.easeOut,
        );
      }
    } else {
      setState(() => _currentIndex = target);
    }
  }

  Future<void> _openAddWord() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            AddWordScreen(initialDeckId: ref.read(deckScopeProvider)),
      ),
    );
  }

  Future<void> _openReview() {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ReviewSessionScreen()),
    );
  }

  Future<void> _confirmDelete(WordEntry word) async {
    final confirmed = await DeleteWordDialog.show(context, word);
    if (!confirmed || !mounted) return;

    await ref.read(databaseProvider).deleteWord(word.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${word.germanWord}" foi excluída.')),
    );
  }

  String _counterText(int shown, int total, bool isTablet) {
    if (total == 0) return '0 de 0';
    if (isTablet && shown + 1 < total) {
      return '${shown + 1}–${shown + 2} de $total';
    }
    return '${shown + 1} de $total';
  }

  @override
  Widget build(BuildContext context) {
    // Ao trocar o filtro, volta para a primeira ficha da nova lista.
    ref.listen<WordFilter>(wordFilterProvider, (previous, next) {
      if (previous == next) return;
      setState(() => _currentIndex = 0);
      if (_pageController.hasClients) _pageController.jumpToPage(0);
    });

    final wordsAsync = ref.watch(filteredWordsProvider);
    final filter = ref.watch(wordFilterProvider);
    final notebookIsEmpty =
        ref.watch(wordListProvider).valueOrNull?.isEmpty ?? false;

    final palette = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Com um deck aberto, o título mostra o nome dele.
    final scopeId = ref.watch(deckScopeProvider);
    final scopedDeck =
        scopeId == null ? null : ref.watch(deckByIdProvider(scopeId));
    final title = scopedDeck?.deck.namePt.toUpperCase() ?? 'MEIN NOTIZBUCH';
    final isTablet = MediaQuery.sizeOf(context).width >= _tabletBreakpoint;
    // max-w-md do protótipo no celular; mais largo no caderno aberto.
    final barMaxWidth = isTablet ? 960.0 : 448.0;

    final words = wordsAsync.valueOrNull ?? const <WordEntry>[];
    final total = words.length;
    // O índice é limitado ao tamanho atual (a lista pode encolher após
    // excluir uma ficha ou trocar de filtro).
    final index = total == 0 ? 0 : math.min(_currentIndex, total - 1);
    final shown = isTablet ? index - index % 2 : index;
    _syncControllerWithLayout(isTablet, shown);

    final visibleCards = <WordEntry>[
      if (total > 0) words[shown],
      if (isTablet && shown + 1 < total) words[shown + 1],
    ];
    final progress = total == 0
        ? 0.0
        : math.min(shown + (isTablet ? 2 : 1), total) / total;

    void next() => _step(1, shown, total, isTablet);
    void previous() => _step(-1, shown, total, isTablet);

    final menuItems = <PopupMenuEntry<VoidCallback>>[
      _menuItem(
        palette,
        icon: Icons.add_rounded,
        label: 'Adicionar palavra',
        value: _openAddWord,
      ),
      _menuItem(
        palette,
        icon: Icons.style_outlined,
        label: 'Revisar',
        value: _openReview,
        enabled: !notebookIsEmpty,
      ),
      if (visibleCards.isNotEmpty) ...[
        const PopupMenuDivider(height: 9),
        _menuHeading(palette, 'Excluir ficha'),
        for (final w in visibleCards)
          _menuItem(
            palette,
            icon: Icons.delete_outline_rounded,
            label: w.germanWord,
            labelColor: GrammarColors.of(
              w.category,
              isDark: Theme.of(context).brightness == Brightness.dark,
            ),
            serif: true,
            value: () => _confirmDelete(w),
          ),
      ],
    ];

    Widget content = wordsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Não foi possível abrir o caderno: $err',
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.text600),
          ),
        ),
      ),
      data: (_) {
        if (total == 0) {
          return _EmptyState(
            notebookIsEmpty: notebookIsEmpty,
            onAdd: _openAddWord,
          );
        }
        if (isTablet) {
          // Deslizar para os lados também funciona no caderno aberto.
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              if (v < -200) next();
              if (v > 200) previous();
            },
            child: TabletNotebookView(
              left: words[shown],
              right: shown + 1 < total ? words[shown + 1] : null,
            ),
          );
        }
        return PageView.builder(
          controller: _pageController,
          itemCount: total,
          onPageChanged: (i) => setState(() => _currentIndex = i),
          itemBuilder: (_, i) => FlashcardCard(
            key: ValueKey(words[i].id),
            word: words[i],
          ),
        );
      },
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Ícones da barra de status legíveis sobre o fundo de papel.
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: CallbackShortcuts(
        // Teclado, como no protótipo: → ou espaço avança, ← volta.
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowRight): next,
          const SingleActivator(LogicalKeyboardKey.space): next,
          const SingleActivator(LogicalKeyboardKey.arrowLeft): previous,
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            body: Column(
              children: [
                _Header(
                  title: title,
                  maxWidth: barMaxWidth,
                  counter: _counterText(shown, total, isTablet),
                  progress: progress,
                  filter: filter,
                  onFilter: (f) =>
                      ref.read(wordFilterProvider.notifier).state = f,
                  menuItems: menuItems,
                ),
                Expanded(child: content),
                if (total > 0)
                  _NavigationFooter(
                    maxWidth: barMaxWidth,
                    onBack: previous,
                    onForward: next,
                    onSpeak: () =>
                        speakWithFeedback(context, words[shown].germanWord),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `<header>` do protótipo: título, contador, barra de progresso e filtros.
class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.maxWidth,
    required this.counter,
    required this.progress,
    required this.filter,
    required this.onFilter,
    required this.menuItems,
  });

  final String title;
  final double maxWidth;
  final String counter;
  final double progress;
  final WordFilter filter;
  final ValueChanged<WordFilter> onFilter;
  final List<PopupMenuEntry<VoidCallback>> menuItems;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return Container(
      decoration: BoxDecoration(
        color: p.page,
        border: Border(bottom: BorderSide(color: p.divider)),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Título + contador (+ menu, que não existe no protótipo)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 4),
                    child: SizedBox(
                      height: 24,
                      child: Row(
                        children: [
                          // Voltar para a tela inicial.
                          if (Navigator.of(context).canPop()) ...[
                            Tooltip(
                              message: 'Voltar',
                              child: InkResponse(
                                radius: 18,
                                onTap: () => Navigator.of(context).maybePop(),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: ChevronIcon.left(
                                    color: p.text500,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Image.asset(
                            kLogoMark,
                            height: 28,
                            color: p.text600,
                            colorBlendMode: BlendMode.srcIn,
                            excludeFromSemantics: true,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                height: 16 / 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                                color: p.text600,
                              ),
                            ),
                          ),
                          Text(
                            counter,
                            style: AppTheme.mono(
                              fontSize: 11,
                              letterSpacing: 0.275,
                              color: p.text500,
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            height: 24,
                            child: PopupMenuButton<VoidCallback>(
                              tooltip: 'Mais opções',
                              padding: EdgeInsets.zero,
                              iconSize: 18,
                              icon: Icon(Icons.more_vert, color: p.text500),
                              position: PopupMenuPosition.under,
                              offset: const Offset(0, 6),
                              color: p.card,
                              surfaceTintColor: Colors.transparent,
                              elevation: 6,
                              shadowColor: Colors.black26,
                              constraints: const BoxConstraints(minWidth: 220),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: p.cardBorder),
                              ),
                              onSelected: (action) => action(),
                              itemBuilder: (_) => menuItems,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Barra fina: h-1.5, gray-200/70, preenchimento gray-800
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Semantics(
                      label: 'Progresso no caderno',
                      value: counter,
                      child: Container(
                        height: 6,
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: p.track,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: AnimatedFractionallySizedBox(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          widthFactor: progress.clamp(0.0, 1.0).toDouble(),
                          heightFactor: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: p.progress,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Filtros (rolagem horizontal, gap-1.5)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 2,
                    ),
                    child: Row(
                      children: [
                        for (final f in WordFilter.values) ...[
                          if (f != WordFilter.values.first)
                            const SizedBox(width: 6),
                          _FilterPill(
                            filter: f,
                            selected: f == filter,
                            onTap: () => onFilter(f),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ponto verde com `animate-pulse` (opacidade 1 → 0,5 → 1 a cada 2 s).
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respeita "reduzir movimento" do sistema.
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const curve = Cubic(0.4, 0, 0.6, 1);
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        final t = _controller.value;
        // 0→0,5: some até 50%; 0,5→1: volta.
        final phase = t < 0.5 ? t * 2 : (1 - t) * 2;
        final opacity = 1 - 0.5 * curve.transform(phase);
        return Opacity(opacity: opacity, child: child);
      },
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: GrammarColors.brandDot,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Pílula de filtro: `px-3 py-1 rounded-full text-xs font-semibold`.
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final WordFilter filter;
  final bool selected;
  final VoidCallback onTap;

  static ChipColors? _colorsFor(WordFilter f, bool isDark) => switch (f) {
        WordFilter.all => null, // "Todos" não tem borda no protótipo
        WordFilter.der => isDark ? ChipColors.derDark : ChipColors.der,
        WordFilter.die => isDark ? ChipColors.dieDark : ChipColors.die,
        WordFilter.das => isDark ? ChipColors.dasDark : ChipColors.das,
        WordFilter.verbs => isDark ? ChipColors.verbDark : ChipColors.verb,
        WordFilter.adjectives =>
          isDark ? ChipColors.adjectiveDark : ChipColors.adjective,
        WordFilter.prepositions =>
          isDark ? ChipColors.prepositionDark : ChipColors.preposition,
        WordFilter.others =>
          isDark ? ChipColors.neutralDark : ChipColors.neutral,
      };

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = _colorsFor(filter, isDark) ??
        (isDark ? ChipColors.neutralDark : ChipColors.neutral);
    final hasBorder = filter != WordFilter.all;
    final shape = StadiumBorder(
      side: hasBorder ? BorderSide(color: c.border) : BorderSide.none,
    );

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? p.ink : p.card,
        shape: shape,
        elevation: selected ? 0.5 : 0, // shadow-xs
        shadowColor: Colors.black26,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              // py-1 + a borda de 1 px que só os chips coloridos têm
              vertical: hasBorder ? 4 : 5,
            ),
            child: Text(
              filter.label,
              style: TextStyle(
                fontSize: 12,
                height: 16 / 12,
                fontWeight: FontWeight.w600,
                color: selected ? p.onInk : c.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.notebookIsEmpty, required this.onAdd});

  final bool notebookIsEmpty;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              notebookIsEmpty
                  ? 'Seu caderno está vazio.'
                  : 'Nenhuma ficha nesta categoria ainda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: p.text600),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Adicionar palavra'),
            ),
          ],
        ),
      ),
    );
  }
}

/// `<footer>` do protótipo: Anterior · Ouvir · Próximo.
class _NavigationFooter extends StatelessWidget {
  const _NavigationFooter({
    required this.maxWidth,
    required this.onBack,
    required this.onForward,
    required this.onSpeak,
  });

  final double maxWidth;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    const label = TextStyle(
      fontFamily: AppTheme.sansFamily,
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w600,
    );
    // py-3 + linha de 20 px
    const buttonSize = Size.fromHeight(44);
    const buttonPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 12);

    return Container(
      decoration: BoxDecoration(
        color: p.footer,
        border: Border(top: BorderSide(color: p.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: onBack,
                      style: TextButton.styleFrom(
                        minimumSize: buttonSize,
                        padding: buttonPadding,
                        backgroundColor: p.softButton,
                        foregroundColor: p.text700,
                        textStyle: label,
                        shape: shape,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ChevronIcon.left(color: p.text700),
                          const SizedBox(width: 6),
                          const Text('Anterior'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SpeakButton(onPressed: onSpeak),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: onForward,
                      style: FilledButton.styleFrom(
                        minimumSize: buttonSize,
                        padding: buttonPadding,
                        backgroundColor: p.ink,
                        foregroundColor: p.onInk,
                        textStyle: label,
                        shape: shape,
                        elevation: 1, // shadow-sm
                        shadowColor: Colors.black26,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Próximo'),
                          const SizedBox(width: 6),
                          ChevronIcon.right(color: p.onInk),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Item do menu "⋮": ícone + texto, no estilo da interface.
PopupMenuItem<VoidCallback> _menuItem(
  AppPalette p, {
  required IconData icon,
  required String label,
  required VoidCallback value,
  bool enabled = true,
  Color? labelColor,
  bool serif = false,
}) {
  final color = enabled ? (labelColor ?? p.text700) : p.text400;
  return PopupMenuItem<VoidCallback>(
    value: value,
    enabled: enabled,
    height: 44,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Row(
      children: [
        Icon(icon, size: 18, color: enabled ? p.text500 : p.text400),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: serif
                ? AppTheme.serif(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  )
                : TextStyle(
                    fontFamily: AppTheme.sansFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
          ),
        ),
      ],
    ),
  );
}

/// Rótulo de grupo do menu, em caixa alta (não clicável).
PopupMenuItem<VoidCallback> _menuHeading(AppPalette p, String text) {
  return PopupMenuItem<VoidCallback>(
    enabled: false,
    height: 28,
    padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: AppTheme.sansFamily,
        fontSize: 11,
        letterSpacing: 0.6,
        fontWeight: FontWeight.w600,
        color: p.text400,
      ),
    ),
  );
}
