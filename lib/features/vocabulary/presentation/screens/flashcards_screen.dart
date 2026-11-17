import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/grammar_colors.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../../core/widgets/speak_button.dart';
import '../../../decks/presentation/deck_navigation.dart';
import '../../../decks/providers/deck_provider.dart';
import '../../../review/presentation/review_session_screen.dart';
import '../../../study/presentation/widgets/study_filter_sheet.dart';
import '../../../study/providers/study_provider.dart';
import '../../providers/vocabulary_provider.dart';
import '../widgets/delete_word_dialog.dart';
import '../widgets/flashcard_card.dart';
import '../widgets/pronunciation_box.dart';
import '../widgets/word_list_card.dart';

/// Sessão de estudo: um lote de fichas (do deck aberto, ou de todos), uma
/// por vez. Para cada ficha, o usuário diz se sabia ou não; a resposta é
/// gravada nos mesmos acertos e erros da revisão.
///
/// O deck vem de `deckScopeProvider`, e filtro, ordem e tamanho de
/// `studySettingsProvider`.
class FlashcardsScreen extends ConsumerStatefulWidget {
  const FlashcardsScreen({super.key});

  /// Largura máxima do conteúdo (`max-w-md` do protótipo).
  static const double maxWidth = 448;

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen> {
  /// Ids das fichas da sessão, na ordem em que aparecem.
  List<int> _sessionIds = const [];

  /// Quantas palavras há no deck (ou no caderno), antes do filtro.
  int _poolSize = 0;

  /// Respostas desta sessão: `true` = sabia.
  final Map<int, bool> _results = {};

  int _index = 0;
  bool _ready = false;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  /// Monta uma sessão nova com as configurações atuais.
  Future<void> _startSession() async {
    final all = await ref.read(wordListProvider.future);
    if (!mounted) return;
    final deckId = ref.read(deckScopeProvider);
    final pool =
        deckId == null ? all : all.where((w) => deckOf(w) == deckId).toList();
    final session = buildSession(pool, ref.read(studySettingsProvider));
    setState(() {
      _poolSize = pool.length;
      _sessionIds = [for (final w in session) w.id];
      _results.clear();
      _index = 0;
      _finished = false;
      _ready = true;
    });
  }

  Future<void> _openFilters() async {
    final current = ref.read(studySettingsProvider);
    final next = await showStudyFilterSheet(context, current);
    if (next == null || !mounted) return;
    ref.read(studySettingsProvider.notifier).state = next;
    await _startSession();
  }

  Future<void> _clearFilter() async {
    final s = ref.read(studySettingsProvider);
    ref.read(studySettingsProvider.notifier).state =
        s.copyWith(filter: WordFilter.all);
    await _startSession();
  }

  void _go(int index, int total) {
    if (total == 0) return;
    setState(() => _index = index.clamp(0, total - 1));
  }

  /// Registra a resposta e vai para a próxima ficha ainda sem resposta.
  void _grade(List<WordEntry> session, int at, bool knew) {
    if (session.isEmpty) return;
    final word = session[at];
    // Grava só a primeira resposta, para não contar a mesma ficha duas vezes.
    if (!_results.containsKey(word.id)) {
      ref.read(databaseProvider).recordReview(word.id, correct: knew);
    }
    setState(() {
      _results[word.id] = knew;
      final next = _nextUnanswered(session, at);
      if (next == null) {
        _finished = true;
      } else {
        _index = next;
      }
    });
  }

  int? _nextUnanswered(List<WordEntry> session, int from) {
    for (var k = 1; k <= session.length; k++) {
      final i = (from + k) % session.length;
      if (!_results.containsKey(session[i].id)) return i;
    }
    return null;
  }

  Future<void> _openJumpSheet(List<WordEntry> session) async {
    final target = await showAppSheet<int>(
      context,
      (_) => _JumpSheet(
        session: session,
        current: _index,
        results: _results,
      ),
    );
    if (target != null && mounted) _go(target, session.length);
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

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(studySettingsProvider);
    final deckId = ref.watch(deckScopeProvider);
    final deck = deckId == null ? null : ref.watch(deckByIdProvider(deckId));
    final deckName = deck?.deck.namePt;

    // A sessão guarda só os ids; os dados vêm sempre atualizados do banco
    // (e fichas excluídas saem da sessão).
    final all = ref.watch(wordListProvider).valueOrNull ?? const <WordEntry>[];
    final byId = {for (final w in all) w.id: w};
    final session = [
      for (final id in _sessionIds)
        if (byId[id] != null) byId[id]!,
    ];
    final total = session.length;
    final index = total == 0 ? 0 : _index.clamp(0, total - 1);
    final current = total == 0 ? null : session[index];
    final answered = _results.length;

    final eyebrow = (deckName ?? 'Todas as fichas').toUpperCase();
    final title = _finished ? 'Sessão concluída' : 'Sessão de estudo';

    Widget body;
    if (!_ready) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_finished) {
      body = _SessionSummary(
        session: session,
        results: _results,
        deckName: deckName,
        onBack: () => Navigator.of(context).maybePop(),
        onRestart: _startSession,
      );
    } else if (total == 0) {
      body = _poolSize == 0
          ? _EmptyState(
              message: deckName == null
                  ? 'Seu Notizbuch ainda não tem fichas.'
                  : 'O deck "$deckName" ainda não tem fichas.',
              actionLabel: 'Adicionar palavra',
              onAction: () => openAddWord(context, deckId: deckId),
            )
          : _EmptyState(
              message: 'Nenhuma ficha com o filtro '
                  '"${settings.filter.label}".',
              actionLabel: 'Limpar filtro',
              onAction: _clearFilter,
            );
    } else {
      final word = current!;
      body = Column(
        children: [
          _SessionToolbar(
            progress: answered / total,
            filterLabel: settings.filter.label,
            orderLabel: settings.order.label,
            onFilters: _openFilters,
          ),
          Expanded(
            child: GestureDetector(
              // Deslizar navega entre as fichas, sem responder.
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (d) {
                final v = d.primaryVelocity ?? 0;
                if (v < -200) _go(index + 1, total);
                if (v > 200) _go(index - 1, total);
              },
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: FlashcardCard(
                  key: ValueKey(word.id),
                  word: word,
                ),
              ),
            ),
          ),
          _GradeFooter(
            answer: _results[word.id],
            onNotYet: () => _grade(session, index, false),
            onKnew: () => _grade(session, index, true),
            onSpeak: () => speakWithFeedback(context, word.germanWord),
          ),
        ],
      );
    }

