import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/grammar_colors.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/speak_button.dart';
import '../../vocabulary/presentation/widgets/pronunciation_box.dart';
import '../providers/review_quiz_provider.dart';

class ReviewSessionScreen extends ConsumerWidget {
  const ReviewSessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quiz = ref.watch(reviewQuizProvider);
    final notifier = ref.read(reviewQuizProvider.notifier);

    return Scaffold(
      appBar: const ScreenHeader(title: 'Revisão'),
      body: quiz.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _CenteredMessage(
          text: 'Não foi possível montar a revisão: $err',
        ),
        data: (state) {
          if (state.isEmpty) {
            return const _CenteredMessage(
              text: 'Ainda não há fichas suficientes para revisar. '
                  'Cadastre pelo menos duas palavras e volte aqui.',
            );
          }
          if (state.isFinished) {
            return _ResultView(
              score: state.score,
              total: state.questions.length,
              onRestart: notifier.restart,
              onExit: () => Navigator.of(context).pop(),
            );
          }
          return _QuestionView(
            state: state,
            onAnswer: notifier.answer,
            onNext: notifier.next,
          );
        },
      ),
    );
  }
}

enum _OptionStatus { idle, correct, wrong, dimmed }

class _QuestionView extends StatelessWidget {
  const _QuestionView({
    required this.state,
    required this.onAnswer,
    required this.onNext,
  });

  final ReviewQuizState state;
  final ValueChanged<int> onAnswer;
  final VoidCallback onNext;

  _OptionStatus _statusFor(int i, QuizQuestion q) {
    if (!state.answered) return _OptionStatus.idle;
    if (i == q.correctIndex) return _OptionStatus.correct;
    if (i == state.selected) return _OptionStatus.wrong;
    return _OptionStatus.dimmed;
  }

  @override
  Widget build(BuildContext context) {
    final q = state.question!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final muted = isDark ? Colors.white70 : const Color(0xFF555555);
    final total = state.questions.length;
    final answered = state.answered;
    final isArticle = q.kind == QuestionKind.article;
    final wasCorrect = answered && state.selected == q.correctIndex;

    // Na pergunta de artigo, a cor e o artigo entregariam a resposta:
    // mostramos a palavra neutra e revelamos tudo depois de responder.
    final hideAnswer = isArticle && !answered;
    final shownWord = hideAnswer ? q.prompt : q.word.germanWord;
    final wordColor = hideAnswer
        ? scheme.onSurface
        : GrammarColors.of(q.word.category, isDark: isDark);

    final example = q.word.exampleGerman?.trim();
    final examplePt = q.word.examplePortuguese?.trim();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Pergunta ${state.current + 1} de $total',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: muted,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (state.current + (answered ? 1 : 0)) / total,
                minHeight: 4,
                backgroundColor:
                    isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              isArticle ? 'Qual é o artigo?' : 'O que significa?',
              style: TextStyle(fontSize: 16, color: muted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    shownWord,
                    style: AppTheme.serif(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: wordColor,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SpeakButton(
                  onPressed: () => speakWithFeedback(context, shownWord),
                ),
              ],
            ),
            if (answered && isArticle) ...[
              const SizedBox(height: 4),
              Text(
                q.word.portugueseTranslation,
                style: TextStyle(fontSize: 18, color: muted),
              ),
            ],
            const SizedBox(height: 24),
            for (var i = 0; i < q.options.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OptionButton(
                  text: q.options[i],
                  status: _statusFor(i, q),
                  onTap: answered ? null : () => onAnswer(i),
                ),
              ),
            if (answered) ...[
              const SizedBox(height: 8),
              _FeedbackCard(
                correct: wasCorrect,
                verdict: wasCorrect
                    ? 'Certo!'
                    : 'A resposta é "${q.options[q.correctIndex]}".',
                example: example,
                exampleTranslation: examplePt,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  state.current + 1 < total ? 'Próxima' : 'Ver resultado',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Opção de resposta. O retorno usa ícone e borda, e não só cor, para não
/// se confundir com o vermelho do "die" e ser legível para daltônicos.
class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.text,
    required this.status,
    required this.onTap,
  });

  final String text;
  final _OptionStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final emphasized =
        status == _OptionStatus.correct || status == _OptionStatus.wrong;
    final borderColor = switch (status) {
      _OptionStatus.correct => scheme.primary,
      _OptionStatus.wrong => scheme.error,
      _ => scheme.outlineVariant,
    };
    final textColor = status == _OptionStatus.dimmed
        ? scheme.onSurface.withValues(alpha: 0.4)
        : scheme.onSurface;

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        side: BorderSide(color: borderColor, width: emphasized ? 2 : 1),
        foregroundColor: textColor,
        disabledForegroundColor: textColor,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 17,
                decoration: status == _OptionStatus.wrong
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
          if (status == _OptionStatus.correct)
            Icon(Icons.check_circle, color: scheme.primary),
          if (status == _OptionStatus.wrong)
            Icon(Icons.cancel, color: scheme.error),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.score,
    required this.total,
    required this.onRestart,
    required this.onExit,
  });

  final int score;
  final int total;
  final VoidCallback onRestart;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ratio = total == 0 ? 0 : score / total;
    final message = ratio >= 0.8
        ? 'Ausgezeichnet! Revisão excelente.'
        : ratio >= 0.5
            ? 'Gut gemacht! Continue praticando.'
            : 'Weiter so! As fichas que você errou voltam primeiro '
                'na próxima revisão.';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score de $total',
                style: AppTheme.serif(fontSize: 48, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: isDark ? Colors.white70 : const Color(0xFF555555),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onRestart,
                  child: const Text('Revisar de novo'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: onExit,
                  child: const Text('Voltar ao caderno'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            height: 1.4,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ),
    );
  }
}

/// Rótulo em caixa alta, no mesmo estilo do "EXEMPLO" das fichas.
class _CapsLabel extends StatelessWidget {
  const _CapsLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        height: 16 / 12,
        letterSpacing: 0.6,
        fontWeight: FontWeight.w600,
        color: AppPalette.of(context).text400,
      ),
    );
  }
}

/// Cartão exibido depois de responder: resultado e, se houver, o exemplo
/// com a tradução.
class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.correct,
    required this.verdict,
    this.example,
    this.exampleTranslation,
  });

  final bool correct;
  final String verdict;
  final String? example;
  final String? exampleTranslation;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final error = Theme.of(context).colorScheme.error;
    final example = this.example;
    final translation = exampleTranslation;

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
              Icon(
                correct ? Icons.check_circle : Icons.cancel,
                size: 20,
                color: correct ? p.text900 : error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  verdict,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: correct ? p.text900 : error,
                  ),
                ),
              ),
            ],
          ),
          if (example != null && example.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: p.divider),
            const SizedBox(height: 14),
            const _CapsLabel('Exemplo'),
            const SizedBox(height: 6),
            Text(
              example,
              style: AppTheme.serif(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: p.text900,
              ),
            ),
            if (translation != null && translation.isNotEmpty) ...[
              const SizedBox(height: 14),
              const _CapsLabel('Tradução'),
              const SizedBox(height: 6),
              Text(
                translation,
                style: TextStyle(fontSize: 15, color: p.text600),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
