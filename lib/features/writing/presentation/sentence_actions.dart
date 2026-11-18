import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../l10n/app_strings.dart';
import '../../vocabulary/providers/vocabulary_provider.dart';

/// Pergunta se a frase deve ser excluída de "Minhas frases" e exclui.
Future<void> confirmDeleteSentence(
  BuildContext context,
  WidgetRef ref,
  Sentence sentence,
) async {
  final confirmed = await showAppSheet<bool>(context, (ctx) {
    final p = AppPalette.of(ctx);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(tr.deleteSentenceTitle, style: AppText.section(p)),
        const SizedBox(height: 12),
        Text(
          sentence.german,
          style: AppTheme.serif(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.4,
            color: p.text900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tr.deleteSentenceWarning,
          style: AppText.body(p),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: SoftButton(
                label: tr.cancel,
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: tr.delete,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ),
          ],
        ),
      ],
    );
  });
  if (confirmed != true) return;
  await ref.read(databaseProvider).deleteSentence(sentence.id);
}
