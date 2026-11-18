import '../../features/vocabulary/models/grammar_type.dart';

/// Termos exibidos no idioma de estudo, para reforçar o idioma (ex.: o
/// "(Wortart)" ao lado de "Classe gramatical").
class LanguageTerms {
  const LanguageTerms({
    required this.wordClass,
    required this.pronunciation,
    required this.example,
    required this.goodMorning,
    required this.goodDay,
    required this.goodEvening,
    required this.excellent,
    required this.wellDone,
    required this.keepGoing,
    required this.sampleWord,
    required this.generalDeck,
  });

  /// "Wortart" (classe gramatical).
  final String wordClass;

  /// "Aussprache" (pronúncia).
  final String pronunciation;

  /// "Beispielsatz" (frase de exemplo).
  final String example;

  /// Saudações da tela inicial: manhã, tarde e noite.
  final String goodMorning;
  final String goodDay;
  final String goodEvening;

  /// Fim de sessão: excelente, bom resultado e "continue assim".
  final String excellent;
  final String wellDone;
  final String keepGoing;

  /// Palavra de exemplo na prévia de cores ("Wort").
  final String sampleWord;

  /// Nome do deck padrão no idioma ("Allgemein").
  final String generalDeck;
}

/// Tudo o que o app precisa saber sobre um idioma de estudo: artigos e
/// gêneros, regras do reconhecimento automático, voz, teclas especiais,
/// regras da correção da escrita e termos exibidos.
///
/// Por enquanto só existe o alemão ([german]). Para um idioma novo, basta
/// criar outro perfil e registrá-lo em [StudyLanguages].
class StudyLanguageProfile {
  const StudyLanguageProfile({
    required this.code,
    required this.namePt,
    required this.nameNative,
    required this.ttsLocale,
    required this.categories,
    required this.articles,
    required this.pluralArticles,
    required this.capitalizeNouns,
    required this.verbPattern,
    required this.specialLetters,
    required this.articleForms,
    required this.contractions,
    required this.terms,
    required this.wordHint,
    required this.pluralHint,
    required this.verbFormsHint,
    required this.conjugationHint,
    required this.degreesHint,
    required this.ipaHint,
    required this.exampleHint,
    required this.deckNameHint,
    required this.approximationHints,
    required this.tipHints,
  });

  /// Código guardado no banco ("de").
  final String code;

  /// Nome em português, minúsculo: "alemão" ("Palavra em alemão").
  final String namePt;

  /// Nome no próprio idioma: "Deutsch".
  final String nameNative;

  /// Voz do aparelho para a pronúncia ("de-DE").
  final String ttsLocale;

  /// Classes gramaticais do idioma, na ordem dos seletores.
  final List<GrammarCategory> categories;

  /// Artigo definido de cada gênero (nominativo singular). Vazio em
  /// idiomas sem gênero, como o inglês.
  final Map<GrammarCategory, String> articles;

  /// O idioma marca o gênero dos substantivos pelo artigo?
  bool get hasGender => articles.isNotEmpty;

  /// Artigos que também são do plural (o gênero pode estar errado).
  final Set<String> pluralArticles;

  /// Substantivos sempre com maiúscula (alemão).
  final bool capitalizeNouns;

  /// Padrão de verbo no infinitivo, para sugerir a classe.
  final String verbPattern;

  /// Teclas extras do campo de escrita (ä, ö, ü…).
  final List<String> specialLetters;

  /// Todas as formas de artigo (para as notas da correção).
  final Set<String> articleForms;

  /// Contrações de preposição + artigo: "zum" = ("zu", "dem").
  final Map<String, (String, String)> contractions;

  final LanguageTerms terms;

  // Exemplos nos campos de cadastro.
  final String wordHint;
  final String pluralHint;
  final String verbFormsHint;
  final String conjugationHint;
  final String degreesHint;
  final String ipaHint;
  final String exampleHint;
  final String deckNameHint;

  /// Aproximação da pronúncia escrita para quem fala cada idioma nativo
  /// ("pt" → "GUÊ-en").
  final Map<String, String> approximationHints;

  /// Dica fonética de exemplo, no idioma nativo.
  final Map<String, String> tipHints;

  String approximationHintFor(String native) =>
      approximationHints[native] ?? approximationHints['pt'] ?? '';

  String tipHintFor(String native) =>
      tipHints[native] ?? tipHints['pt'] ?? '';

  String? articleOf(GrammarCategory c) => articles[c];

  /// Gênero pelo artigo digitado ("der" → masculino).
  GrammarCategory? categoryFromArticle(String article) {
    final a = article.toLowerCase();
    for (final e in articles.entries) {
      if (e.value == a) return e.key;
    }
    return null;
  }

  /// Remove o artigo inicial: "der Hund" → "Hund".
  String stripArticle(String word) {
    final parts = word.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && categoryFromArticle(parts.first) != null) {
      return parts.sublist(1).join(' ');
    }
    return word.trim();
  }
}

