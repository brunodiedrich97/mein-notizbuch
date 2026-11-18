import '../../../core/language/study_language.dart';
import '../../../l10n/app_strings.dart';

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
        GrammarCategory.noun => tr.catNoun,
        GrammarCategory.masculineNoun => tr.catMasculineNoun,
        GrammarCategory.feminineNoun => tr.catFeminineNoun,
        GrammarCategory.neuterNoun => tr.catNeuterNoun,
        GrammarCategory.verb => tr.catVerb,
        GrammarCategory.adjective => tr.catAdjective,
        GrammarCategory.adverb => tr.catAdverb,
        GrammarCategory.preposition => tr.catPreposition,
        GrammarCategory.other => tr.catOther,
      };

  /// Rótulo curto, usado nos seletores.
  String get shortLabel => switch (this) {
        GrammarCategory.noun => tr.catNoun,
        GrammarCategory.masculineNoun =>
          '${article ?? tr.catNounShort} (${tr.genderMascShort})',
        GrammarCategory.feminineNoun =>
          '${article ?? tr.catNounShort} (${tr.genderFemShort})',
        GrammarCategory.neuterNoun =>
          '${article ?? tr.catNounShort} (${tr.genderNeutShort})',
        GrammarCategory.verb => tr.catVerb,
        GrammarCategory.adjective => tr.catAdjective,
        GrammarCategory.adverb => tr.catAdverb,
        GrammarCategory.preposition => tr.catPreposition,
        GrammarCategory.other => tr.catOther,
      };

  /// Gênero pelo artigo, no idioma de estudo ("der" → masculino).
  static GrammarCategory? fromArticle(String article) =>
      StudyLanguages.active.categoryFromArticle(article);
}

/// Remove o artigo inicial: "der Hund" -> "Hund".
String stripArticle(String word) => StudyLanguages.active.stripArticle(word);
