/// O idioma nativo do usuário: em que língua ele escreve as traduções, a
/// aproximação da pronúncia e as dicas. A interface continua em português
/// por enquanto.
class NativeLanguageProfile {
  const NativeLanguageProfile({
    required this.code,
    required this.nameNative,
    required this.tag,
    required this.generalDeckName,
    required this.translationHint,
    required this.exampleTranslationHint,
    required this.deckNameHint,
  });

  /// Código ("pt", "en", "es").
  final String code;


  /// Nome no próprio idioma: "Español".
  final String nameNative;

  /// Sigla curta dos rótulos: "Aproximação ES".
  final String tag;

  /// Nome do deck padrão criado neste idioma ("Geral").
  final String generalDeckName;

  // Exemplos nos campos de cadastro.
  final String translationHint;
  final String exampleTranslationHint;
  final String deckNameHint;
}

const NativeLanguageProfile portuguese = NativeLanguageProfile(
  code: 'pt',
  nameNative: 'Português',
  tag: 'PT',
  generalDeckName: 'Geral',
  translationHint: 'o cachorro',
  exampleTranslationHint: 'O cachorro dorme no jardim.',
  deckNameHint: 'Saúde',
);

const NativeLanguageProfile englishNative = NativeLanguageProfile(
  code: 'en',
  nameNative: 'English',
  tag: 'EN',
  generalDeckName: 'General',
  translationHint: 'the dog',
  exampleTranslationHint: 'The dog sleeps in the garden.',
  deckNameHint: 'Health',
);

const NativeLanguageProfile spanish = NativeLanguageProfile(
  code: 'es',
  nameNative: 'Español',
  tag: 'ES',
  generalDeckName: 'General',
  translationHint: 'el perro',
  exampleTranslationHint: 'El perro duerme en el jardín.',
  deckNameHint: 'Salud',
);

/// Idiomas nativos disponíveis e o ativo.
class NativeLanguages {
  NativeLanguages._();

  static const List<NativeLanguageProfile> all = [
    portuguese,
    englishNative,
    spanish,
  ];

  static NativeLanguageProfile _active = portuguese;

  static NativeLanguageProfile get active => _active;

  static NativeLanguageProfile byCode(String code) =>
      all.firstWhere((l) => l.code == code, orElse: () => portuguese);

  static void setActive(String code) => _active = byCode(code);
}
