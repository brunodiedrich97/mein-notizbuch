import 'dart:io' show Platform;
import 'dart:math';

import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/database/app_database.dart';
import '../models/reminder_content.dart';

/// Notificação diária com uma palavra do Notizbuch.
///
/// Uma notificação agendada não escolhe a palavra na hora de aparecer. Por
/// isso, o app agenda os próximos [daysAhead] dias, cada um com uma palavra,
/// e refaz a fila sempre que é aberto.
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

  NotificationDetails _details(ReminderContent c) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_word',
        'Palavra do dia',
        channelDescription: 'Uma palavra do seu Notizbuch por dia.',
        icon: 'ic_notification',
        color: const Color(0xFF111827),
        styleInformation: BigTextStyleInformation(
          c.body,
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

  /// Escolhe [count] palavras, sem repetir enquanto houver palavras novas.
  ///
  /// Hoje a escolha é aleatória. Com a repetição espaçada, as palavras mais
  /// difíceis (ou que vencem no dia) passam a ter prioridade aqui.
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

  /// Agenda os próximos [daysAhead] dias às [hour]:[minute].
  Future<void> scheduleDaily({
    required List<WordEntry> words,
    required int hour,
    required int minute,
  }) async {
    await init();
    await cancelScheduled();
    if (words.isEmpty) return;

    final now = tz.TZDateTime.now(tz.local);
    final startsToday =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute)
            .isAfter(now);
    final chosen = pickWords(words, daysAhead);

    for (var i = 0; i < chosen.length; i++) {
      final day = now.day + i + (startsToday ? 0 : 1);
      // O construtor ajusta dias além do fim do mês e respeita o horário de
      // verão (somar 24 h mudaria a hora).
      final when = tz.TZDateTime(tz.local, now.year, now.month, day, hour, minute);
      final content = ReminderContent.fromWord(chosen[i]);
      await _plugin.zonedSchedule(
        _firstId + i,
        content.title,
        content.body,
        when,
        _details(content),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '${chosen[i].id}',
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
  Future<void> showNow(WordEntry word) async {
    await init();
    final content = ReminderContent.fromWord(word);
    await _plugin.show(
      _testId,
      content.title,
      content.body,
      _details(content),
      payload: '${word.id}',
    );
  }
}
