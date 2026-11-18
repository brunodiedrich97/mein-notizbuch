import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/language/study_language.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../backup/providers/backup_provider.dart';
import '../../home_widget/data/daily_word_widget.dart';
import '../../home_widget/presentation/widget_invite_card.dart';
import '../../home_widget/providers/widget_invite_provider.dart';
import '../../reminders/data/reminder_service.dart';
import '../../reminders/providers/reminder_provider.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../decks/presentation/deck_navigation.dart';
import '../../decks/presentation/widgets/deck_card.dart';
import '../../decks/presentation/widgets/new_deck_sheet.dart';
import '../../decks/providers/deck_provider.dart';
import '../../splash/presentation/splash_screen.dart' show kLogoMark;
import '../../vocabulary/presentation/widgets/word_list_card.dart';
import '../../vocabulary/providers/vocabulary_provider.dart';
import '../../../core/language/study_language_provider.dart';

/// Tela inicial: saudação, atalhos (revisar e adicionar), os decks e as
/// últimas palavras cadastradas.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Quantas palavras recentes aparecem na lista.
  static const int recentCount = 5;

  /// A revisão precisa de pelo menos duas fichas para montar as opções.
  static const int minWordsForReview = 2;

  static String _greeting(DateTime now) {
    final terms = StudyLanguages.active.terms;
    if (now.hour < 12) return terms.goodMorning;
    if (now.hour < 18) return terms.goodDay;
    return terms.goodEvening;
  }

  static String _countText(int words, int decks) {
    if (words == 0) return 'Seu Notizbuch ainda está vazio';
    final w = words == 1 ? '1 ficha' : '$words fichas';
    final d = decks == 1 ? '1 deck' : '$decks decks';
    return '$w em $d';
  }

  Future<void> _createDeck(BuildContext context) async {
    final id = await NewDeckSheet.show(context);
    if (id != null && context.mounted) await openDeck(context, id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppPalette.of(context);
    // Saudação e textos seguem o idioma de estudo.
    ref.watch(studyLanguageProvider);
    final wordsAsync = ref.watch(wordListProvider);
    final words = wordsAsync.valueOrNull ?? const <WordEntry>[];
    final total = words.length;
    final decks =
        ref.watch(deckSummariesProvider).valueOrNull ?? const <DeckSummary>[];

    // A lista vem em ordem de cadastro; as mais novas ficam no fim.
    final recent = words.reversed.take(recentCount).toList();

    return _StartupTasks(
      child: Scaffold(
      backgroundColor: p.page,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // ---------- Topo ----------
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: p.divider)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            kLogoMark,
                            height: 28,
                            color: p.text600,
                            colorBlendMode: BlendMode.srcIn,
                            excludeFromSemantics: true,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'MEIN NOTIZBUCH',
                            style: TextStyle(
                              fontSize: 12,
                              height: 16 / 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                              color: p.text600,
                            ),
                          ),
                          const Spacer(),
                          HeaderIconButton(
                            icon: Icons.settings_outlined,
                            tooltip: 'Ajustes',
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const SettingsScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        _greeting(DateTime.now()),
                        style: AppTheme.serif(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                          color: p.text900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        wordsAsync.isLoading
                            ? ' '
                            : _countText(total, decks.length),
                        style: TextStyle(fontSize: 13, color: p.text500),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const WidgetInviteCard(),

                      // ---------- Atalhos ----------
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _ShortcutTile(
                                icon: Icons.style_outlined,
                                title: 'Revisar tudo',
                                subtitle: total >= minWordsForReview
                                    ? 'Quiz com todos os decks'
                                    : 'Precisa de 2 fichas',
                                onTap: total >= minWordsForReview
                                    ? () => openReview(context, ref)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _ShortcutTile(
                                icon: Icons.add_rounded,
                                title: 'Adicionar',
                                subtitle: 'Nova palavra',
                                onTap: () => openAddWord(context),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ---------- Decks ----------
                      const SizedBox(height: 24),
                      _SectionTitle(
                        'MEUS DECKS',
                        trailing: Text(
                          decks.length == 1 ? '1 deck' : '${decks.length} decks',
                          style: TextStyle(fontSize: 12, color: p.text400),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _DeckGrid(
                        children: [
                          for (final d in decks)
                            DeckCard(
                              summary: d,
                              onTap: () => openDeck(context, d.deck.id),
                            ),
                          NewDeckCard(onTap: () => _createDeck(context)),
                        ],
                      ),

                      // ---------- Últimas palavras ----------
                      if (recent.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _SectionTitle(
                          'ÚLTIMAS PALAVRAS',
                          trailing: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => openWordIndex(context),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Ver todas',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: p.text500,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  ChevronIcon.right(
                                    color: p.text500,
                                    size: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        WordListCard(
                          words: recent,
                          onTap: (w) => openWordDetail(context, w.id),
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

/// Título de seção em caixa alta, com algo opcional à direita.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: p.text600,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// Grade de duas colunas; os cartões de uma mesma linha têm a mesma altura.
class _DeckGrid extends StatelessWidget {
  const _DeckGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const gap = 12.0;
    return Column(
      children: [
        for (var i = 0; i < children.length; i += 2) ...[
          if (i > 0) const SizedBox(height: gap),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: children[i]),
                const SizedBox(width: gap),
                Expanded(
                  child: i + 1 < children.length
                      ? children[i + 1]
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Atalho em cartão claro: ícone num quadrado, título e descrição.
class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  /// `null` deixa o atalho desabilitado.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final enabled = onTap != null;
    final radius = BorderRadius.circular(16);

    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: p.cardBorder),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: p.softButton,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: enabled ? p.text700 : p.text400,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: enabled ? p.text900 : p.text400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: p.text400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarefas ao abrir a tela inicial e sempre que o app volta para a
/// frente: backup diário (se ainda não houve hoje), renovar a fila de
/// lembretes e o widget, e abrir a ficha da notificação ou do widget que
/// abriu o app.
class _StartupTasks extends ConsumerStatefulWidget {
  const _StartupTasks({required this.child});

  final Widget child;

  @override
  ConsumerState<_StartupTasks> createState() => _StartupTasksState();
}

class _StartupTasksState extends ConsumerState<_StartupTasks>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      _run();
      ref.read(widgetInviteProvider.notifier).check();
      // Ficha da notificação ou do widget que abriu o app.
      final wordId = ReminderService.instance.takeLaunchWordId() ??
          DailyWordWidget.takeLaunchWordId();
      if (wordId != null && mounted) openWordDetail(context, wordId);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _run();
  }

  void _run() {
    if (!mounted) return;
    ref.read(backupProvider.notifier).backupIfDue();
    ref.read(reminderProvider.notifier).refresh();
    refreshDailyWordWidget(ref);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
