import 'dart:convert';
import 'dart:io' show Platform;

import 'package:home_widget/home_widget.dart';

import '../../../core/database/app_database.dart';
import '../../../l10n/app_strings.dart';
import '../../reminders/data/daily_word_plan.dart';
import '../../reminders/models/reminder_content.dart';
import '../../word_classes/presentation/word_appearance.dart';

/// Ponte com o widget nativo "Palavra do dia" (Android).
///
/// O app grava o plano dos próximos dias (palavra, classe, significado e
/// cores); o widget, em Kotlin (`DailyWordWidgetProvider`), escolhe sozinho
/// a entrada do dia, inclusive com o app fechado.
class DailyWordWidget {
  DailyWordWidget._();

  static const String _provider = 'DailyWordWidgetProvider';
  static const String _qualifiedProvider =
      'com.brunodiedrich.mein_notizbuch.DailyWordWidgetProvider';
  static const String _dataKey = 'daily_words';

  /// Por enquanto só no Android (no iOS, exige App Group, da conta paga).
  static bool get isSupported => Platform.isAndroid;

  /// Chamado ao tocar no widget com o app aberto.
  static void Function(int wordId)? onOpenWord;

  static int? _launchWordId;

  /// Palavra do widget que abriu o app (lida uma única vez).
  static int? takeLaunchWordId() {
    final id = _launchWordId;
    _launchWordId = null;
    return id;
  }

  static int? _wordIdOf(Uri? uri) =>
      uri == null ? null : int.tryParse(uri.queryParameters['id'] ?? '');

  /// Liga o toque no widget à abertura da ficha.
  static Future<void> init() async {
    if (!isSupported) return;
    try {
      _launchWordId =
          _wordIdOf(await HomeWidget.initiallyLaunchedFromHomeWidget());
      HomeWidget.widgetClicked.listen((uri) {
        final id = _wordIdOf(uri);
        if (id != null) onOpenWord?.call(id);
      });
    } catch (_) {
      // Sem o plugin (ex.: testes), o widget só não abre a ficha.
    }
  }

  /// Envia o [plan] para o widget e pede para ele se redesenhar. Com
  /// [pinned], todos os dias mostram essa palavra (palavra fixa).
  static Future<void> publish(
    List<DailyWord> plan,
    Map<int, WordClass> classes, {
    WordEntry? pinned,
  }) async {
    if (!isSupported) return;
    final days = [
      for (final day in plan)
        pinned == null ? day : DailyWord(day.date, pinned),
    ];
    final entries = [
      for (final day in days)
        _entry(
          day,
          classes[day.word.customClassId],
          pinned: pinned != null,
        ),
    ];
    await HomeWidget.saveWidgetData<String>(_dataKey, jsonEncode(entries));
    await HomeWidget.updateWidget(
      androidName: _provider,
      qualifiedAndroidName: _qualifiedProvider,
    );
  }

  static Map<String, Object> _entry(
    DailyWord day,
    WordClass? custom, {
    required bool pinned,
  }) {
    final word = day.word;
    final content = ReminderContent.fromWord(word, customClass: custom);
    final light = appearanceFor(word.category, custom, isDark: false);
    final dark = appearanceFor(word.category, custom, isDark: true);
    return {
      'date': DailyWordPlan.dateKey(day.date),
      // "ter, 18/11" (ou "fixada"), no idioma do app.
      'label': pinned ? tr.pinnedLabel : tr.widgetDate(day.date),
      'pinned': pinned,
      'id': word.id,
      'word': word.germanWord,
      'category': content.category,
      'meaning': content.meaning,
      'colorLight': light.titleColor.toARGB32(),
      'colorDark': dark.titleColor.toARGB32(),
    };
  }

  /// O widget já está na tela inicial?
  static Future<bool> isInstalled() async {
    if (!isSupported) return false;
    try {
      return (await HomeWidget.getInstalledWidgets()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// O launcher aceita fixar o widget a pedido do app (Android 8+)?
  static Future<bool> canRequestPin() async {
    if (!isSupported) return false;
    try {
      return await HomeWidget.isRequestPinWidgetSupported() ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Abre a janela do sistema "Adicionar à tela inicial?".
  static Future<void> requestPin() {
    return HomeWidget.requestPinWidget(
      androidName: _provider,
      qualifiedAndroidName: _qualifiedProvider,
    );
  }
}
