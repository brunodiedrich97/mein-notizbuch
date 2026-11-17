import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../models/study_settings.dart';

/// Configurações da sessão. Ficam guardadas enquanto o app está aberto.
final studySettingsProvider =
    StateProvider<StudySettings>((ref) => const StudySettings());

/// Prioridade de estudo: palavras erradas e nunca revisadas vêm primeiro.
/// Usada também na revisão.
int studyPriority(WordEntry w) =>
    w.wrongCount * 2 - w.correctCount + (w.lastReviewedAt == null ? 2 : 0);

/// Monta a lista de fichas de uma sessão a partir de [pool] (as palavras do
/// deck aberto, ou todas).
List<WordEntry> buildSession(
  List<WordEntry> pool,
  StudySettings settings, {
  Random? random,
}) {
  final rnd = random ?? Random();
  final list =
      pool.where((w) => settings.filter.matches(w.category)).toList();

  switch (settings.order) {
    case SessionOrder.smart:
      // Embaralha antes para que empates não saiam sempre na mesma ordem.
      list
        ..shuffle(rnd)
        ..sort((a, b) => studyPriority(b).compareTo(studyPriority(a)));
    case SessionOrder.random:
      list.shuffle(rnd);
    case SessionOrder.recent:
      list.sort((a, b) {
        final byDate = b.createdAt.compareTo(a.createdAt);
        return byDate != 0 ? byDate : b.id.compareTo(a.id);
      });
  }

  final size = settings.size;
  return size == null ? list : list.take(size).toList();
}
