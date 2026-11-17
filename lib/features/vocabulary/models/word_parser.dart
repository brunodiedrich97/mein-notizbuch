import 'grammar_type.dart';

/// Resultado da análise do que o usuário digitou no campo em alemão.
class ParsedWord {
  const ParsedWord({
    required this.lemma,
    required this.display,
    required this.category,
    required this.isGuess,
    this.articleIsAmbiguous = false,
  });

  /// Palavra sem artigo ("Hund").
  final String lemma;

  /// Forma de exibição ("der Hund").
  final String display;

  /// Classe sugerida.
  final GrammarCategory category;

  /// `true` quando a classe é só um palpite (sem artigo digitado).
  final bool isGuess;

  /// "die" também é o artigo do plural, então o gênero pode estar errado.
  final bool articleIsAmbiguous;
}

class WordParser {
  WordParser._();

  // Infinitivos alemães terminam em -en, -eln ou -ern ("gehen", "sammeln",
  // "wandern"). Exigir 2+ letras antes evita falsos positivos como "gern".
  static final RegExp _verbPattern = RegExp(r'^[a-zäöüß]{2,}(en|eln|ern)$');

  /// Reconhece o gênero quando o usuário digita "der Hund", "die Lampe" ou
  /// "das Buch". Sem artigo, sugere verbo para infinitivos e "outros" para o
  /// resto. A sugestão é sempre editável na tela de cadastro.
  static ParsedWord parse(String raw) {
    final normalized = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) {
      return const ParsedWord(
        lemma: '',
        display: '',
        category: GrammarCategory.other,
        isGuess: true,
      );
    }

    final space = normalized.indexOf(' ');
    if (space > 0) {
      final article = normalized.substring(0, space).toLowerCase();
      final category = GrammarCategory.fromArticle(article);
      if (category != null) {
        final noun = _capitalize(normalized.substring(space + 1));
        return ParsedWord(
          lemma: noun,
          display: '$article $noun',
          category: category,
          isGuess: false,
          articleIsAmbiguous: article == 'die',
        );
      }
    }

    final looksLikeVerb = _verbPattern.hasMatch(normalized);
    return ParsedWord(
      lemma: normalized,
      display: normalized,
      category: looksLikeVerb ? GrammarCategory.verb : GrammarCategory.other,
      isGuess: true,
    );
  }

  // Substantivos alemães sempre começam com maiúscula.
  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
