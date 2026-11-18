import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

/// Cabeçalho das telas internas: voltar (círculo), sobretítulo com ponto,
/// título e uma ação opcional à direita. Fica sobre uma linha divisória.
class ScreenHeader extends StatelessWidget implements PreferredSizeWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.onBack,
    this.trailing,
  });

  final String title;
  final String? eyebrow;

  /// Padrão: fecha a tela atual.
  final VoidCallback? onBack;
  final Widget? trailing;

  static const double height = 72;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return Container(
      decoration: BoxDecoration(
        color: p.page,
        border: Border(bottom: BorderSide(color: p.divider)),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Tooltip(
                      message: tr.back,
                      child: Material(
                        color: p.card,
                        shape: CircleBorder(side: BorderSide(color: p.outline)),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onBack ??
                              () => Navigator.of(context).maybePop(),
                          child: SizedBox(
                            width: 40,
                            height: 40,
                            child: Center(
                              child:
                                  ChevronIcon.left(color: p.text500, size: 18),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  eyebrow ?? tr.screenEyebrow,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 14 / 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                    color: p.text500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              height: 16 / 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                              color: p.text600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 12),
                      trailing!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botão de ação do cabeçalho: ícone + texto curto, com borda (ex.: "TTS").
class HeaderActionButton extends StatelessWidget {
  const HeaderActionButton({
    super.key,
    required this.iconPath,
    required this.label,
    required this.onTap,
    this.tooltip,
  });

  /// Caminho SVG, como os de [AppIcons].
  final String iconPath;
  final String label;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final button = Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: p.outline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPathIcon(iconPath, size: 18, color: p.text700),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: p.text700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
