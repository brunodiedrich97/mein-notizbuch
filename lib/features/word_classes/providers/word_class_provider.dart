import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../vocabulary/providers/vocabulary_provider.dart';

/// Classes criadas pelo usuário, em ordem de criação.
final wordClassListProvider = StreamProvider<List<WordClass>>((ref) {
  return ref.watch(databaseProvider).watchWordClasses();
});

/// As mesmas classes, por id.
final wordClassMapProvider = Provider<Map<int, WordClass>>((ref) {
  final list = ref.watch(wordClassListProvider).valueOrNull ?? const [];
  return {for (final c in list) c.id: c};
});
