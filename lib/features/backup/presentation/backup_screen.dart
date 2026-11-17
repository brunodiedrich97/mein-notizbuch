import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/google_config.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/screen_header.dart';
import '../data/drive_backup_service.dart';
import '../providers/backup_provider.dart';

String _two(int n) => n.toString().padLeft(2, '0');

/// "hoje às 15:30", "ontem às 09:05" ou "12/11/2026 às 15:30".
String formatBackupDate(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final time = '${_two(d.hour)}:${_two(d.minute)}';
  if (day == today) return 'hoje às $time';
  if (day == today.subtract(const Duration(days: 1))) return 'ontem às $time';
  return '${_two(d.day)}/${_two(d.month)}/${d.year} às $time';
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
        SnackBar(content: Text('Não foi possível concluir: $e')),
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
          const SnackBar(content: Text('Nenhum backup no Drive ainda.')),
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
      success: 'Backup de ${formatBackupDate(chosen.createdAt)} restaurado.',
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
      appBar: const ScreenHeader(
        eyebrow: 'MEIN NOTIZBUCH',
        title: 'Backup no Google Drive',
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
                                state.connected ? 'CONECTADO' : 'DESLIGADO',
                                style: AppText.caption(p),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                state.email ?? 'Nenhuma conta conectada',
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
                            ? 'Nenhum backup feito ainda.'
                            : 'Último backup: ${formatBackupDate(last)}.',
                        style: AppText.meta(p),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Uma vez por dia, ao abrir o app, o Notizbuch envia um '
                      'backup das palavras, decks e frases para a pasta '
                      '"${DriveBackupService.folderName}" do seu Google '
                      'Drive. Ficam guardados os '
                      '${BackupController.keepBackups} mais recentes.',
                      style: AppText.body(p),
                    ),
                    if (!isDriveBackupSupported || !isGoogleConfigured) ...[
                      const SizedBox(height: 12),
                      Text(
                        isDriveBackupSupported
                            ? 'O login Google ainda não foi configurado neste '
                                'build (google_config.dart).'
                            : 'O backup no Google Drive ainda não está '
                                'disponível no iPhone.',
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
                  label: 'Conectar Google Drive',
                  onPressed: busy || !isGoogleConfigured || !isDriveBackupSupported
                      ? null
                      : () => _run(
                            context,
                            controller.connect,
                            success: 'Conectado. Primeiro backup enviado.',
                          ),
                )
              else ...[
                PrimaryButton(
                  label: 'Fazer backup agora',
                  onPressed: busy
                      ? null
                      : () => _run(
                            context,
                            controller.backupNow,
                            success: 'Backup enviado para o Drive.',
                          ),
                ),
                const SizedBox(height: 12),
                SoftButton(
                  label: 'Restaurar um backup',
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
                              success: 'Conta desconectada. Os backups '
                                  'continuam no seu Drive.',
                            ),
                    style: TextButton.styleFrom(foregroundColor: p.text500),
                    child: Text(
                      'Desconectar conta',
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
        Text('BACKUPS NO DRIVE', style: AppText.section(p)),
        const SizedBox(height: 8),
        for (var i = 0; i < backups.length; i++)
          InkWell(
            onTap: () => Navigator.of(context).pop(backups[i]),
            child: Container(
              height: 52,
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
        Text('RESTAURAR BACKUP', style: AppText.section(p)),
        const SizedBox(height: 12),
        Text(
          'De ${formatBackupDate(backup.createdAt)}',
          style: AppText.display(p, fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          'As palavras, decks e frases deste aparelho serão substituídos '
          'pelos do backup. Antes disso, o app envia um backup do estado '
          'atual, para você poder voltar atrás.',
          style: AppText.body(p),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: SoftButton(
                label: 'Cancelar',
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: 'Restaurar',
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
