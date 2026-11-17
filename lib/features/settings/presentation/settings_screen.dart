import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/screen_header.dart';
import '../../backup/presentation/backup_screen.dart';
import '../../backup/providers/backup_provider.dart';
import '../../reminders/providers/reminder_provider.dart';

/// Ajustes: lembrete diário e backup no Google Drive.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _toggleReminder(
    BuildContext context,
    WidgetRef ref,
    bool value,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(reminderProvider.notifier).setEnabled(value);
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Sem permissão para notificações. Libere em Configurações › '
            'Apps › Mein Notizbuch › Notificações.',
          ),
        ),
      );
    }
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final s = ref.read(reminderProvider);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: s.hour, minute: s.minute),
      helpText: 'Horário do lembrete',
    );
    if (picked == null) return;
    await ref
        .read(reminderProvider.notifier)
        .setTime(picked.hour, picked.minute);
  }

  Future<void> _sendTest(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref.read(reminderProvider.notifier).sendTest();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Notificação de teste enviada.'
              : 'Não foi possível enviar: cadastre uma palavra e libere as '
                  'notificações.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppPalette.of(context);
    final reminder = ref.watch(reminderProvider);
    final backup = ref.watch(backupProvider);

    return Scaffold(
      backgroundColor: p.page,
      appBar: const ScreenHeader(eyebrow: 'MEIN NOTIZBUCH', title: 'Ajustes'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: [
              Text('LEMBRETE DIÁRIO', style: AppText.section(p)),
              const SizedBox(height: 12),
              _Group(
                children: [
                  _SettingRow(
                    icon: Icons.notifications_none_rounded,
                    title: 'Palavra do dia',
                    subtitle: 'Uma notificação por dia com uma palavra, a '
                        'classe gramatical e o significado.',
                    trailing: Switch(
                      value: reminder.enabled,
                      activeTrackColor: p.ink,
                      onChanged: reminder.loaded
                          ? (v) => _toggleReminder(context, ref, v)
                          : null,
                    ),
                  ),
                  if (reminder.enabled) ...[
                    _SettingRow(
                      icon: Icons.schedule_rounded,
                      title: 'Horário',
                      trailing: _Value(reminder.timeLabel, mono: true),
                      onTap: () => _pickTime(context, ref),
                    ),
                    _SettingRow(
                      icon: Icons.send_outlined,
                      title: 'Enviar um teste agora',
                      onTap: () => _sendTest(context, ref),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              Text('BACKUP', style: AppText.section(p)),
              const SizedBox(height: 12),
              _Group(
                children: [
                  _SettingRow(
                    icon: backup.connected
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_outlined,
                    title: 'Google Drive',
                    subtitle: backup.email ?? 'Desligado',
                    trailing: const _Value(''),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const BackupScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cartão com linhas separadas por divisórias.
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.cardBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 64, color: p.divider),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: p.softButton,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: p.text700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.item(p)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppText.meta(p)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          if (onTap != null) ...[
            const SizedBox(width: 8),
            ChevronIcon.right(color: p.text400, size: 12),
          ],
        ],
      ),
    );
    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: row),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value(this.text, {this.mono = false});

  final String text;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    if (text.isEmpty) return const SizedBox.shrink();
    return Text(
      text,
      style: mono
          ? AppTheme.mono(fontSize: 13, color: p.text700)
          : AppText.meta(p),
    );
  }
}
