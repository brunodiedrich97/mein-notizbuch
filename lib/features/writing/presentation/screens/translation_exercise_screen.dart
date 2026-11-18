import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/language/study_language.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../../l10n/app_strings.dart';
import '../../../decks/presentation/deck_navigation.dart';
import '../../../decks/providers/deck_provider.dart';
import '../../../study/presentation/widgets/session_summary.dart';
import '../../../study/providers/study_provider.dart';
import '../../../vocabulary/providers/vocabulary_provider.dart';
import '../../../word_classes/presentation/word_appearance.dart';
import '../../models/sentence_check.dart';
import '../../models/sentence_source.dart';
import '../widgets/umlaut_keys.dart';
import 'write_sentence_screen.dart';

/// Tradução reversa: o app mostra a tradução do exemplo de uma ficha e o
/// usuário escreve a frase em alemão. A correção compara palavra por
/// palavra com o exemplo.
///
/// Usa as fichas do deck aberto (`deckScopeProvider`) que têm exemplo e
/// tradução do exemplo.
class TranslationExerciseScreen extends ConsumerStatefulWidget {
  const TranslationExerciseScreen({super.key});

  /// Frases por sessão.
  static const int sessionSize = 10;

  @override
  ConsumerState<TranslationExerciseScreen> createState() =>
      _TranslationExerciseScreenState();
}

