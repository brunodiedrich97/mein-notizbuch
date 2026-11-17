import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../vocabulary/providers/vocabulary_provider.dart';

/// Todas as frases, das mais novas para as mais antigas.
final sentenceListProvider = StreamProvider<List<Sentence>>((ref) {
  return ref.watch(databaseProvider).watchSentences();
});

/// Frases de uma palavra ("Minhas frases" da ficha).
final sentencesOfWordProvider =
    Provider.family<List<Sentence>, int>((ref, wordId) {
  final all = ref.watch(sentenceListProvider).valueOrNull ?? const [];
  return [for (final s in all) if (s.wordId == wordId) s];
});