const StudyLanguageProfile german = StudyLanguageProfile(
  code: 'de',
  namePt: 'alemão',
  nameNative: 'Deutsch',
  ttsLocale: 'de-DE',
  categories: [
    GrammarCategory.masculineNoun,
    GrammarCategory.feminineNoun,
    GrammarCategory.neuterNoun,
    GrammarCategory.verb,
    GrammarCategory.adjective,
    GrammarCategory.adverb,
    GrammarCategory.preposition,
    GrammarCategory.other,
  ],
  articles: {
    GrammarCategory.masculineNoun: 'der',
    GrammarCategory.feminineNoun: 'die',
    GrammarCategory.neuterNoun: 'das',
  },
  pluralArticles: {'die'},
  capitalizeNouns: true,
  // Infinitivos terminam em -en, -eln ou -ern ("gehen", "sammeln",
  // "wandern"). Exigir 2+ letras antes evita falsos positivos como "gern".
  verbPattern: r'^[a-zäöüß]{2,}(en|eln|ern)$',
  specialLetters: ['ä', 'ö', 'ü', 'ß', 'Ä', 'Ö', 'Ü'],
  articleForms: {
    'der', 'die', 'das', 'den', 'dem', 'des', //
    'ein', 'eine', 'einen', 'einem', 'einer', 'eines',
  },
  contractions: {
    'zum': ('zu', 'dem'),
    'zur': ('zu', 'der'),
    'im': ('in', 'dem'),
    'ins': ('in', 'das'),
    'am': ('an', 'dem'),
    'ans': ('an', 'das'),
    'vom': ('von', 'dem'),
    'beim': ('bei', 'dem'),
  },
  terms: LanguageTerms(
    wordClass: 'Wortart',
    pronunciation: 'Aussprache',
    example: 'Beispielsatz',
    goodMorning: 'Guten Morgen!',
    goodDay: 'Guten Tag!',
    goodEvening: 'Guten Abend!',
    excellent: 'Ausgezeichnet!',
    wellDone: 'Gut gemacht!',
    keepGoing: 'Weiter so!',
    sampleWord: 'Wort',
    generalDeck: 'Allgemein',
  ),
  wordHint: 'der Hund, gehen, schön…',
  pluralHint: 'die Hunde',
  verbFormsHint: 'ging · ist gegangen',
  conjugationHint:
      'ich gehe · du gehst · er geht\nwir gehen · ihr geht · sie gehen',
  degreesHint: 'schön → schöner → am schönsten',
  ipaHint: 'ˈɡeːən',
  exampleHint: 'Der Hund schläft im Garten.',
  deckNameHint: 'Gesundheit',
  approximationHints: {'pt': 'GUÊ-en', 'en': 'GAY-un', 'es': 'GUE-en'},
  tipHints: {
    'pt': 'O g é sempre duro, como em "gato".',
    'en': 'The g is always hard, as in "go".',
    'es': 'La g suena siempre como en "gato", también antes de e.',
  },
);

const StudyLanguageProfile english = StudyLanguageProfile(
  code: 'en',
  namePt: 'inglês',
  nameNative: 'English',
  ttsLocale: 'en-US',
  // Sem gênero: um único "substantivo", sem artigo que indique a classe.
  categories: [
    GrammarCategory.noun,
    GrammarCategory.verb,
    GrammarCategory.adjective,
    GrammarCategory.adverb,
    GrammarCategory.preposition,
    GrammarCategory.other,
  ],
  articles: {},
  pluralArticles: {},
  capitalizeNouns: false,
  // Verbo digitado no infinitivo com "to": "to go", "to read".
  verbPattern: r'^to\s+[a-z]',
  specialLetters: [],
  articleForms: {'the', 'a', 'an'},
  contractions: {},
  terms: LanguageTerms(
    wordClass: 'Part of speech',
    pronunciation: 'Pronunciation',
    example: 'Example sentence',
    goodMorning: 'Good morning!',
    goodDay: 'Good afternoon!',
    goodEvening: 'Good evening!',
    excellent: 'Excellent!',
    wellDone: 'Well done!',
    keepGoing: 'Keep going!',
    sampleWord: 'Word',
    generalDeck: 'General',
  ),
  wordHint: 'dog, to go, beautiful…',
  pluralHint: 'dogs',
  verbFormsHint: 'went · gone',
  conjugationHint: 'I go · you go · he goes\nwe go · you go · they go',
  degreesHint: 'big → bigger → the biggest',
  ipaHint: 'ɡoʊ',
  exampleHint: 'The dog sleeps in the garden.',
  deckNameHint: 'Health',
  approximationHints: {'pt': 'GÔU', 'en': 'GOH', 'es': 'GÓU'},
  tipHints: {
    'pt': 'O o desliza para um u: "ôu".',
    'en': 'The o glides into a u: "oh-oo".',
    'es': 'La o se desliza hacia una u: "óu".',
  },
);

/// Idiomas de estudo disponíveis e o ativo.
class StudyLanguages {
  StudyLanguages._();

  static const List<StudyLanguageProfile> all = [german, english];

  static StudyLanguageProfile _active = german;

  /// Idioma de estudo atual, escolhido em Ajustes (padrão: alemão).
  static StudyLanguageProfile get active => _active;

  static void setActive(String code) {
    _active = all.firstWhere((l) => l.code == code, orElse: () => german);
  }
}
