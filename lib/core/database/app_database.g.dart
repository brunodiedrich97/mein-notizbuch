// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WordEntriesTable extends WordEntries
    with TableInfo<$WordEntriesTable, WordEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _germanWordMeta =
      const VerificationMeta('germanWord');
  @override
  late final GeneratedColumn<String> germanWord = GeneratedColumn<String>(
      'german_word', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 100),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _portugueseTranslationMeta =
      const VerificationMeta('portugueseTranslation');
  @override
  late final GeneratedColumn<String> portugueseTranslation =
      GeneratedColumn<String>('portuguese_translation', aliasedName, false,
          additionalChecks: GeneratedColumn.checkTextLength(
            minTextLength: 1,
          ),
          type: DriftSqlType.string,
          requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<GrammarCategory, String>
      category = GeneratedColumn<String>('category', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<GrammarCategory>($WordEntriesTable.$convertercategory);
  static const VerificationMeta _tagDetailMeta =
      const VerificationMeta('tagDetail');
  @override
  late final GeneratedColumn<String> tagDetail = GeneratedColumn<String>(
      'tag_detail', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _ipaPronunciationMeta =
      const VerificationMeta('ipaPronunciation');
  @override
  late final GeneratedColumn<String> ipaPronunciation = GeneratedColumn<String>(
      'ipa_pronunciation', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _brazilianApproximationMeta =
      const VerificationMeta('brazilianApproximation');
  @override
  late final GeneratedColumn<String> brazilianApproximation =
      GeneratedColumn<String>('brazilian_approximation', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _phoneticTipMeta =
      const VerificationMeta('phoneticTip');
  @override
  late final GeneratedColumn<String> phoneticTip = GeneratedColumn<String>(
      'phonetic_tip', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _pluralFormMeta =
      const VerificationMeta('pluralForm');
  @override
  late final GeneratedColumn<String> pluralForm = GeneratedColumn<String>(
      'plural_form', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _verbFormsMeta =
      const VerificationMeta('verbForms');
  @override
  late final GeneratedColumn<String> verbForms = GeneratedColumn<String>(
      'verb_forms', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _prepositionCaseMeta =
      const VerificationMeta('prepositionCase');
  @override
  late final GeneratedColumn<String> prepositionCase = GeneratedColumn<String>(
      'preposition_case', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _degreesMeta =
      const VerificationMeta('degrees');
  @override
  late final GeneratedColumn<String> degrees = GeneratedColumn<String>(
      'degrees', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _conjugationMeta =
      const VerificationMeta('conjugation');
  @override
  late final GeneratedColumn<String> conjugation = GeneratedColumn<String>(
      'conjugation', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _exampleGermanMeta =
      const VerificationMeta('exampleGerman');
  @override
  late final GeneratedColumn<String> exampleGerman = GeneratedColumn<String>(
      'example_german', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _examplePortugueseMeta =
      const VerificationMeta('examplePortuguese');
  @override
  late final GeneratedColumn<String> examplePortuguese =
      GeneratedColumn<String>('example_portuguese', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _correctCountMeta =
      const VerificationMeta('correctCount');
  @override
  late final GeneratedColumn<int> correctCount = GeneratedColumn<int>(
      'correct_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _wrongCountMeta =
      const VerificationMeta('wrongCount');
  @override
  late final GeneratedColumn<int> wrongCount = GeneratedColumn<int>(
      'wrong_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastReviewedAtMeta =
      const VerificationMeta('lastReviewedAt');
  @override
  late final GeneratedColumn<DateTime> lastReviewedAt =
      GeneratedColumn<DateTime>('last_reviewed_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        germanWord,
        portugueseTranslation,
        category,
        tagDetail,
        ipaPronunciation,
        brazilianApproximation,
        phoneticTip,
        pluralForm,
        verbForms,
        prepositionCase,
        degrees,
        conjugation,
        exampleGerman,
        examplePortuguese,
        correctCount,
        wrongCount,
        lastReviewedAt,
        createdAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_entries';
  @override
  VerificationContext validateIntegrity(Insertable<WordEntry> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('german_word')) {
      context.handle(
          _germanWordMeta,
          germanWord.isAcceptableOrUnknown(
              data['german_word']!, _germanWordMeta));
    } else if (isInserting) {
      context.missing(_germanWordMeta);
    }
    if (data.containsKey('portuguese_translation')) {
      context.handle(
          _portugueseTranslationMeta,
          portugueseTranslation.isAcceptableOrUnknown(
              data['portuguese_translation']!, _portugueseTranslationMeta));
    } else if (isInserting) {
      context.missing(_portugueseTranslationMeta);
    }
    if (data.containsKey('tag_detail')) {
      context.handle(_tagDetailMeta,
          tagDetail.isAcceptableOrUnknown(data['tag_detail']!, _tagDetailMeta));
    }
    if (data.containsKey('ipa_pronunciation')) {
      context.handle(
          _ipaPronunciationMeta,
          ipaPronunciation.isAcceptableOrUnknown(
              data['ipa_pronunciation']!, _ipaPronunciationMeta));
    }
    if (data.containsKey('brazilian_approximation')) {
      context.handle(
          _brazilianApproximationMeta,
          brazilianApproximation.isAcceptableOrUnknown(
              data['brazilian_approximation']!, _brazilianApproximationMeta));
    }
    if (data.containsKey('phonetic_tip')) {
      context.handle(
          _phoneticTipMeta,
          phoneticTip.isAcceptableOrUnknown(
              data['phonetic_tip']!, _phoneticTipMeta));
    }
    if (data.containsKey('plural_form')) {
      context.handle(
          _pluralFormMeta,
          pluralForm.isAcceptableOrUnknown(
              data['plural_form']!, _pluralFormMeta));
    }
    if (data.containsKey('verb_forms')) {
      context.handle(_verbFormsMeta,
          verbForms.isAcceptableOrUnknown(data['verb_forms']!, _verbFormsMeta));
    }
    if (data.containsKey('preposition_case')) {
      context.handle(
          _prepositionCaseMeta,
          prepositionCase.isAcceptableOrUnknown(
              data['preposition_case']!, _prepositionCaseMeta));
    }
    if (data.containsKey('degrees')) {
      context.handle(_degreesMeta,
          degrees.isAcceptableOrUnknown(data['degrees']!, _degreesMeta));
    }
    if (data.containsKey('conjugation')) {
      context.handle(
          _conjugationMeta,
          conjugation.isAcceptableOrUnknown(
              data['conjugation']!, _conjugationMeta));
    }
    if (data.containsKey('example_german')) {
      context.handle(
          _exampleGermanMeta,
          exampleGerman.isAcceptableOrUnknown(
              data['example_german']!, _exampleGermanMeta));
    }
    if (data.containsKey('example_portuguese')) {
      context.handle(
          _examplePortugueseMeta,
          examplePortuguese.isAcceptableOrUnknown(
              data['example_portuguese']!, _examplePortugueseMeta));
    }
    if (data.containsKey('correct_count')) {
      context.handle(
          _correctCountMeta,
          correctCount.isAcceptableOrUnknown(
              data['correct_count']!, _correctCountMeta));
    }
    if (data.containsKey('wrong_count')) {
      context.handle(
          _wrongCountMeta,
          wrongCount.isAcceptableOrUnknown(
              data['wrong_count']!, _wrongCountMeta));
    }
    if (data.containsKey('last_reviewed_at')) {
      context.handle(
          _lastReviewedAtMeta,
          lastReviewedAt.isAcceptableOrUnknown(
              data['last_reviewed_at']!, _lastReviewedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WordEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordEntry(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      germanWord: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}german_word'])!,
      portugueseTranslation: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}portuguese_translation'])!,
      category: $WordEntriesTable.$convertercategory.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!),
      tagDetail: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tag_detail']),
      ipaPronunciation: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}ipa_pronunciation']),
      brazilianApproximation: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}brazilian_approximation']),
      phoneticTip: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phonetic_tip']),
      pluralForm: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plural_form']),
      verbForms: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}verb_forms']),
      prepositionCase: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}preposition_case']),
      degrees: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}degrees']),
      conjugation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}conjugation']),
      exampleGerman: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}example_german']),
      examplePortuguese: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}example_portuguese']),
      correctCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}correct_count'])!,
      wrongCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}wrong_count'])!,
      lastReviewedAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_reviewed_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $WordEntriesTable createAlias(String alias) {
    return $WordEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<GrammarCategory, String, String>
      $convertercategory =
      const EnumNameConverter<GrammarCategory>(GrammarCategory.values);
}

class WordEntry extends DataClass implements Insertable<WordEntry> {
  final int id;
  final String germanWord;
  final String portugueseTranslation;

  /// Salvo pelo nome ("masculineNoun"), não pelo índice.
  final GrammarCategory category;

  /// Complemento do rótulo da classe: "irregular", "dativo"… (v2)
  final String? tagDetail;
  final String? ipaPronunciation;
  final String? brazilianApproximation;
  final String? phoneticTip;
  final String? pluralForm;
  final String? verbForms;
  final String? prepositionCase;
  final String? degrees;

  /// Presente do verbo, uma linha por grupo de pessoas (v2).
  final String? conjugation;
  final String? exampleGerman;
  final String? examplePortuguese;
  final int correctCount;
  final int wrongCount;
  final DateTime? lastReviewedAt;
  final DateTime createdAt;
  const WordEntry(
      {required this.id,
      required this.germanWord,
      required this.portugueseTranslation,
      required this.category,
      this.tagDetail,
      this.ipaPronunciation,
      this.brazilianApproximation,
      this.phoneticTip,
      this.pluralForm,
      this.verbForms,
      this.prepositionCase,
      this.degrees,
      this.conjugation,
      this.exampleGerman,
      this.examplePortuguese,
      required this.correctCount,
      required this.wrongCount,
      this.lastReviewedAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['german_word'] = Variable<String>(germanWord);
    map['portuguese_translation'] = Variable<String>(portugueseTranslation);
    {
      map['category'] = Variable<String>(
          $WordEntriesTable.$convertercategory.toSql(category));
    }
    if (!nullToAbsent || tagDetail != null) {
      map['tag_detail'] = Variable<String>(tagDetail);
    }
    if (!nullToAbsent || ipaPronunciation != null) {
      map['ipa_pronunciation'] = Variable<String>(ipaPronunciation);
    }
    if (!nullToAbsent || brazilianApproximation != null) {
      map['brazilian_approximation'] = Variable<String>(brazilianApproximation);
    }
    if (!nullToAbsent || phoneticTip != null) {
      map['phonetic_tip'] = Variable<String>(phoneticTip);
    }
    if (!nullToAbsent || pluralForm != null) {
      map['plural_form'] = Variable<String>(pluralForm);
    }
    if (!nullToAbsent || verbForms != null) {
      map['verb_forms'] = Variable<String>(verbForms);
    }
    if (!nullToAbsent || prepositionCase != null) {
      map['preposition_case'] = Variable<String>(prepositionCase);
    }
    if (!nullToAbsent || degrees != null) {
      map['degrees'] = Variable<String>(degrees);
    }
    if (!nullToAbsent || conjugation != null) {
      map['conjugation'] = Variable<String>(conjugation);
    }
    if (!nullToAbsent || exampleGerman != null) {
      map['example_german'] = Variable<String>(exampleGerman);
    }
    if (!nullToAbsent || examplePortuguese != null) {
      map['example_portuguese'] = Variable<String>(examplePortuguese);
    }
    map['correct_count'] = Variable<int>(correctCount);
    map['wrong_count'] = Variable<int>(wrongCount);
    if (!nullToAbsent || lastReviewedAt != null) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  WordEntriesCompanion toCompanion(bool nullToAbsent) {
    return WordEntriesCompanion(
      id: Value(id),
      germanWord: Value(germanWord),
      portugueseTranslation: Value(portugueseTranslation),
      category: Value(category),
      tagDetail: tagDetail == null && nullToAbsent
          ? const Value.absent()
          : Value(tagDetail),
      ipaPronunciation: ipaPronunciation == null && nullToAbsent
          ? const Value.absent()
          : Value(ipaPronunciation),
      brazilianApproximation: brazilianApproximation == null && nullToAbsent
          ? const Value.absent()
          : Value(brazilianApproximation),
      phoneticTip: phoneticTip == null && nullToAbsent
          ? const Value.absent()
          : Value(phoneticTip),
      pluralForm: pluralForm == null && nullToAbsent
          ? const Value.absent()
          : Value(pluralForm),
      verbForms: verbForms == null && nullToAbsent
          ? const Value.absent()
          : Value(verbForms),
      prepositionCase: prepositionCase == null && nullToAbsent
          ? const Value.absent()
          : Value(prepositionCase),
      degrees: degrees == null && nullToAbsent
          ? const Value.absent()
          : Value(degrees),
      conjugation: conjugation == null && nullToAbsent
          ? const Value.absent()
          : Value(conjugation),
      exampleGerman: exampleGerman == null && nullToAbsent
          ? const Value.absent()
          : Value(exampleGerman),
      examplePortuguese: examplePortuguese == null && nullToAbsent
          ? const Value.absent()
          : Value(examplePortuguese),
      correctCount: Value(correctCount),
      wrongCount: Value(wrongCount),
      lastReviewedAt: lastReviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReviewedAt),
      createdAt: Value(createdAt),
    );
  }

  factory WordEntry.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordEntry(
      id: serializer.fromJson<int>(json['id']),
      germanWord: serializer.fromJson<String>(json['germanWord']),
      portugueseTranslation:
          serializer.fromJson<String>(json['portugueseTranslation']),
      category: $WordEntriesTable.$convertercategory
          .fromJson(serializer.fromJson<String>(json['category'])),
      tagDetail: serializer.fromJson<String?>(json['tagDetail']),
      ipaPronunciation: serializer.fromJson<String?>(json['ipaPronunciation']),
      brazilianApproximation:
          serializer.fromJson<String?>(json['brazilianApproximation']),
      phoneticTip: serializer.fromJson<String?>(json['phoneticTip']),
      pluralForm: serializer.fromJson<String?>(json['pluralForm']),
      verbForms: serializer.fromJson<String?>(json['verbForms']),
      prepositionCase: serializer.fromJson<String?>(json['prepositionCase']),
      degrees: serializer.fromJson<String?>(json['degrees']),
      conjugation: serializer.fromJson<String?>(json['conjugation']),
      exampleGerman: serializer.fromJson<String?>(json['exampleGerman']),
      examplePortuguese:
          serializer.fromJson<String?>(json['examplePortuguese']),
      correctCount: serializer.fromJson<int>(json['correctCount']),
      wrongCount: serializer.fromJson<int>(json['wrongCount']),
      lastReviewedAt: serializer.fromJson<DateTime?>(json['lastReviewedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'germanWord': serializer.toJson<String>(germanWord),
      'portugueseTranslation': serializer.toJson<String>(portugueseTranslation),
      'category': serializer.toJson<String>(
          $WordEntriesTable.$convertercategory.toJson(category)),
      'tagDetail': serializer.toJson<String?>(tagDetail),
      'ipaPronunciation': serializer.toJson<String?>(ipaPronunciation),
      'brazilianApproximation':
          serializer.toJson<String?>(brazilianApproximation),
      'phoneticTip': serializer.toJson<String?>(phoneticTip),
      'pluralForm': serializer.toJson<String?>(pluralForm),
      'verbForms': serializer.toJson<String?>(verbForms),
      'prepositionCase': serializer.toJson<String?>(prepositionCase),
      'degrees': serializer.toJson<String?>(degrees),
      'conjugation': serializer.toJson<String?>(conjugation),
      'exampleGerman': serializer.toJson<String?>(exampleGerman),
      'examplePortuguese': serializer.toJson<String?>(examplePortuguese),
      'correctCount': serializer.toJson<int>(correctCount),
      'wrongCount': serializer.toJson<int>(wrongCount),
      'lastReviewedAt': serializer.toJson<DateTime?>(lastReviewedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  WordEntry copyWith(
          {int? id,
          String? germanWord,
          String? portugueseTranslation,
          GrammarCategory? category,
          Value<String?> tagDetail = const Value.absent(),
          Value<String?> ipaPronunciation = const Value.absent(),
          Value<String?> brazilianApproximation = const Value.absent(),
          Value<String?> phoneticTip = const Value.absent(),
          Value<String?> pluralForm = const Value.absent(),
          Value<String?> verbForms = const Value.absent(),
          Value<String?> prepositionCase = const Value.absent(),
          Value<String?> degrees = const Value.absent(),
          Value<String?> conjugation = const Value.absent(),
          Value<String?> exampleGerman = const Value.absent(),
          Value<String?> examplePortuguese = const Value.absent(),
          int? correctCount,
          int? wrongCount,
          Value<DateTime?> lastReviewedAt = const Value.absent(),
          DateTime? createdAt}) =>
      WordEntry(
        id: id ?? this.id,
        germanWord: germanWord ?? this.germanWord,
        portugueseTranslation:
            portugueseTranslation ?? this.portugueseTranslation,
        category: category ?? this.category,
        tagDetail: tagDetail.present ? tagDetail.value : this.tagDetail,
        ipaPronunciation: ipaPronunciation.present
            ? ipaPronunciation.value
            : this.ipaPronunciation,
        brazilianApproximation: brazilianApproximation.present
            ? brazilianApproximation.value
            : this.brazilianApproximation,
        phoneticTip: phoneticTip.present ? phoneticTip.value : this.phoneticTip,
        pluralForm: pluralForm.present ? pluralForm.value : this.pluralForm,
        verbForms: verbForms.present ? verbForms.value : this.verbForms,
        prepositionCase: prepositionCase.present
            ? prepositionCase.value
            : this.prepositionCase,
        degrees: degrees.present ? degrees.value : this.degrees,
        conjugation: conjugation.present ? conjugation.value : this.conjugation,
        exampleGerman:
            exampleGerman.present ? exampleGerman.value : this.exampleGerman,
        examplePortuguese: examplePortuguese.present
            ? examplePortuguese.value
            : this.examplePortuguese,
        correctCount: correctCount ?? this.correctCount,
        wrongCount: wrongCount ?? this.wrongCount,
        lastReviewedAt:
            lastReviewedAt.present ? lastReviewedAt.value : this.lastReviewedAt,
        createdAt: createdAt ?? this.createdAt,
      );
  WordEntry copyWithCompanion(WordEntriesCompanion data) {
    return WordEntry(
      id: data.id.present ? data.id.value : this.id,
      germanWord:
          data.germanWord.present ? data.germanWord.value : this.germanWord,
      portugueseTranslation: data.portugueseTranslation.present
          ? data.portugueseTranslation.value
          : this.portugueseTranslation,
      category: data.category.present ? data.category.value : this.category,
      tagDetail: data.tagDetail.present ? data.tagDetail.value : this.tagDetail,
      ipaPronunciation: data.ipaPronunciation.present
          ? data.ipaPronunciation.value
          : this.ipaPronunciation,
      brazilianApproximation: data.brazilianApproximation.present
          ? data.brazilianApproximation.value
          : this.brazilianApproximation,
      phoneticTip:
          data.phoneticTip.present ? data.phoneticTip.value : this.phoneticTip,
      pluralForm:
          data.pluralForm.present ? data.pluralForm.value : this.pluralForm,
      verbForms: data.verbForms.present ? data.verbForms.value : this.verbForms,
      prepositionCase: data.prepositionCase.present
          ? data.prepositionCase.value
          : this.prepositionCase,
      degrees: data.degrees.present ? data.degrees.value : this.degrees,
      conjugation:
          data.conjugation.present ? data.conjugation.value : this.conjugation,
      exampleGerman: data.exampleGerman.present
          ? data.exampleGerman.value
          : this.exampleGerman,
      examplePortuguese: data.examplePortuguese.present
          ? data.examplePortuguese.value
          : this.examplePortuguese,
      correctCount: data.correctCount.present
          ? data.correctCount.value
          : this.correctCount,
      wrongCount:
          data.wrongCount.present ? data.wrongCount.value : this.wrongCount,
      lastReviewedAt: data.lastReviewedAt.present
          ? data.lastReviewedAt.value
          : this.lastReviewedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordEntry(')
          ..write('id: $id, ')
          ..write('germanWord: $germanWord, ')
          ..write('portugueseTranslation: $portugueseTranslation, ')
          ..write('category: $category, ')
          ..write('tagDetail: $tagDetail, ')
          ..write('ipaPronunciation: $ipaPronunciation, ')
          ..write('brazilianApproximation: $brazilianApproximation, ')
          ..write('phoneticTip: $phoneticTip, ')
          ..write('pluralForm: $pluralForm, ')
          ..write('verbForms: $verbForms, ')
          ..write('prepositionCase: $prepositionCase, ')
          ..write('degrees: $degrees, ')
          ..write('conjugation: $conjugation, ')
          ..write('exampleGerman: $exampleGerman, ')
          ..write('examplePortuguese: $examplePortuguese, ')
          ..write('correctCount: $correctCount, ')
          ..write('wrongCount: $wrongCount, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      germanWord,
      portugueseTranslation,
      category,
      tagDetail,
      ipaPronunciation,
      brazilianApproximation,
      phoneticTip,
      pluralForm,
      verbForms,
      prepositionCase,
      degrees,
      conjugation,
      exampleGerman,
      examplePortuguese,
      correctCount,
      wrongCount,
      lastReviewedAt,
      createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordEntry &&
          other.id == this.id &&
          other.germanWord == this.germanWord &&
          other.portugueseTranslation == this.portugueseTranslation &&
          other.category == this.category &&
          other.tagDetail == this.tagDetail &&
          other.ipaPronunciation == this.ipaPronunciation &&
          other.brazilianApproximation == this.brazilianApproximation &&
          other.phoneticTip == this.phoneticTip &&
          other.pluralForm == this.pluralForm &&
          other.verbForms == this.verbForms &&
          other.prepositionCase == this.prepositionCase &&
          other.degrees == this.degrees &&
          other.conjugation == this.conjugation &&
          other.exampleGerman == this.exampleGerman &&
          other.examplePortuguese == this.examplePortuguese &&
          other.correctCount == this.correctCount &&
          other.wrongCount == this.wrongCount &&
          other.lastReviewedAt == this.lastReviewedAt &&
          other.createdAt == this.createdAt);
}

class WordEntriesCompanion extends UpdateCompanion<WordEntry> {
  final Value<int> id;
  final Value<String> germanWord;
  final Value<String> portugueseTranslation;
  final Value<GrammarCategory> category;
  final Value<String?> tagDetail;
  final Value<String?> ipaPronunciation;
  final Value<String?> brazilianApproximation;
  final Value<String?> phoneticTip;
  final Value<String?> pluralForm;
  final Value<String?> verbForms;
  final Value<String?> prepositionCase;
  final Value<String?> degrees;
  final Value<String?> conjugation;
  final Value<String?> exampleGerman;
  final Value<String?> examplePortuguese;
  final Value<int> correctCount;
  final Value<int> wrongCount;
  final Value<DateTime?> lastReviewedAt;
  final Value<DateTime> createdAt;
  const WordEntriesCompanion({
    this.id = const Value.absent(),
    this.germanWord = const Value.absent(),
    this.portugueseTranslation = const Value.absent(),
    this.category = const Value.absent(),
    this.tagDetail = const Value.absent(),
    this.ipaPronunciation = const Value.absent(),
    this.brazilianApproximation = const Value.absent(),
    this.phoneticTip = const Value.absent(),
    this.pluralForm = const Value.absent(),
    this.verbForms = const Value.absent(),
    this.prepositionCase = const Value.absent(),
    this.degrees = const Value.absent(),
    this.conjugation = const Value.absent(),
    this.exampleGerman = const Value.absent(),
    this.examplePortuguese = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.wrongCount = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  WordEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String germanWord,
    required String portugueseTranslation,
    required GrammarCategory category,
    this.tagDetail = const Value.absent(),
    this.ipaPronunciation = const Value.absent(),
    this.brazilianApproximation = const Value.absent(),
    this.phoneticTip = const Value.absent(),
    this.pluralForm = const Value.absent(),
    this.verbForms = const Value.absent(),
    this.prepositionCase = const Value.absent(),
    this.degrees = const Value.absent(),
    this.conjugation = const Value.absent(),
    this.exampleGerman = const Value.absent(),
    this.examplePortuguese = const Value.absent(),
    this.correctCount = const Value.absent(),
    this.wrongCount = const Value.absent(),
    this.lastReviewedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : germanWord = Value(germanWord),
        portugueseTranslation = Value(portugueseTranslation),
        category = Value(category);
  static Insertable<WordEntry> custom({
    Expression<int>? id,
    Expression<String>? germanWord,
    Expression<String>? portugueseTranslation,
    Expression<String>? category,
    Expression<String>? tagDetail,
    Expression<String>? ipaPronunciation,
    Expression<String>? brazilianApproximation,
    Expression<String>? phoneticTip,
    Expression<String>? pluralForm,
    Expression<String>? verbForms,
    Expression<String>? prepositionCase,
    Expression<String>? degrees,
    Expression<String>? conjugation,
    Expression<String>? exampleGerman,
    Expression<String>? examplePortuguese,
    Expression<int>? correctCount,
    Expression<int>? wrongCount,
    Expression<DateTime>? lastReviewedAt,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (germanWord != null) 'german_word': germanWord,
      if (portugueseTranslation != null)
        'portuguese_translation': portugueseTranslation,
      if (category != null) 'category': category,
      if (tagDetail != null) 'tag_detail': tagDetail,
      if (ipaPronunciation != null) 'ipa_pronunciation': ipaPronunciation,
      if (brazilianApproximation != null)
        'brazilian_approximation': brazilianApproximation,
      if (phoneticTip != null) 'phonetic_tip': phoneticTip,
      if (pluralForm != null) 'plural_form': pluralForm,
      if (verbForms != null) 'verb_forms': verbForms,
      if (prepositionCase != null) 'preposition_case': prepositionCase,
      if (degrees != null) 'degrees': degrees,
      if (conjugation != null) 'conjugation': conjugation,
      if (exampleGerman != null) 'example_german': exampleGerman,
      if (examplePortuguese != null) 'example_portuguese': examplePortuguese,
      if (correctCount != null) 'correct_count': correctCount,
      if (wrongCount != null) 'wrong_count': wrongCount,
      if (lastReviewedAt != null) 'last_reviewed_at': lastReviewedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  WordEntriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? germanWord,
      Value<String>? portugueseTranslation,
      Value<GrammarCategory>? category,
      Value<String?>? tagDetail,
      Value<String?>? ipaPronunciation,
      Value<String?>? brazilianApproximation,
      Value<String?>? phoneticTip,
      Value<String?>? pluralForm,
      Value<String?>? verbForms,
      Value<String?>? prepositionCase,
      Value<String?>? degrees,
      Value<String?>? conjugation,
      Value<String?>? exampleGerman,
      Value<String?>? examplePortuguese,
      Value<int>? correctCount,
      Value<int>? wrongCount,
      Value<DateTime?>? lastReviewedAt,
      Value<DateTime>? createdAt}) {
    return WordEntriesCompanion(
      id: id ?? this.id,
      germanWord: germanWord ?? this.germanWord,
      portugueseTranslation:
          portugueseTranslation ?? this.portugueseTranslation,
      category: category ?? this.category,
      tagDetail: tagDetail ?? this.tagDetail,
      ipaPronunciation: ipaPronunciation ?? this.ipaPronunciation,
      brazilianApproximation:
          brazilianApproximation ?? this.brazilianApproximation,
      phoneticTip: phoneticTip ?? this.phoneticTip,
      pluralForm: pluralForm ?? this.pluralForm,
      verbForms: verbForms ?? this.verbForms,
      prepositionCase: prepositionCase ?? this.prepositionCase,
      degrees: degrees ?? this.degrees,
      conjugation: conjugation ?? this.conjugation,
      exampleGerman: exampleGerman ?? this.exampleGerman,
      examplePortuguese: examplePortuguese ?? this.examplePortuguese,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (germanWord.present) {
      map['german_word'] = Variable<String>(germanWord.value);
    }
    if (portugueseTranslation.present) {
      map['portuguese_translation'] =
          Variable<String>(portugueseTranslation.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(
          $WordEntriesTable.$convertercategory.toSql(category.value));
    }
    if (tagDetail.present) {
      map['tag_detail'] = Variable<String>(tagDetail.value);
    }
    if (ipaPronunciation.present) {
      map['ipa_pronunciation'] = Variable<String>(ipaPronunciation.value);
    }
    if (brazilianApproximation.present) {
      map['brazilian_approximation'] =
          Variable<String>(brazilianApproximation.value);
    }
    if (phoneticTip.present) {
      map['phonetic_tip'] = Variable<String>(phoneticTip.value);
    }
    if (pluralForm.present) {
      map['plural_form'] = Variable<String>(pluralForm.value);
    }
    if (verbForms.present) {
      map['verb_forms'] = Variable<String>(verbForms.value);
    }
    if (prepositionCase.present) {
      map['preposition_case'] = Variable<String>(prepositionCase.value);
    }
    if (degrees.present) {
      map['degrees'] = Variable<String>(degrees.value);
    }
    if (conjugation.present) {
      map['conjugation'] = Variable<String>(conjugation.value);
    }
    if (exampleGerman.present) {
      map['example_german'] = Variable<String>(exampleGerman.value);
    }
    if (examplePortuguese.present) {
      map['example_portuguese'] = Variable<String>(examplePortuguese.value);
    }
    if (correctCount.present) {
      map['correct_count'] = Variable<int>(correctCount.value);
    }
    if (wrongCount.present) {
      map['wrong_count'] = Variable<int>(wrongCount.value);
    }
    if (lastReviewedAt.present) {
      map['last_reviewed_at'] = Variable<DateTime>(lastReviewedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordEntriesCompanion(')
          ..write('id: $id, ')
          ..write('germanWord: $germanWord, ')
          ..write('portugueseTranslation: $portugueseTranslation, ')
          ..write('category: $category, ')
          ..write('tagDetail: $tagDetail, ')
          ..write('ipaPronunciation: $ipaPronunciation, ')
          ..write('brazilianApproximation: $brazilianApproximation, ')
          ..write('phoneticTip: $phoneticTip, ')
          ..write('pluralForm: $pluralForm, ')
          ..write('verbForms: $verbForms, ')
          ..write('prepositionCase: $prepositionCase, ')
          ..write('degrees: $degrees, ')
          ..write('conjugation: $conjugation, ')
          ..write('exampleGerman: $exampleGerman, ')
          ..write('examplePortuguese: $examplePortuguese, ')
          ..write('correctCount: $correctCount, ')
          ..write('wrongCount: $wrongCount, ')
          ..write('lastReviewedAt: $lastReviewedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WordEntriesTable wordEntries = $WordEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [wordEntries];
}

typedef $$WordEntriesTableCreateCompanionBuilder = WordEntriesCompanion
    Function({
  Value<int> id,
  required String germanWord,
  required String portugueseTranslation,
  required GrammarCategory category,
  Value<String?> tagDetail,
  Value<String?> ipaPronunciation,
  Value<String?> brazilianApproximation,
  Value<String?> phoneticTip,
  Value<String?> pluralForm,
  Value<String?> verbForms,
  Value<String?> prepositionCase,
  Value<String?> degrees,
  Value<String?> conjugation,
  Value<String?> exampleGerman,
  Value<String?> examplePortuguese,
  Value<int> correctCount,
  Value<int> wrongCount,
  Value<DateTime?> lastReviewedAt,
  Value<DateTime> createdAt,
});
typedef $$WordEntriesTableUpdateCompanionBuilder = WordEntriesCompanion
    Function({
  Value<int> id,
  Value<String> germanWord,
  Value<String> portugueseTranslation,
  Value<GrammarCategory> category,
  Value<String?> tagDetail,
  Value<String?> ipaPronunciation,
  Value<String?> brazilianApproximation,
  Value<String?> phoneticTip,
  Value<String?> pluralForm,
  Value<String?> verbForms,
  Value<String?> prepositionCase,
  Value<String?> degrees,
  Value<String?> conjugation,
  Value<String?> exampleGerman,
  Value<String?> examplePortuguese,
  Value<int> correctCount,
  Value<int> wrongCount,
  Value<DateTime?> lastReviewedAt,
  Value<DateTime> createdAt,
});

class $$WordEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $WordEntriesTable> {
  $$WordEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get germanWord => $composableBuilder(
      column: $table.germanWord, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get portugueseTranslation => $composableBuilder(
      column: $table.portugueseTranslation,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<GrammarCategory, GrammarCategory, String>
      get category => $composableBuilder(
          column: $table.category,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get tagDetail => $composableBuilder(
      column: $table.tagDetail, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ipaPronunciation => $composableBuilder(
      column: $table.ipaPronunciation,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get brazilianApproximation => $composableBuilder(
      column: $table.brazilianApproximation,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phoneticTip => $composableBuilder(
      column: $table.phoneticTip, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get pluralForm => $composableBuilder(
      column: $table.pluralForm, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get verbForms => $composableBuilder(
      column: $table.verbForms, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get prepositionCase => $composableBuilder(
      column: $table.prepositionCase,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get degrees => $composableBuilder(
      column: $table.degrees, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get conjugation => $composableBuilder(
      column: $table.conjugation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exampleGerman => $composableBuilder(
      column: $table.exampleGerman, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get examplePortuguese => $composableBuilder(
      column: $table.examplePortuguese,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get correctCount => $composableBuilder(
      column: $table.correctCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get wrongCount => $composableBuilder(
      column: $table.wrongCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastReviewedAt => $composableBuilder(
      column: $table.lastReviewedAt,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$WordEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WordEntriesTable> {
  $$WordEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get germanWord => $composableBuilder(
      column: $table.germanWord, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get portugueseTranslation => $composableBuilder(
      column: $table.portugueseTranslation,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tagDetail => $composableBuilder(
      column: $table.tagDetail, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ipaPronunciation => $composableBuilder(
      column: $table.ipaPronunciation,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get brazilianApproximation => $composableBuilder(
      column: $table.brazilianApproximation,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phoneticTip => $composableBuilder(
      column: $table.phoneticTip, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get pluralForm => $composableBuilder(
      column: $table.pluralForm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get verbForms => $composableBuilder(
      column: $table.verbForms, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get prepositionCase => $composableBuilder(
      column: $table.prepositionCase,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get degrees => $composableBuilder(
      column: $table.degrees, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get conjugation => $composableBuilder(
      column: $table.conjugation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exampleGerman => $composableBuilder(
      column: $table.exampleGerman,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get examplePortuguese => $composableBuilder(
      column: $table.examplePortuguese,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get correctCount => $composableBuilder(
      column: $table.correctCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get wrongCount => $composableBuilder(
      column: $table.wrongCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastReviewedAt => $composableBuilder(
      column: $table.lastReviewedAt,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$WordEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordEntriesTable> {
  $$WordEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get germanWord => $composableBuilder(
      column: $table.germanWord, builder: (column) => column);

  GeneratedColumn<String> get portugueseTranslation => $composableBuilder(
      column: $table.portugueseTranslation, builder: (column) => column);

  GeneratedColumnWithTypeConverter<GrammarCategory, String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get tagDetail =>
      $composableBuilder(column: $table.tagDetail, builder: (column) => column);

  GeneratedColumn<String> get ipaPronunciation => $composableBuilder(
      column: $table.ipaPronunciation, builder: (column) => column);

  GeneratedColumn<String> get brazilianApproximation => $composableBuilder(
      column: $table.brazilianApproximation, builder: (column) => column);

  GeneratedColumn<String> get phoneticTip => $composableBuilder(
      column: $table.phoneticTip, builder: (column) => column);

  GeneratedColumn<String> get pluralForm => $composableBuilder(
      column: $table.pluralForm, builder: (column) => column);

  GeneratedColumn<String> get verbForms =>
      $composableBuilder(column: $table.verbForms, builder: (column) => column);

  GeneratedColumn<String> get prepositionCase => $composableBuilder(
      column: $table.prepositionCase, builder: (column) => column);

  GeneratedColumn<String> get degrees =>
      $composableBuilder(column: $table.degrees, builder: (column) => column);

  GeneratedColumn<String> get conjugation => $composableBuilder(
      column: $table.conjugation, builder: (column) => column);

  GeneratedColumn<String> get exampleGerman => $composableBuilder(
      column: $table.exampleGerman, builder: (column) => column);

  GeneratedColumn<String> get examplePortuguese => $composableBuilder(
      column: $table.examplePortuguese, builder: (column) => column);

  GeneratedColumn<int> get correctCount => $composableBuilder(
      column: $table.correctCount, builder: (column) => column);

  GeneratedColumn<int> get wrongCount => $composableBuilder(
      column: $table.wrongCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReviewedAt => $composableBuilder(
      column: $table.lastReviewedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$WordEntriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $WordEntriesTable,
    WordEntry,
    $$WordEntriesTableFilterComposer,
    $$WordEntriesTableOrderingComposer,
    $$WordEntriesTableAnnotationComposer,
    $$WordEntriesTableCreateCompanionBuilder,
    $$WordEntriesTableUpdateCompanionBuilder,
    (WordEntry, BaseReferences<_$AppDatabase, $WordEntriesTable, WordEntry>),
    WordEntry,
    PrefetchHooks Function()> {
  $$WordEntriesTableTableManager(_$AppDatabase db, $WordEntriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> germanWord = const Value.absent(),
            Value<String> portugueseTranslation = const Value.absent(),
            Value<GrammarCategory> category = const Value.absent(),
            Value<String?> tagDetail = const Value.absent(),
            Value<String?> ipaPronunciation = const Value.absent(),
            Value<String?> brazilianApproximation = const Value.absent(),
            Value<String?> phoneticTip = const Value.absent(),
            Value<String?> pluralForm = const Value.absent(),
            Value<String?> verbForms = const Value.absent(),
            Value<String?> prepositionCase = const Value.absent(),
            Value<String?> degrees = const Value.absent(),
            Value<String?> conjugation = const Value.absent(),
            Value<String?> exampleGerman = const Value.absent(),
            Value<String?> examplePortuguese = const Value.absent(),
            Value<int> correctCount = const Value.absent(),
            Value<int> wrongCount = const Value.absent(),
            Value<DateTime?> lastReviewedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              WordEntriesCompanion(
            id: id,
            germanWord: germanWord,
            portugueseTranslation: portugueseTranslation,
            category: category,
            tagDetail: tagDetail,
            ipaPronunciation: ipaPronunciation,
            brazilianApproximation: brazilianApproximation,
            phoneticTip: phoneticTip,
            pluralForm: pluralForm,
            verbForms: verbForms,
            prepositionCase: prepositionCase,
            degrees: degrees,
            conjugation: conjugation,
            exampleGerman: exampleGerman,
            examplePortuguese: examplePortuguese,
            correctCount: correctCount,
            wrongCount: wrongCount,
            lastReviewedAt: lastReviewedAt,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String germanWord,
            required String portugueseTranslation,
            required GrammarCategory category,
            Value<String?> tagDetail = const Value.absent(),
            Value<String?> ipaPronunciation = const Value.absent(),
            Value<String?> brazilianApproximation = const Value.absent(),
            Value<String?> phoneticTip = const Value.absent(),
            Value<String?> pluralForm = const Value.absent(),
            Value<String?> verbForms = const Value.absent(),
            Value<String?> prepositionCase = const Value.absent(),
            Value<String?> degrees = const Value.absent(),
            Value<String?> conjugation = const Value.absent(),
            Value<String?> exampleGerman = const Value.absent(),
            Value<String?> examplePortuguese = const Value.absent(),
            Value<int> correctCount = const Value.absent(),
            Value<int> wrongCount = const Value.absent(),
            Value<DateTime?> lastReviewedAt = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              WordEntriesCompanion.insert(
            id: id,
            germanWord: germanWord,
            portugueseTranslation: portugueseTranslation,
            category: category,
            tagDetail: tagDetail,
            ipaPronunciation: ipaPronunciation,
            brazilianApproximation: brazilianApproximation,
            phoneticTip: phoneticTip,
            pluralForm: pluralForm,
            verbForms: verbForms,
            prepositionCase: prepositionCase,
            degrees: degrees,
            conjugation: conjugation,
            exampleGerman: exampleGerman,
            examplePortuguese: examplePortuguese,
            correctCount: correctCount,
            wrongCount: wrongCount,
            lastReviewedAt: lastReviewedAt,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WordEntriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $WordEntriesTable,
    WordEntry,
    $$WordEntriesTableFilterComposer,
    $$WordEntriesTableOrderingComposer,
    $$WordEntriesTableAnnotationComposer,
    $$WordEntriesTableCreateCompanionBuilder,
    $$WordEntriesTableUpdateCompanionBuilder,
    (WordEntry, BaseReferences<_$AppDatabase, $WordEntriesTable, WordEntry>),
    WordEntry,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WordEntriesTableTableManager get wordEntries =>
      $$WordEntriesTableTableManager(_db, _db.wordEntries);
}
