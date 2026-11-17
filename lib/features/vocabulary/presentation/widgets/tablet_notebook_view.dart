import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import 'flashcard_card.dart';

/// Caderno aberto: duas fichas lado a lado, com a lombada no meio.
class TabletNotebookView extends StatelessWidget {
  const TabletNotebookView({super.key, required this.left, this.right});

  final WordEntry left;
  final WordEntry? right;

  @override
  Widget build(BuildContext context) {
    final rightWord = right;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: FlashcardCard(
              key: ValueKey('left-${left.id}'),
              word: left,
              margin: const EdgeInsets.fromLTRB(0, 16, 16, 16),
            ),
          ),
          const _Spine(),
          Expanded(
            child: rightWord != null
                ? FlashcardCard(
                    key: ValueKey('right-${rightWord.id}'),
                    word: rightWord,
                    margin: const EdgeInsets.fromLTRB(16, 16, 0, 16),
                  )
                : const _EndPage(),
          ),
        ],
      ),
    );
  }
}

class _Spine extends StatelessWidget {
  const _Spine();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final edge = isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08);
    return Container(
      width: 2,
      margin: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, edge, edge, Colors.transparent],
          stops: const [0, 0.15, 0.85, 1],
        ),
      ),
    );
  }
}

class _EndPage extends StatelessWidget {
  const _EndPage();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Text(
        'Fim do caderno.',
        style: AppTheme.serif(
          fontSize: 18,
          fontStyle: FontStyle.italic,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
      ),
    );
  }
}
