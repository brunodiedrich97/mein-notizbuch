import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' show sqlite3;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import '../../features/vocabulary/models/grammar_type.dart';

part 'app_database.g.dart';

/// Gera a classe de dados `WordEntry` e o `WordEntriesCompanion`.
class WordEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get germanWord => text().withLength(min: 1, max: 100)();
  TextColumn get portugueseTranslation => text().withLength(min: 1)();

  /// Salvo pelo nome ("masculineNoun"), não pelo índice.
  TextColumn get category => textEnum<GrammarCategory>()();

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

@DriftDatabase(tables: [WordEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Para testes: `AppDatabase.forTesting(NativeDatabase.memory())`.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await batch((b) => b.insertAll(wordEntries, _seedWords));
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(wordEntries, wordEntries.tagDetail);
            await m.addColumn(wordEntries, wordEntries.conjugation);
            await _upgradeSeedToV2();
          }
        },
      );

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

  Future<int> addWord(WordEntriesCompanion entry) =>
      into(wordEntries).insert(entry);

  Future<int> deleteWord(int id) =>
      (delete(wordEntries)..where((t) => t.id.equals(id))).go();

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
    exampleGerman: const Value('Das Wetter ist schön.'),
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
