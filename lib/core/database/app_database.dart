import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' show sqlite3;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import '../../features/decks/models/deck_icon.dart';
import '../language/native_language.dart';
import '../language/study_language.dart';
import 'seed_translations.dart';
import '../../features/vocabulary/models/grammar_type.dart';
import '../../features/writing/models/sentence_source.dart';

part 'app_database.g.dart';

/// Decks temáticos ("Saúde", "Comida"…). Gera `Deck` e `DecksCompanion`. (v3)
class Decks extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Nome em português, exibido em destaque: "Saúde".
  TextColumn get namePt => text().withLength(min: 1, max: 40)();

  /// Nome em alemão, exibido abaixo: "Gesundheit". Opcional.
  TextColumn get nameDe => text().nullable()();

  /// Salvo pelo nome ("health"), não pelo índice.
  TextColumn get icon => textEnum<DeckIcon>()();

  /// Idioma de estudo do deck ("de"). (v7)
  TextColumn get language => text().withDefault(const Constant('de'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Gera a classe de dados `WordEntry` e o `WordEntriesCompanion`.
class WordEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get germanWord => text().withLength(min: 1, max: 100)();
  TextColumn get portugueseTranslation => text().withLength(min: 1)();

  /// Salvo pelo nome ("masculineNoun"), não pelo índice.
  TextColumn get category => textEnum<GrammarCategory>()();

  /// Deck da palavra (v3). `null` é tratado como o deck "Geral".
  IntColumn get deckId => integer().nullable()();

  /// Classe criada pelo usuário (v6). Quando preenchida, [category] fica
  /// como "outros" (mesmo comportamento) e o nome e a cor vêm da classe.
  IntColumn get customClassId => integer().nullable()();

  /// Idioma de estudo da palavra ("de"). Cada idioma é um caderno separado;
  /// as telas mostram só o idioma ativo. (v7)
  TextColumn get language => text().withDefault(const Constant('de'))();

  /// Complemento do rótulo da classe: "irregular", "dativo"… (v2)
  TextColumn get tagDetail => text().nullable()();

  // Fonética e pronúncia
  TextColumn get ipaPronunciation => text().nullable()();
  TextColumn get brazilianApproximation => text().nullable()();
  TextColumn get phoneticTip => text().nullable()();

  // Formas específicas de cada classe
  TextColumn get pluralForm => text().nullable()(); // "die Hunde"
  TextColumn get verbForms => text().nullable()(); // "ging · ist gegangen"
  TextColumn get prepositionCase => text().nullable()(); // "dativo"
  TextColumn get degrees => text().nullable()(); // "schön → schöner → am schönsten"

  /// Presente do verbo, uma linha por grupo de pessoas (v2).
  TextColumn get conjugation => text().nullable()();

  // Exemplo de uso
  TextColumn get exampleGerman => text().nullable()();
  TextColumn get examplePortuguese => text().nullable()();

  // Histórico de revisão
  IntColumn get correctCount => integer().withDefault(const Constant(0))();
  IntColumn get wrongCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastReviewedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Frases escritas pelo usuário com uma palavra ("Minhas frases"). Gera
/// `Sentence` e `SentencesCompanion`. (v5)
class Sentences extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Palavra da ficha. As frases são apagadas junto com a palavra.
  IntColumn get wordId => integer()();

  TextColumn get german => text().withLength(min: 1, max: 300)();
  TextColumn get portuguese => text().nullable()();

  /// Salvo pelo nome ("free"), não pelo índice.
  TextColumn get source => textEnum<SentenceSource>()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Classes gramaticais criadas pelo usuário ("Conjunção", "Pronome"…).
/// Gera `WordClass` e `WordClassesCompanion`. (v6)
///
/// O nome da classe de dados é fixado aqui: sozinho, o Drift geraria
/// `WordClassesData` (não sabe tirar o plural de "Classes").
@DataClassName('WordClass')
class WordClasses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 40)();

  /// Cor escolhida (ARGB). No tema escuro, o app usa uma versão mais clara.
  IntColumn get color => integer()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Decks, WordEntries, Sentences, WordClasses])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Para testes: `AppDatabase.forTesting(NativeDatabase.memory())`.
  AppDatabase.forTesting(super.executor);

  /// Deck padrão do alemão (criado com o banco).
  static const int germanGeneralDeckId = 1;

  /// Deck padrão de cada idioma de estudo, por código ("de" → 1).
  static final Map<String, int> _generalDeckIds = {'de': germanGeneralDeckId};

  /// Deck padrão do idioma de estudo ativo. Recebe as palavras sem deck e
  /// não pode ser excluído. Garanta que exista com [ensureGeneralDeck].
  static int get generalDeckId =>
      _generalDeckIds[StudyLanguages.active.code] ?? germanGeneralDeckId;

  /// O deck é o padrão de algum idioma?
  static bool isGeneralDeck(int id) => _generalDeckIds.containsValue(id);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createGeneralDeck();
          // Fichas iniciais no idioma nativo escolhido.
          final seeds = localizeSeeds(_seedWords, NativeLanguages.active.code);
          await batch((b) => b.insertAll(wordEntries, seeds));
          await _moveOrphanWordsToGeneral();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(wordEntries, wordEntries.tagDetail);
            await m.addColumn(wordEntries, wordEntries.conjugation);
            await _upgradeSeedToV2();
          }
          if (from < 3) {
            await m.createTable(decks);
            await m.addColumn(wordEntries, wordEntries.deckId);
            await _createGeneralDeck();
            await _moveOrphanWordsToGeneral();
          }
          if (from < 4) {
            await _restoreSchoenExampleTranslation();
          }
          if (from < 5) {
            await m.createTable(sentences);
          }
          if (from < 6) {
            await m.createTable(wordClasses);
            await m.addColumn(wordEntries, wordEntries.customClassId);
          }
          if (from < 7) {
            // Tudo o que já existe é alemão (o padrão da coluna).
            await m.addColumn(wordEntries, wordEntries.language);
            await m.addColumn(decks, decks.language);
          }
        },
      );

  Future<void> _createGeneralDeck() {
    return into(decks).insert(
      DecksCompanion.insert(
        id: const Value(germanGeneralDeckId),
        namePt: NativeLanguages.active.generalDeckName,
        nameDe: const Value('Allgemein'),
        icon: DeckIcon.general,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  /// Devolve a tradução do exemplo de "schön", tirada na v2. Só mexe na
  /// ficha original, e só se o usuário não tiver escrito outra. (v4)
  Future<void> _restoreSchoenExampleTranslation() {
    return (update(wordEntries)
          ..where((t) =>
              t.germanWord.equals('schön') &
              t.exampleGerman.equals(_schoenExample) &
              t.examplePortuguese.isNull()))
        .write(
      const WordEntriesCompanion(
        examplePortuguese: Value(_schoenExampleTranslation),
      ),
    );
  }

  /// Palavras sem deck (de alemão, nas migrações) vão para o "Geral".
  Future<void> _moveOrphanWordsToGeneral() {
    return (update(wordEntries)..where((t) => t.deckId.isNull())).write(
      const WordEntriesCompanion(deckId: Value(germanGeneralDeckId)),
    );
  }

  /// Garante o deck "Geral" do idioma [language] e devolve o id. Na primeira
  /// vez de um idioma novo, cria o deck e as fichas iniciais dele.
  Future<int> ensureGeneralDeck(String language) async {
    if (language == 'de') {
      await _createGeneralDeck();
      return germanGeneralDeckId;
    }
    final existing = await (select(decks)
          ..where((t) =>
              t.language.equals(language) &
              t.icon.equalsValue(DeckIcon.general))
          ..orderBy([(t) => OrderingTerm.asc(t.id)])
          ..limit(1))
        .getSingleOrNull();
    if (existing != null) {
      _generalDeckIds[language] = existing.id;
      return existing.id;
    }

    final profile = StudyLanguages.all.firstWhere(
      (l) => l.code == language,
      orElse: () => StudyLanguages.active,
    );
    return transaction(() async {
      final id = await into(decks).insert(
        DecksCompanion.insert(
          namePt: NativeLanguages.active.generalDeckName,
          nameDe: Value(profile.terms.generalDeck),
          icon: DeckIcon.general,
          language: Value(language),
        ),
      );
      _generalDeckIds[language] = id;
      final seeds = localizeSeeds(
        _seedWordsByLanguage[language] ?? const [],
        NativeLanguages.active.code,
      );
      await batch((b) => b.insertAll(wordEntries, [
            for (final w in seeds)
              w.copyWith(deckId: Value(id), language: Value(language)),
          ]));
      return id;
    });
  }

  /// Leva as fichas iniciais da v1 ao formato do protótipo.
  Future<void> _upgradeSeedToV2() async {
    await (update(wordEntries)
          ..where((t) =>
              t.germanWord.equals('gehen') &
              t.examplePortuguese.equals('presente regular')))
        .write(
      const WordEntriesCompanion(
        tagDetail: Value('irregular'),
        conjugation: Value(_gehenPresent),
        exampleGerman: Value(null),
        examplePortuguese: Value(null),
      ),
    );
    await (update(wordEntries)..where((t) => t.germanWord.equals('mit')))
        .write(const WordEntriesCompanion(tagDetail: Value('dativo')));
    await (update(wordEntries)
          ..where((t) =>
              t.germanWord.equals('schön') &
              t.examplePortuguese.equals('O tempo está bom.')))
        .write(const WordEntriesCompanion(examplePortuguese: Value(null)));
  }

  // ---------- Consultas ----------

  /// Lista reativa: emite de novo a cada inserção, edição ou exclusão.
  /// Palavras do idioma [language], em ordem de cadastro.
  Stream<List<WordEntry>> watchAllWords(String language) {
    return (select(wordEntries)
          ..where((t) => t.language.equals(language))
          ..orderBy([
            (t) => OrderingTerm.asc(t.createdAt),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .watch();
  }

  /// Classes criadas pelo usuário, em ordem de criação.
  Stream<List<WordClass>> watchWordClasses() {
    return (select(wordClasses)..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .watch();
  }

  Future<int> addWordClass(String name, int color) => into(wordClasses)
      .insert(WordClassesCompanion.insert(name: name, color: color));

  Future<void> updateWordClass(int id, String name, int color) {
    return (update(wordClasses)..where((t) => t.id.equals(id))).write(
      WordClassesCompanion(name: Value(name), color: Value(color)),
    );
  }

  /// Exclui a classe; as palavras dela voltam a ser "outros".
  Future<void> deleteWordClass(int id) {
    return transaction(() async {
      await (update(wordEntries)..where((t) => t.customClassId.equals(id)))
          .write(const WordEntriesCompanion(customClassId: Value(null)));
      await (delete(wordClasses)..where((t) => t.id.equals(id))).go();
    });
  }

  /// Decks em ordem de criação ("Geral" primeiro).
  Stream<List<Deck>> watchDecks(String language) {
    // O "Geral" (id 1) é do alemão. Quando houver outro idioma de estudo,
    // cada idioma terá o seu deck padrão.
    return (select(decks)
          ..where((t) => t.language.equals(language))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .watch();
  }

  Future<int> addDeck(DecksCompanion entry) => into(decks).insert(entry);

  /// Exclui o deck e move as palavras dele para o "Geral".
  Future<void> deleteDeck(int id) {
    if (isGeneralDeck(id)) return Future.value();
    return transaction(() async {
      final deck = await (select(decks)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (deck == null) return;
      final general = await ensureGeneralDeck(deck.language);
      await (update(wordEntries)..where((t) => t.deckId.equals(id)))
          .write(WordEntriesCompanion(deckId: Value(general)));
      await (delete(decks)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<int> addWord(WordEntriesCompanion entry) =>
      into(wordEntries).insert(entry);

  /// Exclui a palavra e as frases dela.
  Future<void> deleteWord(int id) {
    return transaction(() async {
      await (delete(sentences)..where((t) => t.wordId.equals(id))).go();
      await (delete(wordEntries)..where((t) => t.id.equals(id))).go();
    });
  }

  /// Todas as frases, das mais novas para as mais antigas.
  Stream<List<Sentence>> watchSentences() {
    return (select(sentences)
          ..orderBy([
            (t) => OrderingTerm.desc(t.createdAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
        .watch();
  }

  Future<int> addSentence(SentencesCompanion entry) =>
      into(sentences).insert(entry);

  Future<int> deleteSentence(int id) =>
      (delete(sentences)..where((t) => t.id.equals(id))).go();

  // ---------- Backup ----------

  /// Formato do arquivo de backup. Suba ao mudar a estrutura do JSON.
  static const int backupFormat = 1;

  /// Todos os dados (decks, palavras e frases) num mapa pronto para JSON.
  Future<Map<String, dynamic>> exportData() async {
    final allDecks = await select(decks).get();
    final allWords = await select(wordEntries).get();
    final allSentences = await select(sentences).get();
    final allClasses = await select(wordClasses).get();
    return {
      'app': 'mein_notizbuch',
      'format': backupFormat,
      'schemaVersion': schemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'decks': [for (final d in allDecks) d.toJson()],
      'words': [for (final w in allWords) w.toJson()],
      'sentences': [for (final s in allSentences) s.toJson()],
      'wordClasses': [for (final c in allClasses) c.toJson()],
    };
  }

  /// Substitui TODOS os dados do aparelho pelos do backup [data].
  /// Lança [FormatException] se o arquivo não for um backup válido.
  Future<void> importData(Map<String, dynamic> data) async {
    if (data['app'] != 'mein_notizbuch') {
      throw const FormatException('O arquivo não é um backup do Notizbuch.');
    }
    final format = data['format'];
    if (format is! int || format > backupFormat) {
      throw const FormatException(
        'Backup feito por uma versão mais nova do app. Atualize o app.',
      );
    }

    List<Map<String, dynamic>> list(String key) => [
          for (final item in (data[key] as List? ?? const []))
            Map<String, dynamic>.from(item as Map),
        ];

    // Converte antes de apagar: se algo estiver errado, nada é perdido.
    // Backups anteriores à v7 não têm idioma: eram todos de alemão.
    List<Map<String, dynamic>> withLanguage(String key) => [
          for (final j in list(key)) {'language': 'de', ...j},
        ];
    final newDecks = [
      for (final j in withLanguage('decks')) Deck.fromJson(j),
    ];
    final newWords = [
      for (final j in withLanguage('words')) WordEntry.fromJson(j),
    ];
    final newSentences = [
      for (final j in list('sentences')) Sentence.fromJson(j),
    ];
    // Backups anteriores à v6 não têm classes: a lista fica vazia.
    final newClasses = [
      for (final j in list('wordClasses')) WordClass.fromJson(j),
    ];

    await transaction(() async {
      await delete(sentences).go();
      await delete(wordEntries).go();
      await delete(decks).go();
      await delete(wordClasses).go();
      await batch((b) {
        b.insertAll(wordClasses, newClasses);
        b.insertAll(decks, newDecks);
        b.insertAll(wordEntries, newWords);
        b.insertAll(sentences, newSentences);
      });
      // O "Geral" precisa existir, mesmo num backup sem ele.
      await _createGeneralDeck();
      await _moveOrphanWordsToGeneral();
    });
    // Os ids dos decks "Geral" dos outros idiomas vêm do backup.
    _generalDeckIds.removeWhere((code, _) => code != 'de');
    await ensureGeneralDeck(StudyLanguages.active.code);
  }

  /// Registra o resultado de uma pergunta da revisão.
  Future<void> recordReview(int id, {required bool correct}) {
    return transaction(() async {
      final word = await (select(wordEntries)..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (word == null) return;
      await (update(wordEntries)..where((t) => t.id.equals(id))).write(
        WordEntriesCompanion(
          correctCount: Value(word.correctCount + (correct ? 1 : 0)),
          wrongCount: Value(word.wrongCount + (correct ? 0 : 1)),
          lastReviewedAt: Value(DateTime.now()),
        ),
      );
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'notizbuch_deutsch.sqlite'));

    // Corrige a abertura do SQLite em Androids antigos (6 e anteriores).
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    // Pasta temporária gravável para o SQLite em todas as plataformas.
    sqlite3.tempDirectory = (await getTemporaryDirectory()).path;

    return NativeDatabase.createInBackground(file);
  });
}

/// Fichas iniciais de cada idioma além do alemão, criadas junto com o deck
/// "Geral" do idioma (veja [AppDatabase.ensureGeneralDeck]).
final Map<String, List<WordEntriesCompanion>> _seedWordsByLanguage = {
  'en': [
    WordEntriesCompanion.insert(
      germanWord: 'dog',
      portugueseTranslation: 'o cachorro',
      category: GrammarCategory.noun,
      ipaPronunciation: const Value('[dɔːɡ]'),
      brazilianApproximation: const Value('DÓG'),
      pluralForm: const Value('dogs'),
      exampleGerman: const Value('The dog sleeps in the garden.'),
      examplePortuguese: const Value('O cachorro dorme no jardim.'),
    ),
    WordEntriesCompanion.insert(
      germanWord: 'to go',
      portugueseTranslation: 'ir',
      category: GrammarCategory.verb,
      tagDetail: const Value('irregular'),
      ipaPronunciation: const Value('[ɡoʊ]'),
      brazilianApproximation: const Value('GÔU'),
      verbForms: const Value('went · gone'),
      conjugation: const Value(
        'I go · you go · he goes\nwe go · you go · they go',
      ),
    ),
    WordEntriesCompanion.insert(
      germanWord: 'beautiful',
      portugueseTranslation: 'bonito, belo',
      category: GrammarCategory.adjective,
      ipaPronunciation: const Value('[ˈbjuːtɪfəl]'),
      brazilianApproximation: const Value('BIÚ-ti-fol'),
      degrees: const Value('beautiful → more beautiful → most beautiful'),
      exampleGerman: const Value('The weather is beautiful.'),
      examplePortuguese: const Value('O tempo está bonito.'),
    ),
    WordEntriesCompanion.insert(
      germanWord: 'often',
      portugueseTranslation: 'frequentemente',
      category: GrammarCategory.adverb,
      ipaPronunciation: const Value('[ˈɔːfən]'),
      brazilianApproximation: const Value('Ó-fen'),
      exampleGerman: const Value('I often read at night.'),
      examplePortuguese: const Value('Eu leio frequentemente à noite.'),
    ),
    WordEntriesCompanion.insert(
      germanWord: 'with',
      portugueseTranslation: 'com',
      category: GrammarCategory.preposition,
      ipaPronunciation: const Value('[wɪð]'),
      brazilianApproximation: const Value('UID'),
      exampleGerman: const Value('I go with my friend.'),
      examplePortuguese: const Value('Eu vou com meu amigo.'),
    ),
    WordEntriesCompanion.insert(
      germanWord: 'and',
      portugueseTranslation: 'e',
      category: GrammarCategory.other,
      ipaPronunciation: const Value('[ænd]'),
      brazilianApproximation: const Value('ÉND'),
      exampleGerman: const Value('bread and butter'),
      examplePortuguese: const Value('pão e manteiga'),
    ),
  ],
};

const _schoenExample = 'Das Wetter ist schön.';
const _schoenExampleTranslation = 'O tempo está bonito.';

const _gehenPresent =
    'ich gehe · du gehst · er geht\nwir gehen · ihr geht · sie gehen';

/// Fichas iniciais do caderno: as seis do protótipo, mais um advérbio e
/// uma conjunção para mostrar as cores restantes.
final List<WordEntriesCompanion> _seedWords = [
  WordEntriesCompanion.insert(
    germanWord: 'der Hund',
    portugueseTranslation: 'o cachorro',
    category: GrammarCategory.masculineNoun,
    ipaPronunciation: const Value('[deːɐ̯ hʊnt]'),
    brazilianApproximation: const Value('dér HUNT'),
    phoneticTip: const Value(
        'O h é aspirado, como um suspiro. O d no fim soa como t.'),
    pluralForm: const Value('die Hunde'),
    exampleGerman: const Value('Der Hund schläft im Garten.'),
    examplePortuguese: const Value('O cachorro dorme no jardim.'),
  ),
  WordEntriesCompanion.insert(
    germanWord: 'die Lampe',
    portugueseTranslation: 'a luminária',
    category: GrammarCategory.feminineNoun,
    ipaPronunciation: const Value("[diː 'lampə]"),
    brazilianApproximation: const Value('dí LAM-pe'),
    phoneticTip: const Value(
        'O a não é nasal como em "lâmpada", e o -e final é bem fraco.'),
    pluralForm: const Value('die Lampen'),
    exampleGerman: const Value('Die Lampe steht auf dem Tisch.'),
    examplePortuguese: const Value('A luminária está sobre a mesa.'),
  ),
  WordEntriesCompanion.insert(
    germanWord: 'das Buch',
    portugueseTranslation: 'o livro',
    category: GrammarCategory.neuterNoun,
    ipaPronunciation: const Value('[das buːx]'),
    brazilianApproximation: const Value('das BUUKH'),
    phoneticTip: const Value(
        'O ch depois de u é raspado no fundo da garganta, parecido com o r '
        'de "carro" no Rio.'),
    pluralForm: const Value('die Bücher'),
    exampleGerman: const Value('Ich lese ein Buch.'),
    examplePortuguese: const Value('Eu leio um livro.'),
  ),
  WordEntriesCompanion.insert(
    germanWord: 'gehen',
    portugueseTranslation: 'ir (a pé)',
    category: GrammarCategory.verb,
    tagDetail: const Value('irregular'),
    ipaPronunciation: const Value("['ɡeːən]"),
    brazilianApproximation: const Value('GUÊ-en'),
    phoneticTip: const Value(
        'O g é sempre duro, como em "gato", e o h no meio é mudo.'),
    verbForms: const Value('ging · ist gegangen'),
    conjugation: const Value(_gehenPresent),
  ),
  WordEntriesCompanion.insert(
    germanWord: 'schön',
    portugueseTranslation: 'bonito, belo',
    category: GrammarCategory.adjective,
    ipaPronunciation: const Value('[ʃøːn]'),
    brazilianApproximation: const Value('XÖÖN'),
    phoneticTip: const Value(
        'Para o ö, diga "ê" com os lábios arredondados como para "ô".'),
    degrees: const Value('schön → schöner → am schönsten'),
    exampleGerman: const Value(_schoenExample),
    examplePortuguese: const Value(_schoenExampleTranslation),
  ),
  WordEntriesCompanion.insert(
    germanWord: 'gern',
    portugueseTranslation: 'com gosto, de bom grado',
    category: GrammarCategory.adverb,
    ipaPronunciation: const Value('[ɡɛʁn]'),
    brazilianApproximation: const Value('GUÉRN'),
    phoneticTip: const Value(
        'O r antes de consoante quase some e vira um "a" bem leve.'),
    degrees: const Value('gern → lieber → am liebsten'),
    exampleGerman: const Value('Ich trinke gern Kaffee.'),
    examplePortuguese: const Value('Eu gosto de tomar café.'),
  ),
  WordEntriesCompanion.insert(
    germanWord: 'mit',
    portugueseTranslation: 'com',
    category: GrammarCategory.preposition,
    tagDetail: const Value('dativo'),
    ipaPronunciation: const Value('[mɪt]'),
    brazilianApproximation: const Value('MIT'),
    phoneticTip: const Value(
        'O i é curto e um pouco mais aberto que o nosso, quase entre "i" e '
        '"ê".'),
    prepositionCase: const Value(
        'sempre com dativo: aus · bei · mit · nach · seit · von · zu'),
    exampleGerman: const Value('Ich fahre mit dem Bus.'),
    examplePortuguese: const Value('Eu vou de ônibus.'),
  ),
  WordEntriesCompanion.insert(
    germanWord: 'und',
    portugueseTranslation: 'e',
    category: GrammarCategory.other,
    ipaPronunciation: const Value('[ʊnt]'),
    brazilianApproximation: const Value('UNT'),
    phoneticTip: const Value(
        'Como em "Hund": o d no fim da palavra soa como t.'),
    exampleGerman: const Value('Brot und Butter'),
    examplePortuguese: const Value('pão e manteiga'),
  ),
];
