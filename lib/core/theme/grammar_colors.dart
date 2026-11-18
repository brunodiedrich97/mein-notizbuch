import 'package:flutter/material.dart';

import '../../features/vocabulary/models/grammar_type.dart';

/// Cores do método, copiadas do `tailwind.config` do protótipo.
///
/// Advérbio e "outros" não existem no protótipo; usam tons no mesmo
/// registro sóbrio das demais classes.
class GrammarColors {
  GrammarColors._();

  // ---------- Papel claro (valores do protótipo) ----------
  /// Substantivo sem gênero (inglês): um azul-petróleo, distinto do azul
  /// do masculino.
  static const Color noun = Color(0xFF0E7490);
  static const Color masculine = Color(0xFF1D5FA7);
  static const Color feminine = Color(0xFFA82E2E);
  static const Color neuter = Color(0xFF366B1A);
  static const Color verb = Color(0xFF9E4318);
  static const Color adjective = Color(0xFF5243AA);
  static const Color preposition = Color(0xFF4A4A4A);
  static const Color prepositionTitle = Color(0xFF444444); // título de "mit"
  static const Color adverb = Color(0xFF9B2F6B);
  static const Color other = Color(0xFF4B5563);

  // ---------- Modo escuro (mesmas famílias, mais claras) ----------
  static const Color nounDark = Color(0xFF6CC7DA);
  static const Color masculineDark = Color(0xFF7CB0EC);
  static const Color feminineDark = Color(0xFFF08A8A);
  static const Color neuterDark = Color(0xFF8DCB6B);
  static const Color verbDark = Color(0xFFF0A070);
  static const Color adjectiveDark = Color(0xFFA99CF0);
  static const Color prepositionDark = Color(0xFFBDBDBD);
  static const Color adverbDark = Color(0xFFE88BBE);
  static const Color otherDark = Color(0xFF9CA3AF);

  // ---------- Fundos ----------
  static const Color paperBgLight = Color(0xFFFCFBF9);
  static const Color paperBorderLight = Color(0xFFEDEBE8);
  static const Color paperBgDark = Color(0xFF191816);
  static const Color paperCardDark = Color(0xFF232220);

  /// Ponto do título (emerald-500).
  static const Color brandDot = Color(0xFF10B981);

  static Color of(GrammarCategory category, {required bool isDark}) {
    return switch (category) {
      GrammarCategory.noun => isDark ? nounDark : noun,
      GrammarCategory.masculineNoun => isDark ? masculineDark : masculine,
      GrammarCategory.feminineNoun => isDark ? feminineDark : feminine,
      GrammarCategory.neuterNoun => isDark ? neuterDark : neuter,
      GrammarCategory.verb => isDark ? verbDark : verb,
      GrammarCategory.adjective => isDark ? adjectiveDark : adjective,
      GrammarCategory.adverb => isDark ? adverbDark : adverb,
      GrammarCategory.preposition => isDark ? prepositionDark : preposition,
      GrammarCategory.other => isDark ? otherDark : other,
    };
  }

  /// Cor da palavra grande. Só a preposição difere do rótulo (#444).
  static Color titleOf(GrammarCategory category, {required bool isDark}) {
    if (category == GrammarCategory.preposition && !isDark) {
      return prepositionTitle;
    }
    return of(category, isDark: isDark);
  }

  /// Cor do texto sobre um fundo preenchido com [of].
  static Color onCategory({required bool isDark}) =>
      isDark ? const Color(0xFF1A1A1A) : Colors.white;
}

/// Cores de um chip de filtro (classes do protótipo: texto 800, borda 100).
class ChipColors {
  const ChipColors(this.text, this.border);
  final Color text;
  final Color border;

  static const neutral = ChipColors(Color(0xFF374151), Color(0xFFE5E7EB));
  static const der = ChipColors(Color(0xFF1E40AF), Color(0xFFDBEAFE)); // blue
  static const die = ChipColors(Color(0xFF9F1239), Color(0xFFFFE4E6)); // rose
  static const das = ChipColors(Color(0xFF065F46), Color(0xFFD1FAE5)); // emerald
  static const verb = ChipColors(Color(0xFF92400E), Color(0xFFFEF3C7)); // amber
  static const adjective =
      ChipColors(Color(0xFF6B21A8), Color(0xFFF3E8FF)); // purple
  static const preposition =
      ChipColors(Color(0xFF44403C), Color(0xFFE7E5E4)); // stone-700 / stone-200

  static const neutralDark = ChipColors(Color(0xFFD1D5DB), Color(0x33FFFFFF));
  static const derDark = ChipColors(Color(0xFF93C5FD), Color(0x5593C5FD));
  static const dieDark = ChipColors(Color(0xFFFDA4AF), Color(0x55FDA4AF));
  static const dasDark = ChipColors(Color(0xFF6EE7B7), Color(0x556EE7B7));
  static const verbDark = ChipColors(Color(0xFFFCD34D), Color(0x55FCD34D));
  static const adjectiveDark =
      ChipColors(Color(0xFFD8B4FE), Color(0x55D8B4FE));
  static const prepositionDark =
      ChipColors(Color(0xFFD6D3D1), Color(0x55D6D3D1));
}
