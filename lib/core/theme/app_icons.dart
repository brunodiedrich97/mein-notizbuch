import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../features/vocabulary/models/grammar_type.dart';

/// Ícones SVG copiados do protótipo (viewBox 24×24).
class AppIcons {
  AppIcons._();

  static const _nounMasc =
      'M12 8.5C12 9.88 10.88 11 9.5 11S7 9.88 7 8.5 8.12 6 9.5 6s2.5 1.12 2.5 2.5zm5 0c0 1.38-1.12 2.5-2.5 2.5S12 9.88 12 8.5 13.12 6 14.5 6s2.5 1.12 2.5 2.5zM4 14.5c0 1.93 1.57 3.5 3.5 3.5.76 0 1.47-.25 2.05-.66C10.23 18.21 11.08 19 12 19s1.77-.79 2.45-1.66c.58.41 1.29.66 2.05.66 1.93 0 3.5-1.57 3.5-3.5 0-2.45-2.26-4.5-5.5-4.5h-5C6.26 10 4 12.05 4 14.5z';
  static const _nounFem =
      'M9 21c0 .55.45 1 1 1h4c.55 0 1-.45 1-1v-1H9v1zm3-19C8.14 2 5 5.14 5 9c0 2.38 1.19 4.47 3 5.74V17c0 .55.45 1 1 1h6c.55 0 1-.45 1-1v-2.26c1.81-1.27 3-3.36 3-5.74 0-3.86-3.14-7-7-7z';
  static const _nounNeut =
      'M18 2H6c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zM6 4h5v8l-2.5-1.5L6 12V4z';
  static const _verb =
      'M13.5 5.5c1.1 0 2-.9 2-2s-.9-2-2-2-2 .9-2 2 .9 2 2 2zM9.8 8.9L7 23h2.1l1.8-8 2.1 2v6h2v-7.5l-2.1-2 .6-3C14.8 12 16.8 13 19 13v-2c-1.9 0-3.5-1-4.3-2.4l-1-1.6c-.4-.6-1-1-1.7-1-.3 0-.5.1-.8.1L6 8.3V13h2V9.6l1.8-.7';
  static const _adjective =
      'M12 7c-2.76 0-5 2.24-5 5s2.24 5 5 5 5-2.24 5-5-2.24-5-5-5zM2 13h2c.55 0 1-.45 1-1s-.45-1-1-1H2c-.55 0-1 .45-1 1s.45 1 1 1zm18 0h2c.55 0 1-.45 1-1s-.45-1-1-1h-2c-.55 0-1 .45-1 1s.45 1 1 1zM11 2v2c0 .55.45 1 1 1s1-.45 1-1V2c0-.55-.45-1-1-1s-1 .45-1 1zm0 18v2c0 .55.45 1 1 1s1-.45 1-1v-2c0-.55-.45-1-1-1s-1 .45-1 1z';
  static const _preposition =
      'M3.9 12c0-1.71 1.39-3.1 3.1-3.1h4V7H7c-2.76 0-5 2.24-5 5s2.24 5 5 5h4v-1.9H7c-1.71 0-3.1-1.39-3.1-3.1zM8 13h8v-2H8v2zm9-6h-4v1.9h4c1.71 0 3.1 1.39 3.1 3.1s-1.39 3.1-3.1 3.1h-4V17h4c2.76 0 5-2.24 5-5s-2.24-5-5-5z';

  static const volumeUp =
      'M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z';
  static const volumeDown =
      'M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02z';
  static const chevronLeft = 'M15 19l-7-7 7-7';
  static const chevronRight = 'M9 5l7 7-7 7';

  /// Caminho do ícone da classe, ou `null` para as classes sem ícone no
  /// protótipo (advérbio e outros), que usam um ícone Material.
  static String? categoryPath(GrammarCategory c) => switch (c) {
        GrammarCategory.noun => _nounNeut,
        GrammarCategory.masculineNoun => _nounMasc,
        GrammarCategory.feminineNoun => _nounFem,
        GrammarCategory.neuterNoun => _nounNeut,
        GrammarCategory.verb => _verb,
        GrammarCategory.adjective => _adjective,
        GrammarCategory.preposition => _preposition,
        _ => null,
      };
}

/// Ícone preenchido a partir de um caminho SVG.
class SvgPathIcon extends StatelessWidget {
  const SvgPathIcon(this.path, {super.key, this.size = 20, required this.color});

  final String path;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
      '<path d="$path"/></svg>',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

/// Chevron de traço (stroke-width 2.2), como nos botões do rodapé.
class ChevronIcon extends StatelessWidget {
  const ChevronIcon.left({super.key, required this.color, this.size = 16})
      : path = AppIcons.chevronLeft;
  const ChevronIcon.right({super.key, required this.color, this.size = 16})
      : path = AppIcons.chevronRight;

  final String path;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
      'stroke="#000" stroke-width="2.2" stroke-linecap="round" '
      'stroke-linejoin="round"><path d="$path"/></svg>',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

/// Ícone da classe gramatical, com a opacidade do protótipo.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon(this.category, {super.key, required this.color, this.size = 16});

  final GrammarCategory category;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final path = AppIcons.categoryPath(category);
    final opacity = category == GrammarCategory.preposition ? 0.8 : 0.9;
    final tinted = color.withValues(alpha: opacity);
    if (path != null) return SvgPathIcon(path, size: size, color: tinted);
    return Icon(
      category == GrammarCategory.adverb ? Icons.speed : Icons.more_horiz,
      size: size,
      color: tinted,
    );
  }
}
