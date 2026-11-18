import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/app_database.dart';
import '../../../core/language/study_language_provider.dart';
import '../../reminders/data/daily_word_plan.dart';
import '../../vocabulary/providers/vocabulary_provider.dart';
import '../../word_classes/providers/word_class_provider.dart';
import '../data/daily_word_widget.dart';
import 'pinned_word_provider.dart';

/// Atualiza o widget com o plano da palavra do dia (ao abrir o app), ou com
/// a palavra fixa do idioma de estudo, se houver uma.
Future<void> refreshDailyWordWidget(WidgetRef ref) async {
  if (!DailyWordWidget.isSupported) return;
  final words = await ref.read(wordListProvider.future);
  final classes = await ref.read(wordClassListProvider.future);
  final plan = await DailyWordPlan.ensure(words);
  final pinnedId = await PinnedWordController.savedFor(
    ref.read(studyLanguageProvider),
  );
  WordEntry? pinned;
  for (final w in words) {
    if (w.id == pinnedId) pinned = w;
  }
  await DailyWordWidget.publish(
    plan,
    {for (final c in classes) c.id: c},
    pinned: pinned,
  );
}

final widgetInviteProvider =
    NotifierProvider<WidgetInviteController, bool>(WidgetInviteController.new);

/// Convite para colocar o widget na tela inicial, sem ser insistente:
/// aparece no máximo [maxShows] vezes, com pelo menos [gap] entre elas, e
/// nunca se o widget já estiver na tela inicial. O estado é `true` quando o
/// cartão deve aparecer.
class WidgetInviteController extends Notifier<bool> {
  static const int maxShows = 3;
  static const Duration gap = Duration(days: 7);
  static const _kCount = 'widget.invite.count';
  static const _kLastAt = 'widget.invite.lastAt';

  @override
  bool build() => false;

  /// Decide se o cartão aparece (chamado ao abrir a tela inicial).
  Future<void> check() async {
    if (!DailyWordWidget.isSupported) return;
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_kCount) ?? 0;
    final last = prefs.getInt(_kLastAt);
    final due = last == null ||
        DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(last)) >=
            gap;
    state = count < maxShows && due && !await DailyWordWidget.isInstalled();
  }

  /// "Agora não", ✕ ou "Adicionar": conta como uma vez mostrado e esconde.
  Future<void> dismiss() async {
    state = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCount, (prefs.getInt(_kCount) ?? 0) + 1);
    await prefs.setInt(_kLastAt, DateTime.now().millisecondsSinceEpoch);
  }
}
