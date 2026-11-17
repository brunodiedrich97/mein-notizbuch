import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../vocabulary/presentation/widgets/word_list_card.dart';

/// Resumo no fim de uma sessão (fichas ou escrita): título, contagem de
/// acertos e erros, palavras para rever e os botões de saída.
class SessionSummary extends StatelessWidget {
  const SessionSummary({
    super.key,
    required this.words,
    required this.results,
    required this.deckName,
    required this.onBack,
    required this.onRestart,
    required this.onOpenWord,
    this.verb = 'estudou',
    this.rightLabel = 'sabia',
    this.wrongLabel = 'ainda não',
  });

  final List<WordEntry> words;

  /// Resultado por id de palavra: `true` = acerto.
  final Map<int, bool> results;
  final String? deckName;
  final VoidCallback onBack;
  final VoidCallback onRestart;
  final ValueChanged<WordEntry> onOpenWord;

  /// "Você estudou 12 fichas", "Você praticou 10 frases"…
  final String verb;
  final String rightLabel;
  final String wrongLabel;

  /// Largura máxima do conteúdo.
  static const double maxWidth = 448;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final right = results.values.where((r) => r).length;
    final wrong = results.values.where((r) => !r).length;
    final toReview = [
      for (final w in words)
        if (results[w.id] == false) w,
    ];
    final total = words.length;
    final great = total > 0 && right / total >= 0.7;
    final studied = total == 1 ? '1 ficha' : '$total fichas';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
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
                  ? 'Você $verb $studied.'
                  : 'Você $verb $studied do deck $deckName.',
              style: AppText.body(p),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _StatTile(value: right, label: rightLabel)),
                const SizedBox(width: 12),
                Expanded(child: _StatTile(value: wrong, label: wrongLabel)),
              ],
            ),
            if (toReview.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text('PARA REVER', style: AppText.section(p)),
              const SizedBox(height: 12),
              WordListCard(words: toReview, onTap: onOpenWord),
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
