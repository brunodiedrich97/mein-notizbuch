import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/screen_header.dart';
import '../../backup/data/file_backup.dart';
import '../../backup/presentation/backup_screen.dart';
import '../../backup/providers/backup_provider.dart';
import '../../reminders/providers/reminder_provider.dart';
import '../../vocabulary/providers/vocabulary_provider.dart';
import '../../word_classes/presentation/word_classes_screen.dart';
import '../../word_classes/providers/word_class_provider.dart';
import '../providers/text_size_provider.dart';

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

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final saved = await FileBackup.export(ref.read(databaseProvider));
      if (saved) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Backup exportado.')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Não foi possível exportar: $e')),
      );
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    Map<String, dynamic>? data;
    try {
      data = await FileBackup.pick();
    } on FormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      return;
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Não foi possível abrir o arquivo: $e')),
      );
      return;
    }
    if (data == null || !context.mounted) return;

    final backup = data;
    final confirmed = await showAppSheet<bool>(
      context,
      (_) => _ConfirmImportSheet(data: backup),
    );
    if (confirmed != true) return;

    try {
      await ref.read(databaseProvider).importData(backup);
      messenger.showSnackBar(
        const SnackBar(content: Text('Backup importado.')),
      );
    } on FormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Não foi possível importar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppPalette.of(context);
    final reminder = ref.watch(reminderProvider);
    final backup = ref.watch(backupProvider);
    final classCount = ref.watch(wordClassMapProvider).length;
    final textSize = ref.watch(textSizeProvider);

    return Scaffold(
      backgroundColor: p.page,
      appBar: const ScreenHeader(eyebrow: 'MEIN NOTIZBUCH', title: 'Ajustes'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: [
              Text('TELA', style: AppText.section(p)),
              const SizedBox(height: 12),
              _Group(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Tamanho do texto', style: AppText.item(p)),
                        const SizedBox(height: 2),
                        Text(
                          'Soma com o ajuste de acessibilidade do celular.',
                          style: AppText.meta(p),
                        ),
                        const SizedBox(height: 12),
                        _TextSizeSelector(
                          selected: textSize,
                          onChanged: (level) =>
                              ref.read(textSizeProvider.notifier).set(level),
                        ),
                        const SizedBox(height: 16),
                        const _TextSizePreview(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('VOCABULÁRIO', style: AppText.section(p)),
              const SizedBox(height: 12),
              _Group(
                children: [
                  _SettingRow(
                    icon: Icons.palette_outlined,
                    title: 'Classes gramaticais',
                    subtitle: switch (classCount) {
                      0 => 'Crie classes novas, com nome e cor',
                      1 => '1 classe criada',
                      _ => '$classCount classes criadas',
                    },
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const WordClassesScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
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
                  _SettingRow(
                    icon: Icons.ios_share_rounded,
                    title: 'Exportar para um arquivo',
                    subtitle: 'Salve no app Arquivos, no iCloud Drive ou '
                        'em outra pasta.',
                    onTap: () => _export(context, ref),
                  ),
                  _SettingRow(
                    icon: Icons.file_open_outlined,
                    title: 'Importar de um arquivo',
                    subtitle: 'Substitui os dados deste aparelho.',
                    onTap: () => _import(context, ref),
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

/// Confirmação antes de importar: mostra a data e o conteúdo do arquivo.
class _ConfirmImportSheet extends StatelessWidget {
  const _ConfirmImportSheet({required this.data});

  final Map<String, dynamic> data;

  int _count(String key) => (data[key] as List?)?.length ?? 0;

  String? _date() {
    final raw = data['exportedAt'];
    final d = raw is String ? DateTime.tryParse(raw)?.toLocal() : null;
    if (d == null) return null;
    return formatBackupDate(d);
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final date = _date();
    final words = _count('words');
    final decks = _count('decks');
    final sentences = _count('sentences');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('IMPORTAR BACKUP', style: AppText.section(p)),
        const SizedBox(height: 12),
        Text(
          date == null ? 'Backup do Notizbuch' : 'De $date',
          style: AppText.display(p, fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          '$words palavras · $decks decks · $sentences frases',
          style: AppText.meta(p),
        ),
        const SizedBox(height: 12),
        Text(
          'As palavras, decks e frases deste aparelho serão substituídos '
          'pelos do arquivo. Se quiser guardar os dados atuais, exporte '
          'antes.',
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
                label: 'Importar',
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Três opções lado a lado: "A" em tamanhos crescentes e o nome.
class _TextSizeSelector extends StatelessWidget {
  const _TextSizeSelector({required this.selected, required this.onChanged});

  final TextSizeLevel selected;
  final ValueChanged<TextSizeLevel> onChanged;

  static const _sampleSize = {
    TextSizeLevel.normal: 15.0,
    TextSizeLevel.large: 19.0,
    TextSizeLevel.extraLarge: 23.0,
  };

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Row(
      children: [
        for (final level in TextSizeLevel.values) ...[
          if (level != TextSizeLevel.values.first) const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              button: true,
              selected: level == selected,
              label: 'Tamanho do texto: ${level.label}',
              child: Material(
                color: level == selected ? p.ink : p.card,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: level == selected ? p.ink : p.outline,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onChanged(level),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      children: [
                        // O "A" mostra a diferença real, sem a escala do app.
                        Text(
                          'A',
                          textScaler: TextScaler.noScaling,
                          style: AppTheme.serif(
                            fontSize: _sampleSize[level]!,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: level == selected ? p.onInk : p.text900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          level.label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.meta(p).copyWith(
                            fontWeight: FontWeight.w600,
                            color: level == selected ? p.onInk : p.text700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Uma ficha em miniatura com o tamanho atual, para conferir.
class _TextSizePreview extends StatelessWidget {
  const _TextSizePreview();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.pronBox,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PRÉVIA', style: AppText.caption(p)),
          const SizedBox(height: 6),
          Text(
            'Der Hund schläft im Garten.',
            style: AppTheme.serif(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: p.text900,
            ),
          ),
          const SizedBox(height: 2),
          Text('O cachorro dorme no jardim.', style: AppText.body(p)),
        ],
      ),
    );
  }
}
