import 'package:deutsch_notizbuch/features/vocabulary/models/grammar_type.dart';
import 'package:deutsch_notizbuch/features/vocabulary/models/word_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WordParser', () {
    test('reconhece "der" e põe o substantivo em maiúscula', () {
      final p = WordParser.parse('  Der   hund ');
      expect(p.category, GrammarCategory.masculineNoun);
      expect(p.lemma, 'Hund');
      expect(p.display, 'der Hund');
      expect(p.isGuess, isFalse);
    });

    test('marca "die" como ambíguo (pode ser plural)', () {
      final p = WordParser.parse('die Lampe');
      expect(p.category, GrammarCategory.feminineNoun);
      expect(p.articleIsAmbiguous, isTrue);
    });

    test('reconhece "das"', () {
      expect(WordParser.parse('das Buch').category, GrammarCategory.neuterNoun);
    });

    test('sugere verbo para infinitivos', () {
      for (final v in ['gehen', 'sammeln', 'wandern']) {
        expect(WordParser.parse(v).category, GrammarCategory.verb, reason: v);
      }
    });

    test('não confunde "gern" ou "schön" com verbo', () {
      expect(WordParser.parse('gern').category, GrammarCategory.other);
      expect(WordParser.parse('schön').category, GrammarCategory.other);
    });

    test('artigo sozinho não vira substantivo', () {
      expect(WordParser.parse('der').category, isNot(GrammarCategory.masculineNoun));
    });
  });

  test('stripArticle remove só artigos', () {
    expect(stripArticle('das Buch'), 'Buch');
    expect(stripArticle('gehen'), 'gehen');
    expect(stripArticle('am Ende'), 'am Ende');
  });
}