    final showControls = _ready && !_finished && total > 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Ícones da barra de status legíveis sobre o fundo de papel.
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: CallbackShortcuts(
        // Teclado: ← e → navegam; 1 = ainda não, 2 = sabia.
        bindings: {
          const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
              _go(index + 1, total),
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
              _go(index - 1, total),
          if (showControls) ...{
            const SingleActivator(LogicalKeyboardKey.digit1): () =>
                _grade(session, index, false),
            const SingleActivator(LogicalKeyboardKey.digit2): () =>
                _grade(session, index, true),
          },
        },
        child: Focus(
          autofocus: true,
          child: Scaffold(
            backgroundColor: p.page,
            appBar: ScreenHeader(
              eyebrow: eyebrow,
              title: title,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showControls) ...[
                    _CounterPill(
                      text: '${index + 1} / $total',
                      onTap: () => _openJumpSheet(session),
                    ),
                    const SizedBox(width: 8),
                  ],
                  _SessionMenu(
                    current: showControls ? current : null,
                    onWords: () => openWordIndex(context, deckId: deckId),
                    onAdd: () => openAddWord(context, deckId: deckId),
                    onReview: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ReviewSessionScreen(),
                      ),
                    ),
                    onDelete: _confirmDelete,
                  ),
                ],
              ),
            ),
            body: body,
          ),
        ),
      ),
    );
  }
}

/// Progresso da sessão e os botões de filtro e ordem.
class _SessionToolbar extends StatelessWidget {
  const _SessionToolbar({
    required this.progress,
    required this.filterLabel,
    required this.orderLabel,
    required this.onFilters,
  });

