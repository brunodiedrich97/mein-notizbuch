import '../../../core/language/study_language.dart';
import '../../vocabulary/models/grammar_type.dart';

/// Comparação simples de frases, feita no aparelho (sem internet).
///
/// Não "entende" o idioma: compara palavra por palavra com a resposta
/// esperada e reconhece alguns erros comuns para explicar (contrações,
/// artigos, maiúsculas e letras especiais), com as regras do idioma de
/// estudo.

/// Minúsculas e sem trema/ß: "Ärzte" → "arzte".
String foldGerman(String s) => s
    .toLowerCase()
    .replaceAll('ä', 'a')
    .replaceAll('ö', 'o')
    .replaceAll('ü', 'u')
    .replaceAll('ß', 'ss');

/// Palavras da frase, sem pontuação nas pontas.
List<String> tokenize(String sentence) {
  final punctuation = RegExp(r'^[^\wäöüÄÖÜß]+|[^\wäöüÄÖÜß]+$');
  return [
    for (final raw in sentence.trim().split(RegExp(r'\s+')))
      if (raw.replaceAll(punctuation, '').isNotEmpty)
        raw.replaceAll(punctuation, ''),
  ];
}

/// A frase usa a palavra da ficha? Compara pelo radical: "Arzt" aceita
/// "Ärzte"; "gehen" aceita "gehe" e "geht".
bool sentenceUsesWord(String sentence, String germanWord, GrammarCategory c) {
  var stem = foldGerman(stripArticle(germanWord));
  if (c == GrammarCategory.verb && stem.length > 4) {
    if (stem.endsWith('en')) {
      stem = stem.substring(0, stem.length - 2);
    } else if (stem.endsWith('n')) {
      stem = stem.substring(0, stem.length - 1);
    }
  }
  if (stem.isEmpty) return false;
  return foldGerman(sentence).contains(stem);
}

/// Uma palavra na comparação. [ok] = igual à outra frase.
class DiffToken {
  const DiffToken(this.text, {required this.ok});
  final String text;
  final bool ok;
}

/// Resultado da comparação entre a resposta e a frase esperada.
class SentenceCheck {
  const SentenceCheck({
    required this.answer,
    required this.expected,
    required this.differences,
    required this.notes,
  });

  /// Palavras da resposta; as erradas ou a mais têm `ok == false`.
  final List<DiffToken> answer;

  /// Palavras esperadas; as que faltaram na resposta têm `ok == false`.
  final List<DiffToken> expected;

  final int differences;

  /// Explicações curtas para erros reconhecidos (no máximo 3).
  final List<String> notes;

  bool get isPerfect => differences == 0;
}

/// Compara [answer] com [expected]. Maiúsculas e trema contam como erro
/// (são parte da escrita correta), mas ganham uma explicação.
SentenceCheck checkSentence(String answer, String expected) {
  final a = tokenize(answer);
  final e = tokenize(expected);

  // Maior subsequência comum, palavra por palavra.
  final lcs = List.generate(a.length + 1, (_) => List.filled(e.length + 1, 0));
  for (var i = a.length - 1; i >= 0; i--) {
    for (var j = e.length - 1; j >= 0; j--) {
      lcs[i][j] = a[i] == e[j]
          ? lcs[i + 1][j + 1] + 1
          : (lcs[i + 1][j] >= lcs[i][j + 1] ? lcs[i + 1][j] : lcs[i][j + 1]);
    }
  }

  final answerTokens = <DiffToken>[];
  final expectedTokens = <DiffToken>[];
  // Trechos divergentes, pareados para gerar as notas.
  final pairs = <(List<String>, List<String>)>[];
  var wrong = <String>[];
  var missing = <String>[];

  void flush() {
    if (wrong.isNotEmpty || missing.isNotEmpty) pairs.add((wrong, missing));
    wrong = [];
    missing = [];
  }

  var i = 0;
  var j = 0;
  while (i < a.length || j < e.length) {
    if (i < a.length && j < e.length && a[i] == e[j]) {
      flush();
      answerTokens.add(DiffToken(a[i], ok: true));
      expectedTokens.add(DiffToken(e[j], ok: true));
      i++;
      j++;
    } else if (j < e.length &&
        (i == a.length || lcs[i][j + 1] >= lcs[i + 1][j])) {
      expectedTokens.add(DiffToken(e[j], ok: false));
      missing.add(e[j]);
      j++;
    } else {
      answerTokens.add(DiffToken(a[i], ok: false));
      wrong.add(a[i]);
      i++;
    }
  }
  flush();

  final differences = pairs.fold<int>(
    0,
    (sum, p) => sum + (p.$1.length > p.$2.length ? p.$1.length : p.$2.length),
  );

  final notes = <String>{};
  for (final (got, want) in pairs) {
    for (var k = 0; k < want.length; k++) {
      final w = want[k];
      final g = k < got.length ? got[k] : null;
      final note = _explain(g, w, got);
      if (note != null) notes.add(note);
    }
  }

  return SentenceCheck(
    answer: answerTokens,
    expected: expectedTokens,
    differences: differences,
    notes: notes.take(3).toList(),
  );
}

String? _explain(String? got, String want, List<String> gotBlock) {
  final wantLower = want.toLowerCase();

  // Contração: escreveu "zu" (ou "zu dem") no lugar de "zum".
  final language = StudyLanguages.active;
  final contraction = language.contractions[wantLower];
  if (contraction != null) {
    final (prep, article) = contraction;
    final block = gotBlock.map((t) => t.toLowerCase()).toList();
    if (block.contains(prep) || block.contains(article)) {
      return '"$wantLower" = $prep + $article. Em ${language.namePt}, essa '
          'junção é obrigatória.';
    }
  }

  if (got == null) return null;
  final gotLower = got.toLowerCase();

  // Artigo no caso errado.
  if (language.articleForms.contains(gotLower) &&
      language.articleForms.contains(wantLower)) {
    return 'Artigo: o esperado é "$want", e não "$got". Confira o caso '
        '(nominativo, acusativo, dativo) e o gênero da palavra.';
  }

  // Só a maiúscula/minúscula está diferente.
  if (gotLower == wantLower) {
    final upper = want[0] == want[0].toUpperCase();
    if (!upper) return '"$want" é escrita com minúscula.';
    return language.capitalizeNouns
        ? '"$want" começa com maiúscula: em ${language.namePt}, todo '
            'substantivo é escrito com inicial maiúscula.'
        : '"$want" começa com maiúscula.';
  }

  // Só o trema (ou ß) está diferente.
  if (foldGerman(got) == foldGerman(want)) {
    return 'Trema: o esperado é "$want", e não "$got".';
  }
  return null;
}
