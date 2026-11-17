import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../vocabulary/providers/vocabulary_provider.dart';
import '../data/drive_backup_service.dart';

/// Estado do backup no Google Drive.
class BackupState {
  const BackupState({
    this.loaded = false,
    this.email,
    this.lastBackupAt,
    this.busy = false,
  });

  /// As preferências já foram lidas.
  final bool loaded;

  /// Conta conectada (`null` = backup desligado).
  final String? email;
  final DateTime? lastBackupAt;

  /// Enviando, listando ou restaurando.
  final bool busy;

  bool get connected => email != null;

  BackupState copyWith({
    bool? loaded,
    String? email,
    bool clearEmail = false,
    DateTime? lastBackupAt,
    bool? busy,
  }) {
    return BackupState(
      loaded: loaded ?? this.loaded,
      email: clearEmail ? null : (email ?? this.email),
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      busy: busy ?? this.busy,
    );
  }
}

final backupProvider =
    NotifierProvider<BackupController, BackupState>(BackupController.new);

/// Conecta a conta, envia backups (na hora e um por dia) e restaura.
class BackupController extends Notifier<BackupState> {
  static const int keepBackups = 30;
  static const _kEmail = 'backup.email';
  static const _kLastAt = 'backup.lastAt';

  DriveBackupService get _drive => DriveBackupService.instance;

  @override
  BackupState build() {
    _load();
    return const BackupState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_kLastAt);
    state = BackupState(
      loaded: true,
      email: prefs.getString(_kEmail),
      lastBackupAt:
          last == null ? null : DateTime.fromMillisecondsSinceEpoch(last),
    );
  }

  Future<T> _busy<T>(Future<T> Function() task) async {
    state = state.copyWith(busy: true);
    try {
      return await task();
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  /// Entra com o Google, pede a permissão do Drive e já faz o primeiro
  /// backup. Lança [DriveAuthException] se não der certo.
  Future<void> connect() => _busy(() async {
        final email = await _drive.connect();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kEmail, email);
        state = state.copyWith(email: email);
        await _upload(interactive: true);
      });

  Future<void> disconnect() => _busy(() async {
        await _drive.disconnect();
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_kEmail);
        state = state.copyWith(clearEmail: true);
      });

  /// "Fazer backup agora".
  Future<void> backupNow() => _busy(() async {
        await _ensureAccount();
        await _upload(interactive: true);
      });

  /// Um backup por dia, chamado ao abrir o app. Silencioso: se não for
  /// possível (sem internet, login expirado), tenta de novo na próxima vez.
  Future<void> backupIfDue() async {
    if (!state.loaded) await _load();
    if (!state.connected || state.busy) return;
    final last = state.lastBackupAt;
    final now = DateTime.now();
    final doneToday = last != null &&
        last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
    if (doneToday) return;

    try {
      await _busy(() async {
        if (_drive.account == null && !await _drive.reconnectSilently()) {
          return;
        }
        await _upload(interactive: false);
      });
    } catch (_) {
      // Fica para a próxima abertura do app.
    }
  }

  Future<List<DriveBackup>> listBackups() => _busy(() async {
        await _ensureAccount();
        return _drive.list(interactive: true);
      });

  /// Substitui os dados do aparelho pelo backup [backup]. Antes, envia um
  /// backup do estado atual, para que a restauração possa ser desfeita.
  Future<void> restore(DriveBackup backup) => _busy(() async {
        await _ensureAccount();
        // Baixa primeiro: o backup de segurança abaixo pode apagar o mais
        // antigo (limite de 30), e ele pode ser justamente o escolhido.
        final data = await _drive.download(backup.id);
        await _upload(interactive: true);
        await ref.read(databaseProvider).importData(data);
      });

  Future<void> _ensureAccount() async {
    if (_drive.account != null) return;
    if (await _drive.reconnectSilently()) return;
    final email = await _drive.connect();
    state = state.copyWith(email: email);
  }

  Future<void> _upload({required bool interactive}) async {
    final data = await ref.read(databaseProvider).exportData();
    await _drive.upload(data, interactive: interactive);
    await _drive.prune(keep: keepBackups);
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastAt, now.millisecondsSinceEpoch);
    state = state.copyWith(lastBackupAt: now);
  }
}
