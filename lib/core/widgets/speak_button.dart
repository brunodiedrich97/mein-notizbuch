import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

/// Botão quadrado de "tocar áudio" (48 px, borda e sombra leve), igual ao
/// do rodapé das fichas.
class SpeakButton extends StatelessWidget {
  const SpeakButton({
    super.key,
    required this.onPressed,
    this.tooltip,
  });

  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Tooltip(
      message: tooltip ?? tr.playAudio,
      child: SizedBox(
        width: 48,
        height: 48,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: p.footer,
            foregroundColor: p.text700,
            side: BorderSide(color: p.outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0.5,
            shadowColor: Colors.black26,
          ),
          child: SvgPathIcon(AppIcons.volumeUp, size: 20, color: p.text700),
        ),
      ),
    );
  }
}
