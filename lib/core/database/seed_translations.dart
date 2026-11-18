import 'package:drift/drift.dart';

import 'app_database.dart';

/// Textos de uma ficha inicial num idioma nativo. Os campos nulos ficam
/// como na versão em português.
class SeedText {
  const SeedText(
    this.translation, {
    this.approximation,
    this.tip,
    this.example,
    this.tagDetail,
    this.prepositionCase,
  });

  final String translation;
  final String? approximation;
  final String? tip;
  final String? example;
  final String? tagDetail;
  final String? prepositionCase;
}

/// Fichas iniciais (escritas em português) com a tradução, a aproximação e
/// as dicas no idioma nativo [native]. Em português, nada muda.
List<WordEntriesCompanion> localizeSeeds(
  List<WordEntriesCompanion> seeds,
  String native,
) {
  final texts = _seedTexts[native];
  if (texts == null) return seeds;
  return [
    for (final w in seeds)
      switch (texts[w.germanWord.value]) {
        null => w,
        final SeedText t => w.copyWith(
            portugueseTranslation: Value(t.translation),
            brazilianApproximation: t.approximation == null
                ? w.brazilianApproximation
                : Value(t.approximation),
            phoneticTip: t.tip == null ? w.phoneticTip : Value(t.tip),
            examplePortuguese:
                t.example == null ? w.examplePortuguese : Value(t.example),
            tagDetail: t.tagDetail == null ? w.tagDetail : Value(t.tagDetail),
            prepositionCase: t.prepositionCase == null
                ? w.prepositionCase
                : Value(t.prepositionCase),
          ),
      },
  ];
}

/// Por idioma nativo, pela palavra da ficha.
const Map<String, Map<String, SeedText>> _seedTexts = {
  'en': {
    // Alemão
    'der Hund': SeedText(
      'the dog',
      approximation: 'dair HOONT',
      tip: 'The h is breathy, like a sigh. The d at the end sounds like t.',
      example: 'The dog sleeps in the garden.',
    ),
    'die Lampe': SeedText(
      'the lamp',
      approximation: 'dee LAHM-puh',
      tip: 'The a is open, as in "father", and the final -e is a weak "uh".',
      example: 'The lamp is on the table.',
    ),
    'das Buch': SeedText(
      'the book',
      approximation: 'dahs BOOKH',
      tip: 'The ch after u is scraped at the back of the throat, as in '
          'Scottish "loch".',
      example: "I'm reading a book.",
    ),
    'gehen': SeedText(
      'to go (on foot)',
      approximation: 'GAY-un',
      tip: 'The g is always hard, as in "go", and the h in the middle is '
          'silent.',
    ),
    'schön': SeedText(
      'beautiful, nice',
      approximation: 'SHURN',
      tip: 'For ö, say "ay" with your lips rounded as for "oh".',
      example: 'The weather is nice.',
    ),
    'gern': SeedText(
      'gladly, with pleasure',
      approximation: 'GAIRN',
      tip: 'The r before a consonant almost disappears into a light "a".',
      example: 'I like drinking coffee.',
    ),
    'mit': SeedText(
      'with',
      approximation: 'MIT',
      tip: 'A short i, as in "bit".',
      tagDetail: 'dative',
      prepositionCase:
          'always with the dative: aus · bei · mit · nach · seit · von · zu',
      example: "I'm going by bus.",
    ),
    'und': SeedText(
      'and',
      approximation: 'OONT',
      tip: 'As in "Hund": a d at the end of a word sounds like t.',
      example: 'bread and butter',
    ),
  },
  'es': {
    // Alemão
    'der Hund': SeedText(
      'el perro',
      approximation: 'der JUNT',
      tip: 'La h es aspirada, como un suspiro suave. La d final suena '
          'como t.',
      example: 'El perro duerme en el jardín.',
    ),
    'die Lampe': SeedText(
      'la lámpara',
      approximation: 'di LAM-pe',
      tip: 'La a es abierta como en español y la -e final es muy débil.',
      example: 'La lámpara está sobre la mesa.',
    ),
    'das Buch': SeedText(
      'el libro',
      approximation: 'das BUJ',
      tip: 'La ch después de u suena como la j de "jamón".',
      example: 'Leo un libro.',
    ),
    'gehen': SeedText(
      'ir (a pie)',
      approximation: 'GUE-en',
      tip: 'La g suena siempre como en "gato", también antes de e, y la h '
          'del medio es muda.',
    ),
    'schön': SeedText(
      'bonito, bello',
      approximation: 'SHÖÖN',
      tip: 'Para la ö, di "e" con los labios redondeados como para "o".',
      example: 'Hace buen tiempo.',
    ),
    'gern': SeedText(
      'con gusto',
      approximation: 'GUERN',
      tip: 'La r antes de consonante casi desaparece y suena como una "a" '
          'suave.',
      example: 'Me gusta tomar café.',
    ),
    'mit': SeedText(
      'con',
      approximation: 'MIT',
      tip: 'La i es corta y un poco más abierta que la española.',
      prepositionCase:
          'siempre con dativo: aus · bei · mit · nach · seit · von · zu',
      example: 'Voy en autobús.',
    ),
    'und': SeedText(
      'y',
      approximation: 'UNT',
      tip: 'Como en "Hund": la d al final de la palabra suena como t.',
      example: 'pan y mantequilla',
    ),
    // Inglês
    'dog': SeedText(
      'el perro',
      approximation: 'DOG',
      example: 'El perro duerme en el jardín.',
    ),
    'to go': SeedText('ir', approximation: 'GÓU'),
    'beautiful': SeedText(
      'bonito, bello',
      approximation: 'BIÚ-ti-ful',
      example: 'Hace un tiempo precioso.',
    ),
    'often': SeedText(
      'a menudo',
      approximation: 'Ó-fen',
      example: 'A menudo leo por la noche.',
    ),
    'with': SeedText(
      'con',
      approximation: 'UID',
      example: 'Voy con mi amigo.',
    ),
    'and': SeedText(
      'y',
      approximation: 'AND',
      example: 'pan y mantequilla',
    ),
  },
};
