import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' show sqlite3;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import '../../features/decks/models/deck_icon.dart';
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

@DriftDatabase(tables: [Decks, WordEntries, Sentences])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Para testes: `AppDatabase.forTesting(NativeDatabase.memory())`.
  AppDatabase.forTesting(super.executor);

  /// Deck padrão. Recebe as palavras sem deck e não pode ser excluído.
  static const int generalDeckId = 1;

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createGeneralDeck();
          await batch((b) => b.insertAll(wordEntries, _seedWords));
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
        },
      );

  Future<void> _createGeneralDeck() {
    return into(decks).insert(
      DecksCompanion.insert(
        id: const Value(generalDeckId),
        namePt: 'Geral',
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

  /// Palavras sem deck vão para o "Geral".
  Future<void> _moveOrphanWordsToGeneral() {
    return (update(wordEntries)..where((t) => t.deckId.isNull()))
        .write(const WordEntriesCompanion(deckId: Value(generalDeckId)));
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
  Stream<List<WordEntry>> watchAllWords() {
    return (select(wordEntries)
          ..orderBy([
            (t) => OrderingTerm.asc(t.createdAt),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .watch();
  }

  /// Decks em ordem de criação ("Geral" primeiro).
  Stream<List<Deck>> watchDecks() {
    return (select(decks)..orderBy([(t) => OrderingTerm.asc(t.id)])).watch();
  }

  Future<int> addDeck(DecksCompanion entry) => into(decks).insert(entry);

  /// Exclui o deck e move as palavras dele para o "Geral".
  Future<void> deleteDeck(int id) {
    if (id == generalDeckId) return Future.value();
    return transaction(() async {
      await (update(wordEntries)..where((t) => t.deckId.equals(id)))
          .write(const WordEntriesCompanion(deckId: Value(generalDeckId)));
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
    return {
      'app': 'mein_notizbuch',
      'format': backupFormat,
      'schemaVersion': schemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'decks': [for (final d in allDecks) d.toJson()],
      'words': [for (final w in allWords) w.toJson()],
      'sentences': [for (final s in allSentences) s.toJson()],
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
    final newDecks = [for (final j in list('decks')) Deck.fromJson(j)];
    final newWords = [for (final j in list('words')) WordEntry.fromJson(j)];
    final newSentences = [
      for (final j in list('sentences')) Sentence.fromJson(j),
    ];

    await transaction(() async {
      await delete(sentences).go();
      await delete(wordEntries).go();
      await delete(decks).go();
      await batch((b) {
        b.insertAll(decks, newDecks);
        b.insertAll(wordEntries, newWords);
        b.insertAll(sentences, newSentences);
      });
      // O "Geral" precisa existir, mesmo num backup sem ele.
      await _createGeneralDeck();
      await _moveOrphanWordsToGeneral();
    });
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
