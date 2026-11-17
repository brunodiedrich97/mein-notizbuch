import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../vocabulary/providers/vocabulary_provider.dart';
import '../data/reminder_service.dart';

class ReminderState {
  const ReminderState({
    this.loaded = false,
    this.enabled = false,
    this.hour = 9,
    this.minute = 0,
  });

  final bool loaded;
  final bool enabled;
  final int hour;
  final int minute;

  /// "09:00".
  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  ReminderState copyWith({bool? enabled, int? hour, int? minute}) {
    return ReminderState(
      loaded: true,
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }
}

final reminderProvider =
    NotifierProvider<ReminderController, ReminderState>(ReminderController.new);

/// Liga/desliga o lembrete diário, guarda o horário e mantém a fila de
/// notificações agendadas.
class ReminderController extends Notifier<ReminderState> {
  static const _kEnabled = 'reminder.enabled';
  static const _kHour = 'reminder.hour';
  static const _kMinute = 'reminder.minute';

  ReminderService get _service => ReminderService.instance;

  @override
  ReminderState build() {
    _load();
    return const ReminderState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = ReminderState(
      loaded: true,
      enabled: prefs.getBool(_kEnabled) ?? false,
      hour: prefs.getInt(_kHour) ?? 9,
      minute: prefs.getInt(_kMinute) ?? 0,
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, state.enabled);
    await prefs.setInt(_kHour, state.hour);
    await prefs.setInt(_kMinute, state.minute);
  }

  /// Liga ou desliga. Retorna `false` se a permissão de notificações for
  /// negada (o lembrete continua desligado).
  Future<bool> setEnabled(bool enabled) async {
    if (enabled && !await _service.requestPermission()) return false;
    state = state.copyWith(enabled: enabled);
    await _save();
    await refresh();
    return true;
  }

  Future<void> setTime(int hour, int minute) async {
    state = state.copyWith(hour: hour, minute: minute);
    await _save();
    await refresh();
  }

  /// Refaz a fila de notificações (chamado ao abrir o app e ao mudar os
  /// ajustes), com as palavras atuais do banco.
  Future<void> refresh() async {
    if (!state.loaded) await _load();
    if (!state.enabled) {
      await _service.cancelScheduled();
      return;
    }
    final words = await ref.read(wordListProvider.future);
    await _service.scheduleDaily(
      words: words,
      hour: state.hour,
      minute: state.minute,
    );
  }

  /// Mostra uma notificação agora, com uma palavra qualquer. Retorna
  /// `false` se não houver palavras ou permissão.
  Future<bool> sendTest() async {
    final words = await ref.read(wordListProvider.future);
    if (words.isEmpty || !await _service.requestPermission()) return false;
    await _service.showNow(_service.pickWords(words, 1).first);
    return true;
  }
}
