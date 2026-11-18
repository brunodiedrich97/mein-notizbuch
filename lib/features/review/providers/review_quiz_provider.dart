import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/language/study_language.dart';
import '../../study/providers/study_provider.dart';
import '../../vocabulary/models/grammar_type.dart';
import '../../vocabulary/providers/vocabulary_provider.dart';

enum QuestionKind {
  /// Substantivos: der, die ou das?
  article,

  /// Demais classes: o que significa?
  translation,
}

class QuizQuestion {
  const QuizQuestion({
    required this.word,
    required this.kind,
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });

  final WordEntry word;
  final QuestionKind kind;

  /// O que aparece na pergunta. Em perguntas de artigo vem sem o artigo.
  final String prompt;
  final List<String> options;
  final int correctIndex;
}

class ReviewQuizState {
  const ReviewQuizState({
    required this.questions,
    this.current = 0,
    this.selected,
    this.score = 0,
  });

  final List<QuizQuestion> questions;
  final int current;

  /// Opção escolhida na pergunta atual (`null` = ainda não respondeu).
  final int? selected;
  final int score;

  bool get isEmpty => questions.isEmpty;
  bool get isFinished => current >= questions.length;
  bool get answered => selected != null;
  QuizQuestion? get question => isFinished ? null : questions[current];

  ReviewQuizState copyWith({
    int? current,
    int? selected,
    bool clearSelected = false,
    int? score,
  }) {
    return ReviewQuizState(
      questions: questions,
      current: current ?? this.current,
      selected: clearSelected ? null : (selected ?? this.selected),
      score: score ?? this.score,
    );
  }
}

class ReviewQuizNotifier extends AutoDisposeAsyncNotifier<ReviewQuizState> {
  static const int sessionSize = 10;
  final Random _random = Random();

  @override
  Future<ReviewQuizState> build() async {
    // `read`, e não `watch`: cada resposta grava no banco, e a sessão não
    // deve recomeçar quando a lista de palavras é atualizada.
    final words = await ref.read(wordListProvider.future);
    // Só as palavras do deck aberto (ou todas, se nenhum deck foi aberto).
    final deckId = ref.read(deckScopeProvider);
    final pool = deckId == null
        ? words
        : words.where((w) => deckOf(w) == deckId).toList();
    return ReviewQuizState(questions: _buildQuestions(pool, words));
  }


  /// [words] são as palavras perguntadas; [all] fornece as traduções
  /// usadas como opções erradas (mais variedade num deck pequeno).
  List<QuizQuestion> _buildQuestions(
    List<WordEntry> words,
    List<WordEntry> all,
  ) {
    if (words.isEmpty) return const [];

    final pool = [...words]..shuffle(_random);
    pool.sort((a, b) => studyPriority(b).compareTo(studyPriority(a)));
    final chosen = pool.take(sessionSize).toList()..shuffle(_random);

    final translations =
        all.map((w) => w.portugueseTranslation.trim()).toSet().toList();

    final questions = <QuizQuestion>[];
    for (final word in chosen) {
      // Pergunta de artigo só em idiomas com gênero (der/die/das).
      final question = word.category.article != null
          ? _articleQuestion(word)
          : _translationQuestion(word, translations);
      if (question != null) questions.add(question);
    }
    return questions;
  }

  QuizQuestion _articleQuestion(WordEntry word) {
    // Os artigos do idioma de estudo, na ordem masculino, feminino, neutro.
    final options = StudyLanguages.active.articles.values.toList();
    return QuizQuestion(
      word: word,
      kind: QuestionKind.article,
      prompt: stripArticle(word.germanWord),
      options: options,
      correctIndex: options.indexOf(word.category.article!),
    );
  }

  /// Precisa de pelo menos uma tradução diferente para servir de distrator.
  QuizQuestion? _translationQuestion(WordEntry word, List<String> all) {
    final correct = word.portugueseTranslation.trim();
    final distractors = all.where((t) => t != correct).toList()
      ..shuffle(_random);
    if (distractors.isEmpty) return null;

    final options = [correct, ...distractors.take(3)]..shuffle(_random);
    return QuizQuestion(
      word: word,
      kind: QuestionKind.translation,
      prompt: word.germanWord,
      options: options,
      correctIndex: options.indexOf(correct),
    );
  }

  Future<void> answer(int optionIndex) async {
    final s = state.valueOrNull;
    if (s == null || s.isFinished || s.answered) return;

    final q = s.question!;
    final correct = optionIndex == q.correctIndex;
    final db = ref.read(databaseProvider);
    state = AsyncData(
      s.copyWith(selected: optionIndex, score: s.score + (correct ? 1 : 0)),
    );
    await db.recordReview(q.word.id, correct: correct);
  }

  void next() {
    final s = state.valueOrNull;
    if (s == null || !s.answered) return;
    state = AsyncData(s.copyWith(current: s.current + 1, clearSelected: true));
  }

  /// Monta uma nova sessão, já com as prioridades atualizadas.
  void restart() => ref.invalidateSelf();
}

final reviewQuizProvider =
    AsyncNotifierProvider.autoDispose<ReviewQuizNotifier, ReviewQuizState>(
  ReviewQuizNotifier.new,
);