class _TranslationExerciseScreenState
    extends ConsumerState<TranslationExerciseScreen> {
  final _input = TextEditingController();
  final _focus = FocusNode();

  List<int> _ids = const [];
  final Map<int, bool> _results = {};
  int _index = 0;
  bool _ready = false;
  bool _finished = false;

  /// Correção da frase atual (`null` = ainda escrevendo).
  SentenceCheck? _check;
  bool _revealed = false;
  bool _acceptedAnyway = false;
  bool _saved = false;

  static bool _hasExample(WordEntry w) =>
      (w.exampleGerman?.trim().isNotEmpty ?? false) &&
      (w.examplePortuguese?.trim().isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
    _focus.addListener(() => setState(() {}));
    _start();
  }

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final all = await ref.read(wordListProvider.future);
    if (!mounted) return;
    final deckId = ref.read(deckScopeProvider);
    final pool = [
      for (final w in all)
        if ((deckId == null || deckOf(w) == deckId) && _hasExample(w)) w,
    ]
      ..shuffle(Random())
      ..sort((a, b) => studyPriority(b).compareTo(studyPriority(a)));
    setState(() {
      _ids = [
        for (final w in pool.take(TranslationExerciseScreen.sessionSize)) w.id,
      ];
      _results.clear();
      _index = 0;
      _finished = false;
      _ready = true;
      _resetAnswer();
    });
  }

  void _resetAnswer() {
    _input.clear();
    _check = null;
    _revealed = false;
    _acceptedAnyway = false;
    _saved = false;
  }

  void _verify(WordEntry word) {
    if (_input.text.trim().isEmpty) return;
    _focus.unfocus();
    setState(() {
      _check = checkSentence(_input.text, word.exampleGerman!.trim());
    });
  }

  void _reveal(WordEntry word) {
    _focus.unfocus();
    setState(() {
      _revealed = true;
      _check = checkSentence('', word.exampleGerman!.trim());
    });
  }

  /// Grava o resultado e passa para a próxima frase.
  void _next(List<WordEntry> session, WordEntry word) {
    final check = _check;
    if (check == null) return;
    final correct = !_revealed && (check.isPerfect || _acceptedAnyway);
    ref.read(databaseProvider).recordReview(word.id, correct: correct);
    setState(() {
      _results[word.id] = correct;
      if (_index + 1 >= session.length) {
        _finished = true;
      } else {
        _index++;
      }
      _resetAnswer();
    });
  }

  Future<void> _saveSentence(WordEntry word) async {
    await ref.read(databaseProvider).addSentence(
          SentencesCompanion.insert(
            wordId: word.id,
            german: word.exampleGerman!.trim(),
            portuguese: Value(word.examplePortuguese?.trim()),
            source: SentenceSource.translation,
          ),
        );
    if (mounted) setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final deckId = ref.watch(deckScopeProvider);
    final deck = deckId == null ? null : ref.watch(deckByIdProvider(deckId));
    final deckName = deck?.deck.displayName;

    final all = ref.watch(wordListProvider).valueOrNull ?? const <WordEntry>[];
    final byId = {for (final w in all) w.id: w};
    final session = [
      for (final id in _ids)
        if (byId[id] != null && _hasExample(byId[id]!)) byId[id]!,
    ];
    final total = session.length;
    final index = total == 0 ? 0 : _index.clamp(0, total - 1);
    final word = total == 0 ? null : session[index];

    final eyebrow =
        '${(deckName ?? tr.allCards).toUpperCase()} · ${tr.writeEyebrow}';

    Widget body;
    Widget? footer;
    if (!_ready) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_finished) {
      body = SessionSummary(
        words: session,
        results: _results,
        deckName: deckName,
        practice: true,
        rightLabel: tr.rightCount,
        wrongLabel: tr.toReviewCount,
        onBack: () => Navigator.of(context).maybePop(),
        onRestart: _start,
        onOpenWord: (w) => openWordDetail(context, w.id),
      );
    } else if (word == null) {
      body = _EmptyMessage(deckName: deckName);
    } else {
      final check = _check;
      body = Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _ProgressBar(value: (_results.length) / total),
              const SizedBox(height: 24),
              Text(
                tr.writeIn(
                  tr.languageName(StudyLanguages.active.code).toUpperCase(),
                ),
                style: AppText.caption(p),
              ),
              const SizedBox(height: 8),
              Text(
                word.examplePortuguese!.trim(),
                style: TextStyle(
                  fontFamily: AppTheme.sansFamily,
                  fontSize: 22,
                  height: 1.35,
                  color: p.text900,
                ),
              ),
              const SizedBox(height: 12),
              _WordHint(word: word),
              const SizedBox(height: 16),
              if (check == null) ...[
                WritingField(
                  controller: _input,
                  focusNode: _focus,
                  hint: tr.writeSentenceIn(
                    tr.languageName(StudyLanguages.active.code),
                  ),
                  autofocus: true,
                  onSubmitted: () => _verify(word),
                ),
                const SizedBox(height: 8),
                UmlautKeys(controller: _input),
              ] else
                _ResultCard(
                  check: check,
                  revealed: _revealed,
                  acceptedAnyway: _acceptedAnyway,
                  saved: _saved,
                  onSave: () => _saveSentence(word),
                ),
            ],
          ),
        ),
      );

      final isLast = index + 1 >= total;
      footer = WritingFooter(
        children: check == null
            ? [
                Expanded(
                  child: SoftButton(
                    label: tr.showAnswer,
                    onPressed: () => _reveal(word),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: tr.check,
                    chevron: true,
                    onPressed: _input.text.trim().isEmpty
                        ? null
                        : () => _verify(word),
                  ),
                ),
              ]
            : [
                if (!check.isPerfect && !_revealed && !_acceptedAnyway) ...[
                  Expanded(
                    child: SoftButton(
                      label: tr.acceptAsRight,
                      onPressed: () => setState(() => _acceptedAnyway = true),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: PrimaryButton(
                    label: isLast ? tr.finish : tr.nextFem,
                    chevron: true,
                    onPressed: () => _next(session, word),
                  ),
                ),
              ],
      );
    }

    final showCounter = _ready && !_finished && total > 0;

    return Scaffold(
      backgroundColor: p.page,
      appBar: ScreenHeader(
        eyebrow: eyebrow,
        title: tr.reverseTranslation,
        trailing: showCounter
            ? _StaticPill(text: '${index + 1} / $total')
            : null,
      ),
      body: body,
      bottomNavigationBar: footer,
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      height: 6,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: p.track,
        borderRadius: BorderRadius.circular(3),
      ),
      child: AnimatedFractionallySizedBox(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        widthFactor: value.clamp(0.0, 1.0).toDouble(),
        heightFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: p.progress,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

/// "● use: der Arzt", na cor da classe.
class _WordHint extends StatelessWidget {
  const _WordHint({required this.word});

  final WordEntry word;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = appearanceOf(context, word).color;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              tr.useWord(word.germanWord),
              style: TextStyle(
                fontFamily: AppTheme.sansFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Correção: veredito, resposta com erros riscados, resposta esperada com
/// o que faltou destacado, notas e "Salvar a frase correta".
class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.check,
    required this.revealed,
    required this.acceptedAnyway,
    required this.saved,
    required this.onSave,
  });

  final SentenceCheck check;
  final bool revealed;
  final bool acceptedAnyway;
  final bool saved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final error = Theme.of(context).colorScheme.error;
    final success = isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D);

    final (IconData icon, Color color, String verdict) = switch (true) {
      _ when revealed => (
          Icons.visibility_outlined,
          p.text700,
          tr.thisIsTheAnswer,
        ),
      _ when check.isPerfect => (
          Icons.check_circle_rounded,
          success,
          tr.perfect,
        ),
      _ when acceptedAnyway => (
          Icons.check_circle_outline_rounded,
          p.text700,
          tr.acceptedAsRight,
        ),
      _ => (
          Icons.error_outline_rounded,
          error,
          tr.differences(check.differences),
        ),
    };

    final sentenceStyle = AppTheme.serif(
      fontSize: 19,
      fontWeight: FontWeight.w600,
      height: 1.5,
      color: p.text900,
    );

    TextSpan line(List<DiffToken> tokens, {required bool isAnswer}) {
      return TextSpan(
        style: sentenceStyle,
        children: [
          for (var i = 0; i < tokens.length; i++) ...[
            if (i > 0) const TextSpan(text: ' '),
            if (tokens[i].ok)
              TextSpan(text: tokens[i].text)
            else if (isAnswer)
              TextSpan(
                text: tokens[i].text,
                style: TextStyle(
                  color: error,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: error,
                  decorationThickness: 1.5,
                ),
              )
            else
              TextSpan(
                text: tokens[i].text,
                style: TextStyle(
                  color: success,
                  backgroundColor: success.withValues(alpha: 0.12),
                ),
              ),
          ],
        ],
      );
    }

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
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  verdict,
                  style: AppText.item(p).copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          if (!revealed && !check.isPerfect) ...[
            const SizedBox(height: 16),
            Text(tr.yourAnswer, style: AppText.caption(p)),
            const SizedBox(height: 4),
            Text.rich(line(check.answer, isAnswer: true)),
          ],
          const SizedBox(height: 16),
          Text(
            check.isPerfect && !revealed ? tr.yourAnswer : tr.expectedAnswer,
            style: AppText.caption(p),
          ),
          const SizedBox(height: 4),
          revealed
              ? Text(
                  check.expected.map((t) => t.text).join(' '),
                  style: sentenceStyle,
                )
              : Text.rich(line(check.expected, isAnswer: false)),
          if (!revealed)
            for (final note in check.notes) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: p.pronBox,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: p.outline),
                ),
                child: Text(note, style: AppText.body(p)),
              ),
            ],
          const SizedBox(height: 12),
          if (saved)
            Row(
              children: [
                Icon(Icons.check_rounded, size: 16, color: success),
                const SizedBox(width: 6),
                Text(
                  tr.savedInMySentences,
                  style: AppText.meta(p).copyWith(
                    fontWeight: FontWeight.w600,
                    color: success,
                  ),
                ),
              ],
            )
          else
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onSave,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_outlined, size: 16, color: p.text700),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        tr.saveCorrectSentence,
                        style: AppText.item(p).copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: p.text700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StaticPill extends StatelessWidget {
  const _StaticPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.outline),
      ),
      child: Text(text, style: AppTheme.mono(fontSize: 12, color: p.text700)),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.deckName});

  final String? deckName;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final deck = deckName;
    final message = deck == null
        ? tr.noExamplesInNotebook(tr.addWordTitle)
        : tr.noExamplesInDeck(deck, tr.addWordTitle);
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
              PrimaryButton(
                label: tr.back,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
