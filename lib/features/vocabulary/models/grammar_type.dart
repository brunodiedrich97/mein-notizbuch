/// Classes gramaticais do caderno.
///
/// O banco salva o NOME de cada valor (via `textEnum`), então reordenar
/// esta lista é seguro. Só não renomeie um valor existente sem migração.
enum GrammarCategory {
  masculineNoun,
  feminineNoun,
  neuterNoun,
  verb,
  adjective,
  adverb,
  preposition,
  other;

  bool get isNoun =>
      this == GrammarCategory.masculineNoun ||
      this == GrammarCategory.feminineNoun ||
      this == GrammarCategory.neuterNoun;

  /// Artigo definido no nominativo singular, só para substantivos.
  String? get article => switch (this) {
        GrammarCategory.masculineNoun => 'der',
        GrammarCategory.feminineNoun => 'die',
        GrammarCategory.neuterNoun => 'das',
        _ => null,
      };

  /// Rótulo completo, usado no topo da ficha.
  String get label => switch (this) {
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
        GrammarCategory.masculineNoun => 'der',
        GrammarCategory.feminineNoun => 'die',
        GrammarCategory.neuterNoun => 'das',
        GrammarCategory.verb => 'verbo',
        GrammarCategory.adjective => 'adjetivo',
        GrammarCategory.adverb => 'advérbio',
        GrammarCategory.preposition => 'preposição',
        GrammarCategory.other => 'outros',
      };

  static GrammarCategory? fromArticle(String article) =>
      switch (article.toLowerCase()) {
        'der' => GrammarCategory.masculineNoun,
        'die' => GrammarCategory.feminineNoun,
        'das' => GrammarCategory.neuterNoun,
        _ => null,
      };
}

/// Remove o artigo inicial: "der Hund" -> "Hund".
String stripArticle(String word) {
  final parts = word.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2 && GrammarCategory.fromArticle(parts.first) != null) {
    return parts.sublist(1).join(' ');
  }
  return word.trim();
}
