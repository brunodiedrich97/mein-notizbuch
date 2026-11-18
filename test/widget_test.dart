import 'package:deutsch_notizbuch/core/database/app_database.dart';
import 'package:deutsch_notizbuch/core/theme/app_theme.dart';
import 'package:deutsch_notizbuch/features/vocabulary/models/grammar_type.dart';
import 'package:deutsch_notizbuch/features/vocabulary/presentation/widgets/flashcard_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a ficha mostra palavra, classe, plural e exemplo',
      (tester) async {
    final word = WordEntry(
      id: 1,
      germanWord: 'der Hund',
      portugueseTranslation: 'o cachorro',
      category: GrammarCategory.masculineNoun,
      ipaPronunciation: '[deːɐ̯ hʊnt]',
      brazilianApproximation: 'dér HUNT',
      pluralForm: 'die Hunde',
      exampleGerman: 'Der Hund schläft im Garten.',
      examplePortuguese: 'O cachorro dorme no jardim.',
      correctCount: 0,
      wrongCount: 0,
      createdAt: DateTime(2026),
      language: 'de',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: FlashcardCard(word: word)),
      ),
    );

    expect(find.text('der Hund'), findsOneWidget);
    expect(find.text('substantivo · masculino'), findsOneWidget);
    expect(find.text('Der Hund schläft im Garten.'), findsOneWidget);
    expect(find.textContaining('die Hunde', findRichText: true), findsOneWidget);
  });

  testWidgets('a ficha de verbo mostra o detalhe da classe e o presente',
      (tester) async {
    final word = WordEntry(
      id: 2,
      germanWord: 'gehen',
      portugueseTranslation: 'ir (a pé)',
      category: GrammarCategory.verb,
      tagDetail: 'irregular',
      verbForms: 'ging · ist gegangen',
      conjugation: 'ich gehe · du gehst · er geht\nwir gehen · ihr geht · sie gehen',
      correctCount: 0,
      wrongCount: 0,
      createdAt: DateTime(2026),
      language: 'de',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: FlashcardCard(word: word)),
      ),
    );

    expect(find.text('verbo · irregular'), findsOneWidget);
    expect(find.text('ging · ist gegangen · ir (a pé)'), findsOneWidget);
    expect(find.text('PRESENTE'), findsOneWidget);
    expect(find.text('wir gehen · ihr geht · sie gehen'), findsOneWidget);
  });
}
