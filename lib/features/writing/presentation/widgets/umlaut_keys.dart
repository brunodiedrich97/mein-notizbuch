import 'package:flutter/material.dart';

import '../../../../core/language/study_language.dart';
import '../../../../core/theme/app_theme.dart';

/// Fileira com as letras especiais do idioma de estudo (ä ö ü ß no
/// alemão), para escrever com qualquer teclado.
/// Insere a letra na posição do cursor de [controller].
class UmlautKeys extends StatelessWidget {
  const UmlautKeys({super.key, required this.controller});

  final TextEditingController controller;

  void _insert(String letter) {
    final value = controller.value;
    final sel = value.selection;
    final start = sel.isValid ? sel.start : value.text.length;
    final end = sel.isValid ? sel.end : value.text.length;
    final text = value.text.replaceRange(start, end, letter);
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: start + letter.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Idiomas sem letras especiais (inglês) não mostram a fileira.
    if (StudyLanguages.active.specialLetters.isEmpty) {
      return const SizedBox.shrink();
    }
    final p = AppPalette.of(context);
    final radius = BorderRadius.circular(8);
    // As letras crescem até 1,3x; acima disso não caberiam na tecla.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final letter in StudyLanguages.active.specialLetters)
          Material(
            color: p.card,
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(color: p.outline),
            ),
            child: InkWell(
              borderRadius: radius,
              onTap: () => _insert(letter),
              child: SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: Text(
                    letter,
                    style: AppTheme.serif(fontSize: 17, color: p.text700),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
    );
  }
}
