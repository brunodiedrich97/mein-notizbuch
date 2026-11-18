import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/app_database.dart';

/// Palavra escolhida para um dia.
class DailyWord {
  const DailyWord(this.date, this.word);

  /// Dia (meia-noite, horário local).
  final DateTime date;
  final WordEntry word;
}

/// Plano da palavra do dia: uma palavra por data, para os próximos
/// [daysAhead] dias, salvo no aparelho. A notificação e o widget leem o
/// mesmo plano, então mostram sempre a mesma palavra.
///
/// Datas já planejadas não mudam ao abrir o app; só entram dias novos (e
/// trocam as palavras que foram excluídas).
class DailyWordPlan {
  DailyWordPlan._();

  static const int daysAhead = 14;
  static const _key = 'dailyWord.plan';

  static final Random _random = Random();

  /// Garante uma de cada vez (notificação e widget pedem o plano juntos).
  static Future<List<DailyWord>> _queue = Future.value(const []);

  static String dateKey(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  /// Completa e devolve o plano de hoje até hoje + [daysAhead] - 1.
  static Future<List<DailyWord>> ensure(List<WordEntry> words) {
    final next = _queue.then((_) => _ensure(words));
    _queue = next.catchError((Object _) => const <DailyWord>[]);
    return next;
  }

  static Future<List<DailyWord>> _ensure(List<WordEntry> words) async {
    final prefs = await SharedPreferences.getInstance();
    if (words.isEmpty) {
      await prefs.remove(_key);
      return const [];
    }
    final byId = {for (final w in words) w.id: w};

    final saved = <String, int>{};
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        (jsonDecode(raw) as Map<String, dynamic>)
            .forEach((k, v) => saved[k] = v as int);
      } catch (_) {
        // Plano corrompido: recomeça.
      }
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = [
      for (var i = 0; i < daysAhead; i++)
        DateTime(today.year, today.month, today.day + i),
    ];

    // Mantém as escolhas válidas; o resto é sorteado sem repetir enquanto
    // houver palavras que ainda não estão no plano.
    final plan = <String, int>{};
    for (final d in days) {
      final id = saved[dateKey(d)];
      if (id != null && byId.containsKey(id)) plan[dateKey(d)] = id;
    }
    var bag = <int>[];
    int? previous;
    for (final d in days) {
      final key = dateKey(d);
      if (plan.containsKey(key)) {
        previous = plan[key];
        continue;
      }
      if (bag.isEmpty) {
        final used = plan.values.toSet();
        bag = [
          for (final w in words)
            if (!used.contains(w.id)) w.id,
        ];
        if (bag.isEmpty) bag = [for (final w in words) w.id];
        bag.shuffle(_random);
      }
      // Evita a mesma palavra em dois dias seguidos.
      if (bag.length > 1 && bag.first == previous) bag.add(bag.removeAt(0));
      final id = bag.removeAt(0);
      plan[key] = id;
      previous = id;
    }

    await prefs.setString(_key, jsonEncode(plan));
    return [
      for (final d in days) DailyWord(d, byId[plan[dateKey(d)]]!),
    ];
  }
}
