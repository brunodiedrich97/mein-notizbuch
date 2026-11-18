import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/google_config.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../l10n/app_strings.dart';
import '../data/drive_backup_service.dart';
import '../providers/backup_provider.dart';

String _two(int n) => n.toString().padLeft(2, '0');

/// "hoje às 15:30", "ontem às 09:05" ou "12/11/2026 às 15:30".
String formatBackupDate(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final time = '${_two(d.hour)}:${_two(d.minute)}';
  if (day == today) return tr.todayAt(time);
  if (day == today.subtract(const Duration(days: 1))) {
    return tr.yesterdayAt(time);
  }
  return tr.dateAt(_two(d.day), _two(d.month), d.year, time);
}

/// Backup no Google Drive: conectar a conta, fazer backup agora, restaurar
/// e desconectar.
class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  Future<void> _run(
    BuildContext context,
    Future<void> Function() task, {
    String? success,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await task();
      if (success != null) {
        messenger.showSnackBar(SnackBar(content: Text(success)));
      }
    } on DriveAuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on FormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(tr.actionFailed(e))),
      );
    }
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(backupProvider.notifier);
    var backups = const <DriveBackup>[];
    await _run(context, () async {
      backups = await controller.listBackups();
    });
    if (!context.mounted || backups.isEmpty) {
      if (context.mounted && backups.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr.noDriveBackupsYet)),
        );
      }
      return;
    }

    final chosen = await showAppSheet<DriveBackup>(
      context,
      (ctx) => _BackupListSheet(backups: backups),
    );
    if (chosen == null || !context.mounted) return;

    final confirmed = await showAppSheet<bool>(
      context,
      (ctx) => _ConfirmRestoreSheet(backup: chosen),
    );
    if (confirmed != true || !context.mounted) return;

    await _run(
      context,
      () => controller.restore(chosen),
      success: tr.backupRestored(formatBackupDate(chosen.createdAt)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppPalette.of(context);
    final state = ref.watch(backupProvider);
    final controller = ref.read(backupProvider.notifier);
    final busy = state.busy;
    final last = state.lastBackupAt;

    return Scaffold(
      backgroundColor: p.page,
      appBar: ScreenHeader(
        eyebrow: 'MEIN NOTIZBUCH',
        title: tr.driveBackupTitle,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: p.softButton,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            state.connected
                                ? Icons.cloud_done_outlined
                                : Icons.cloud_off_outlined,
                            size: 20,
                            color: p.text700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                state.connected ? tr.connected : tr.disconnected,
                                style: AppText.caption(p),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                state.email ?? tr.noAccountConnected,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.item(p),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (state.connected) ...[
                      const SizedBox(height: 12),
                      Text(
                        last == null
                            ? tr.noBackupYet
                            : tr.lastBackup(formatBackupDate(last)),
                        style: AppText.meta(p),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      tr.driveBackupExplanation(
                        DriveBackupService.folderName,
                        BackupController.keepBackups,
                      ),
                      style: AppText.body(p),
                    ),
                    if (!isDriveBackupSupported || !isGoogleConfigured) ...[
                      const SizedBox(height: 12),
                      Text(
                        isDriveBackupSupported
                            ? tr.googleNotConfiguredBuild
                            : tr.driveNotOnIos,
                        style: AppText.body(p).copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (busy) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    minHeight: 3,
                    color: p.progress,
                    backgroundColor: p.track,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (!state.connected)
                PrimaryButton(
                  label: tr.connectDrive,
                  onPressed: busy || !isGoogleConfigured || !isDriveBackupSupported
                      ? null
                      : () => _run(
                            context,
                            controller.connect,
                            success: tr.connectedFirstBackup,
                          ),
                )
              else ...[
                PrimaryButton(
                  label: tr.backupNow,
                  onPressed: busy
                      ? null
                      : () => _run(
                            context,
                            controller.backupNow,
                            success: tr.backupUploaded,
                          ),
                ),
                const SizedBox(height: 12),
                SoftButton(
                  label: tr.restoreBackup,
                  onPressed: busy ? null : () => _restore(context, ref),
                ),
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: busy
                        ? null
                        : () => _run(
                              context,
                              controller.disconnect,
                              success: tr.accountDisconnected,
                            ),
                    style: TextButton.styleFrom(foregroundColor: p.text500),
                    child: Text(
                      tr.disconnectAccount,
                      style: AppText.meta(p).copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Lista de backups para restaurar.
class _BackupListSheet extends StatelessWidget {
  const _BackupListSheet({required this.backups});

  final List<DriveBackup> backups;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(tr.driveBackups, style: AppText.section(p)),
        const SizedBox(height: 8),
        for (var i = 0; i < backups.length; i++)
          InkWell(
            onTap: () => Navigator.of(context).pop(backups[i]),
            child: Container(
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(vertical: 8),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: i == backups.length - 1
                    ? null
                    : Border(bottom: BorderSide(color: p.divider)),
              ),
              child: Row(
                children: [
                  Icon(Icons.description_outlined, size: 18, color: p.text500),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      formatBackupDate(backups[i].createdAt),
                      style: AppText.item(p),
                    ),
                  ),
                  if (backups[i].sizeBytes != null)
                    Text(
                      '${(backups[i].sizeBytes! / 1024).ceil()} KB',
                      style: AppTheme.mono(fontSize: 11, color: p.text400),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ConfirmRestoreSheet extends StatelessWidget {
  const _ConfirmRestoreSheet({required this.backup});

  final DriveBackup backup;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(tr.restoreBackupSheetTitle, style: AppText.section(p)),
        const SizedBox(height: 12),
        Text(
          tr.fromDate(formatBackupDate(backup.createdAt)),
          style: AppText.display(p, fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          tr.restoreWarning,
          style: AppText.body(p),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: SoftButton(
                label: tr.cancel,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: tr.restore,
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
