import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Fileira de teclas ä ö ü ß, para escrever em alemão com qualquer teclado.
/// Insere a letra na posição do cursor de [controller].
class UmlautKeys extends StatelessWidget {
  const UmlautKeys({super.key, required this.controller});

  final TextEditingController controller;

  static const _letters = ['ä', 'ö', 'ü', 'ß', 'Ä', 'Ö', 'Ü'];

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
    final p = AppPalette.of(context);
    final radius = BorderRadius.circular(8);
    // As letras crescem até 1,3x; acima disso não caberiam na tecla.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final letter in _letters)
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
