import '../../../core/language/study_language.dart';

/// Classes gramaticais do caderno.
///
/// O banco salva o NOME de cada valor (via `textEnum`), então reordenar
/// esta lista é seguro. Só não renomeie um valor existente sem migração.
enum GrammarCategory {
  /// Substantivo sem gênero (idiomas como o inglês).
  noun,
  masculineNoun,
  feminineNoun,
  neuterNoun,
  verb,
  adjective,
  adverb,
  preposition,
  other;

  bool get isNoun =>
      this == GrammarCategory.noun ||
      this == GrammarCategory.masculineNoun ||
      this == GrammarCategory.feminineNoun ||
      this == GrammarCategory.neuterNoun;

  /// Artigo definido do idioma de estudo, só para substantivos
  /// ("der", "die", "das" no alemão).
  String? get article => StudyLanguages.active.articleOf(this);

  /// Rótulo completo, usado no topo da ficha.
  String get label => switch (this) {
        GrammarCategory.noun => 'substantivo',
        GrammarCategory.masculineNoun => 'substantivo · masculino',
        GrammarCategory.feminineNoun => 'substantivo · feminino',
        GrammarCategory.neuterNoun => 'substantivo · neutro',
        GrammarCategory.verb => 'verbo',
        GrammarCategory.adjective => 'adjetivo',
        GrammarCategory.adverb => 'advérbio',
        GrammarCategory.preposition => 'preposição',
        GrammarCategory.other => 'outros',
      };

  /// Rótulo curto, usado nos seletores.
  String get shortLabel => switch (this) {
        GrammarCategory.noun => 'substantivo',
        GrammarCategory.masculineNoun => '${article ?? 'Subst.'} (Masc.)',
        GrammarCategory.feminineNoun => '${article ?? 'Subst.'} (Fem.)',
        GrammarCategory.neuterNoun => '${article ?? 'Subst.'} (Neutro)',
        GrammarCategory.verb => 'verbo',
        GrammarCategory.adjective => 'adjetivo',
        GrammarCategory.adverb => 'advérbio',
        GrammarCategory.preposition => 'preposição',
        GrammarCategory.other => 'outros',
      };

  /// Gênero pelo artigo, no idioma de estudo ("der" → masculino).
  static GrammarCategory? fromArticle(String article) =>
      StudyLanguages.active.categoryFromArticle(article);
}

/// Remove o artigo inicial: "der Hund" -> "Hund".
String stripArticle(String word) => StudyLanguages.active.stripArticle(word);
