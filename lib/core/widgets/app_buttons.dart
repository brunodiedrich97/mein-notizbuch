import 'package:flutter/material.dart';

import '../theme/app_icons.dart';
import '../theme/app_text.dart';
import '../theme/app_theme.dart';

const Size _buttonSize = Size.fromHeight(44);
final OutlinedBorder _buttonShape =
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

/// Botão principal escuro, como "Próximo" e "Sabia".
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.chevron = false,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Mostra "›" depois do texto.
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: _buttonSize,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        backgroundColor: p.ink,
        foregroundColor: p.onInk,
        textStyle: AppText.button,
        shape: _buttonShape,
        elevation: 1, // shadow-sm
        shadowColor: Colors.black26,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
          if (chevron) ...[
            const SizedBox(width: 6),
            ChevronIcon.right(
              color: onPressed == null ? p.text400 : p.onInk,
            ),
          ],
        ],
      ),
    );
  }
}

/// Botão secundário cinza claro, como "Anterior" e "Ainda não".
class SoftButton extends StatelessWidget {
  const SoftButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: _buttonSize,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        backgroundColor: p.softButton,
        foregroundColor: p.text700,
        textStyle: AppText.button,
        shape: _buttonShape,
      ),
      child: Text(label, overflow: TextOverflow.ellipsis),
    );
  }
}

/// Botão quadrado de 40 px com borda, para o lado direito do cabeçalho.
class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: p.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: p.outline),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: p.text700),
          ),
        ),
      ),
    );
  }
}

/// Folha inferior padrão do app: fundo do cartão, cantos de 22 px e a
/// "alça" no topo. O conteúdo rola e sobe junto com o teclado.
Future<T?> showAppSheet<T>(BuildContext context, WidgetBuilder builder) {
  final p = AppPalette.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: p.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppPalette.of(ctx).dots,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              builder(ctx),
            ],
          ),
        ),
      ),
    ),
  );
}
