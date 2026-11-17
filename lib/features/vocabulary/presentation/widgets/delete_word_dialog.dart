import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../word_classes/presentation/word_appearance.dart';

/// Confirmação de exclusão no estilo dos cartões do app: a palavra aparece
/// na cor da classe gramatical, e os botões seguem os do rodapé das fichas.
class DeleteWordDialog extends StatelessWidget {
  const DeleteWordDialog({super.key, required this.word});

  final WordEntry word;

  /// Mostra o diálogo. Retorna `true` só se o usuário confirmar.
  static Future<bool> show(BuildContext context, WordEntry word) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteWordDialog(word: word),
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final danger = Theme.of(context).colorScheme.error;
    final wordColor = appearanceOf(context, word).titleColor;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    const label = TextStyle(
      fontFamily: AppTheme.sansFamily,
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w600,
    );
    const buttonSize = Size.fromHeight(44);

    return Dialog(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: p.cardBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: danger.withValues(alpha: isDark ? 0.18 : 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: danger,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'EXCLUIR FICHA',
                    style: TextStyle(
                      fontSize: 12,
                      height: 16 / 12,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w700,
                      color: danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                word.germanWord,
                style: AppTheme.serif(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  color: wordColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                word.portugueseTranslation,
                style: TextStyle(fontSize: 14, color: p.text500),
              ),
              const SizedBox(height: 14),
              Text(
                'Esta ficha será removida do Notizbuch. '
                'Essa ação não pode ser desfeita.',
                style: TextStyle(fontSize: 14, height: 1.45, color: p.text600),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        minimumSize: buttonSize,
                        backgroundColor: p.softButton,
                        foregroundColor: p.text700,
                        textStyle: label,
                        shape: shape,
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        minimumSize: buttonSize,
                        backgroundColor: p.ink,
                        foregroundColor: p.onInk,
                        textStyle: label,
                        shape: shape,
                        elevation: 1,
                        shadowColor: Colors.black26,
                      ),
                      child: const Text('Excluir'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
