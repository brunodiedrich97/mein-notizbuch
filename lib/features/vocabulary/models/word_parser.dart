import '../../../core/language/study_language.dart';
import 'grammar_type.dart';

/// Resultado da análise do que o usuário digitou no campo da palavra.
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

  /// O artigo também é do plural ("die" no alemão), então o gênero pode
  /// estar errado.
  final bool articleIsAmbiguous;
}

class WordParser {
  WordParser._();

  /// Reconhece o gênero quando o usuário digita o artigo ("der Hund",
  /// "die Lampe", "das Buch" no alemão). Sem artigo, sugere verbo para
  /// infinitivos e "outros" para o resto, pelas regras do idioma de estudo.
  /// A sugestão é sempre editável na tela de cadastro.
  static ParsedWord parse(String raw) {
    final language = StudyLanguages.active;
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
        final rest = normalized.substring(space + 1);
        final noun = language.capitalizeNouns ? _capitalize(rest) : rest;
        return ParsedWord(
          lemma: noun,
          display: '$article $noun',
          category: category,
          isGuess: false,
          articleIsAmbiguous: language.pluralArticles.contains(article),
        );
      }
    }

    // Idiomas sem gênero: "the dog" / "a dog" indica substantivo.
    if (!language.hasGender && space > 0) {
      final first = normalized.substring(0, space).toLowerCase();
      if (language.articleForms.contains(first)) {
        final noun = normalized.substring(space + 1);
        return ParsedWord(
          lemma: noun,
          display: noun,
          category: GrammarCategory.noun,
          isGuess: false,
        );
      }
    }

    final looksLikeVerb = RegExp(language.verbPattern).hasMatch(normalized);
    return ParsedWord(
      lemma: normalized,
      display: normalized,
      category: looksLikeVerb ? GrammarCategory.verb : GrammarCategory.other,
      isGuess: true,
    );
  }

  // Usado quando o idioma escreve substantivos com maiúscula (alemão).
  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
