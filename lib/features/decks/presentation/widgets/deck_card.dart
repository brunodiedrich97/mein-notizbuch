import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_strings.dart';
import '../../providers/deck_provider.dart';
import '../deck_icon_data.dart';

/// Quadrado claro com o ícone do deck.
class DeckIconBox extends StatelessWidget {
  const DeckIconBox({
    super.key,
    required this.icon,
    this.size = 36,
    this.selected = false,
  });

  final IconData icon;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected ? p.ink : p.softButton,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        icon,
        size: size * 0.55,
        color: selected ? p.onInk : p.text700,
      ),
    );
  }
}

/// Cartão de um deck na grade da tela inicial.
class DeckCard extends StatelessWidget {
  const DeckCard({super.key, required this.summary, required this.onTap});

  final DeckSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final deck = summary.deck;
    final count = summary.words.length;
    final radius = BorderRadius.circular(16);

    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: p.cardBorder),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DeckIconBox(icon: deck.icon.data),
              const SizedBox(height: 12),
              Text(
                deck.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.serif(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  color: p.text900,
                ),
              ),
              if (deck.nameDe != null && deck.nameDe!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    deck.nameDe!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: p.text500,
                    ),
                  ),
                ),
              const Spacer(),
              const SizedBox(height: 10),
              Text(
                tr.cardsCount(count),
                style: AppTheme.mono(fontSize: 11, color: p.text400),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Último cartão da grade: cria um deck.
class NewDeckCard extends StatelessWidget {
  const NewDeckCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final radius = BorderRadius.circular(16);
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: p.dots, width: 1.5),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 22, color: p.text500),
                const SizedBox(height: 6),
                Text(
                  tr.newDeck,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: p.text500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