  final double progress;
  final String filterLabel;
  final String orderLabel;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: FlashcardsScreen.maxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                label: 'Progresso da sessão',
                value: '${(progress * 100).round()}%',
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
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _ToolbarButton(
                      icon: Icons.tune_rounded,
                      label: 'Filtro · $filterLabel',
                      onTap: onFilters,
                    ),
                    const SizedBox(width: 8),
                    _ToolbarButton(
                      icon: Icons.swap_vert_rounded,
                      label: orderLabel,
                      onTap: onFilters,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final radius = BorderRadius.circular(10);
    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: p.outline),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: p.text500),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppText.meta(p).copyWith(
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

/// Contador "3 / 12" tocável, no cabeçalho.
class _CounterPill extends StatelessWidget {
  const _CounterPill({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final radius = BorderRadius.circular(12);
    return Tooltip(
      message: 'Ir para outra ficha',
      child: Material(
        color: p.card,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: p.outline),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: AppTheme.mono(fontSize: 12, color: p.text700),
                ),
                const SizedBox(width: 4),
                Icon(Icons.expand_more_rounded, size: 16, color: p.text500),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rodapé: "Ainda não", áudio e "Sabia".
class _GradeFooter extends StatelessWidget {
  const _GradeFooter({
    required this.answer,
    required this.onNotYet,
    required this.onKnew,
    required this.onSpeak,
  });

  /// Resposta já dada para a ficha atual (`null` = nenhuma).
  final bool? answer;
  final VoidCallback onNotYet;
  final VoidCallback onKnew;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final caption = switch (answer) {
      null => 'VOCÊ SABIA ESTA?',
      true => 'VOCÊ MARCOU: SABIA',
      false => 'VOCÊ MARCOU: AINDA NÃO',
    };

    return Container(
      decoration: BoxDecoration(
        color: p.footer,
        border: Border(top: BorderSide(color: p.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: FlashcardsScreen.maxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(caption, style: AppText.caption(p)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: SoftButton(
                          label: 'Ainda não',
                          onPressed: onNotYet,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SpeakButton(onPressed: onSpeak),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          label: 'Sabia',
                          chevron: true,
                          onPressed: onKnew,
                        ),
                      ),
                    ],
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

/// Lista das fichas da sessão, para pular para qualquer uma.
class _JumpSheet extends StatelessWidget {
  const _JumpSheet({
    required this.session,
    required this.current,
    required this.results,
  });

  final List<WordEntry> session;
  final int current;
  final Map<int, bool> results;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final error = Theme.of(context).colorScheme.error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('FICHAS DA SESSÃO', style: AppText.section(p)),
        const SizedBox(height: 8),
        for (var i = 0; i < session.length; i++)
          InkWell(
            onTap: () => Navigator.of(context).pop(i),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                border: i == session.length - 1
                    ? null
                    : Border(bottom: BorderSide(color: p.divider)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${i + 1}',
                      style: AppTheme.mono(fontSize: 11, color: p.text400),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      session[i].germanWord,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.serif(
                        fontSize: 17,
                        fontWeight: i == current
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: GrammarColors.titleOf(
                          session[i].category,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ),
                  switch (results[session[i].id]) {
                    true => Icon(Icons.check_rounded, size: 18, color: p.text700),
                    false => Icon(Icons.close_rounded, size: 18, color: error),
                    null => i == current
                        ? Text('atual', style: AppText.meta(p))
                        : const SizedBox.shrink(),
                  },
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Menu "⋮" da sessão.
class _SessionMenu extends StatelessWidget {
  const _SessionMenu({
    required this.current,
    required this.onWords,
    required this.onAdd,
    required this.onReview,
    required this.onDelete,
  });

  /// Ficha na tela (para "Excluir esta ficha"), se houver.
  final WordEntry? current;
  final VoidCallback onWords;
  final VoidCallback onAdd;
  final VoidCallback onReview;
  final ValueChanged<WordEntry> onDelete;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final word = current;

    PopupMenuItem<VoidCallback> item(
      IconData icon,
      String label,
      VoidCallback action,
    ) {
      return PopupMenuItem<VoidCallback>(
        value: action,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: p.text500),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: AppText.item(p))),
          ],
        ),
      );
    }

    return PopupMenuButton<VoidCallback>(
      tooltip: 'Mais opções',
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
      itemBuilder: (_) => [
        item(Icons.list_rounded, 'Ver palavras', onWords),
        item(Icons.add_rounded, 'Adicionar palavra', onAdd),
        item(Icons.style_outlined, 'Revisar (quiz)', onReview),
        if (word != null) ...[
          const PopupMenuDivider(height: 9),
          item(
            Icons.delete_outline_rounded,
            'Excluir esta ficha',
            () => onDelete(word),
          ),
        ],
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

/// Resumo no fim da sessão.
class _SessionSummary extends StatelessWidget {
  const _SessionSummary({
    required this.session,
    required this.results,
    required this.deckName,
    required this.onBack,
    required this.onRestart,
  });

  final List<WordEntry> session;
  final Map<int, bool> results;
  final String? deckName;
  final VoidCallback onBack;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final knew = results.values.where((r) => r).length;
    final notYet = results.values.where((r) => !r).length;
    final toReview = [
      for (final w in session)
        if (results[w.id] == false) w,
    ];
    final total = session.length;
    final great = total > 0 && knew / total >= 0.7;
    final studied = total == 1 ? '1 ficha' : '$total fichas';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: FlashcardsScreen.maxWidth),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
          children: [
            Text('SESSÃO CONCLUÍDA', style: AppText.section(p)),
            const SizedBox(height: 8),
            Text(
              great ? 'Gut gemacht!' : 'Weiter so!',
              style: AppText.display(p, fontSize: 40),
            ),
            const SizedBox(height: 8),
            Text(
              deckName == null
                  ? 'Você estudou $studied.'
                  : 'Você estudou $studied do deck $deckName.',
              style: AppText.body(p),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _StatTile(value: knew, label: 'sabia')),
                const SizedBox(width: 12),
                Expanded(child: _StatTile(value: notYet, label: 'ainda não')),
              ],
            ),
            if (toReview.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('PARA REVER', style: AppText.section(p)),
              const SizedBox(height: 12),
              WordListCard(
                words: toReview,
                onTap: (w) => openWordDetail(context, w.id),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: SoftButton(label: 'Voltar', onPressed: onBack)),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: 'Nova sessão',
                    onPressed: onRestart,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value', style: AppText.display(p, fontSize: 32)),
          const SizedBox(height: 4),
          Text(label, style: AppText.meta(p)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppText.body(p),
              ),
              const SizedBox(height: 16),
              PrimaryButton(label: actionLabel, onPressed: onAction),
            ],
          ),
        ),
      ),
    );
  }
}
