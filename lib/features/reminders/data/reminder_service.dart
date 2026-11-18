import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/database/app_database.dart';
import '../../../l10n/app_strings.dart';
import '../models/reminder_content.dart';
import 'daily_word_plan.dart';

/// Notificação diária com uma palavra do Notizbuch.
///
/// Uma notificação agendada não escolhe a palavra na hora de aparecer. Por
/// isso, o app agenda os próximos [daysAhead] dias, seguindo o plano da
/// palavra do dia ([DailyWordPlan]), e refaz a fila sempre que é aberto.
class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  static const int daysAhead = 14;
  static const int _firstId = 1000;
  static const int _testId = 999;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Future<void>? _init;
  final Random _random = Random();

  /// Chamado ao tocar numa notificação com o app aberto.
  void Function(int wordId)? onOpenWord;

  int? _launchWordId;

  /// Palavra da notificação que abriu o app (lida uma única vez).
  int? takeLaunchWordId() {
    final id = _launchWordId;
    _launchWordId = null;
    return id;
  }

  Future<void> init() => _init ??= _initialize();

  Future<void> _initialize() async {
    tzdata.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Sem o fuso do aparelho, os horários ficam em UTC.
    }

    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        // A permissão é pedida só ao ligar o lembrete, não ao abrir o app.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final id = int.tryParse(response.payload ?? '');
        if (id != null) onOpenWord?.call(id);
      },
    );

    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _launchWordId = int.tryParse(launch!.notificationResponse?.payload ?? '');
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  /// Pede a permissão de notificações (Android 13+ e iOS). `true` se
  /// liberada.
  Future<bool> requestPermission() async {
    await init();
    if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, sound: true) ?? false;
    }
    return await _android?.requestNotificationsPermission() ?? true;
  }

  /// Texto principal: duas linhas no iOS; no Android, uma linha em HTML
  /// (a notificação recolhida só mostra a primeira linha do texto).
  static String _body(ReminderContent c) =>
      Platform.isIOS ? c.twoLines : c.oneLineHtml;

  NotificationDetails _details(ReminderContent c) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_word',
        tr.reminderChannel,
        channelDescription: tr.reminderChannelDescription,
        icon: 'ic_notification',
        color: const Color(0xFF111827),
        // Classe em itálico (HTML). Recolhida: tudo numa linha (texto
        // principal); expandida: classe e significado em duas linhas.
        styleInformation: BigTextStyleInformation(
          c.twoLinesHtml,
          htmlFormatBigText: true,
          htmlFormatContent: true,
          contentTitle: c.title,
        ),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentSound: true,
        threadIdentifier: 'daily_word',
      ),
    );
  }

  /// Escolhe [count] palavras ao acaso, sem repetir enquanto houver
  /// palavras novas (usado no "Enviar um teste agora").
  List<WordEntry> pickWords(List<WordEntry> words, int count) {
    if (words.isEmpty) return const [];
    final picked = <WordEntry>[];
    var bag = <WordEntry>[];
    while (picked.length < count) {
      if (bag.isEmpty) {
        bag = [...words]..shuffle(_random);
        // Evita a mesma palavra em dois dias seguidos ao recomeçar.
        if (bag.length > 1 && picked.isNotEmpty && bag.first == picked.last) {
          bag.add(bag.removeAt(0));
        }
      }
      picked.add(bag.removeAt(0));
    }
    return picked;
  }

  /// Agenda a palavra de cada dia do [plan] às [hour]:[minute] (os dias
  /// cujo horário já passou ficam de fora).
  Future<void> scheduleDaily({
    required List<DailyWord> plan,
    required int hour,
    required int minute,
    Map<int, WordClass> classes = const {},
  }) async {
    await init();
    await cancelScheduled();

    final now = tz.TZDateTime.now(tz.local);
    for (var i = 0; i < plan.length && i < daysAhead; i++) {
      final d = plan[i].date;
      // O construtor respeita o horário de verão (somar 24 h mudaria a hora).
      final when = tz.TZDateTime(tz.local, d.year, d.month, d.day, hour, minute);
      if (!when.isAfter(now)) continue;
      final word = plan[i].word;
      final content = ReminderContent.fromWord(
        word,
        customClass: classes[word.customClassId],
      );
      await _plugin.zonedSchedule(
        _firstId + i,
        content.title,
        _body(content),
        when,
        _details(content),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '${word.id}',
      );
    }
  }

  Future<void> cancelScheduled() async {
    await init();
    for (var i = 0; i < daysAhead; i++) {
      await _plugin.cancel(_firstId + i);
    }
  }

  /// Mostra agora uma notificação com [word] (botão "Enviar um teste").
  Future<void> showNow(WordEntry word, {WordClass? customClass}) async {
    await init();
    final content = ReminderContent.fromWord(word, customClass: customClass);
    await _plugin.show(
      _testId,
      content.title,
      _body(content),
      _details(content),
      payload: '${word.id}',
    );
  }
}
