import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/language/native_language.dart';
import '../../../core/language/native_language_provider.dart';
import '../../../core/language/study_language.dart';
import '../../../core/language/study_language_provider.dart';
import '../../../core/language/ui_language_provider.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../l10n/app_strings.dart';
import '../../backup/data/file_backup.dart';
import '../../backup/presentation/backup_screen.dart';
import '../../backup/providers/backup_provider.dart';
import '../../home/presentation/home_screen.dart';
import '../../home_widget/data/daily_word_widget.dart';
import '../../home_widget/presentation/widget_invite_card.dart';
import '../../home_widget/presentation/pinned_word_sheet.dart';
import '../../home_widget/providers/pinned_word_provider.dart';
import '../../home_widget/providers/widget_invite_provider.dart';
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
        SnackBar(content: Text(tr.notificationsDenied)),
      );
    }
  }

  Future<void> _pickTime(BuildContext context, WidgetRef ref) async {
    final s = ref.read(reminderProvider);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: s.hour, minute: s.minute),
      helpText: tr.reminderTimeHelp,
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
              ? tr.testNotificationSent
              : tr.testNotificationFailed,
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
          SnackBar(content: Text(tr.backupExported)),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(tr.exportFailed(e))),
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
        SnackBar(content: Text(tr.openFileFailed(e))),
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
        SnackBar(content: Text(tr.backupImported)),
      );
    } on FormatException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(tr.importFailed(e))),
      );
    }
  }

  Future<void> _chooseStudyLanguage(BuildContext context, WidgetRef ref) async {
    final current = ref.read(studyLanguageProvider);
    final nativeLang = ref.read(nativeLanguageProvider);
    final code = await showAppSheet<String>(
      context,
      (_) => _LanguageSheet(
        title: tr.studyLanguageSheetTitle,
        description: tr.studyLanguageSheetText,
        selected: current,
        options: [
          for (final l in StudyLanguages.all)
            _LanguageOption(
              l.code,
              _capitalize(tr.languageName(l.code)),
              l.nameNative,
              note: l.code == nativeLang ? tr.isYourNativeLanguage : null,
            ),
        ],
      ),
    );
    if (code == null || code == current || !context.mounted) return;

    final navigator = Navigator.of(context);
    await ref
        .read(studyLanguageProvider.notifier)
        .select(ref.read(databaseProvider), code);
    // O deck aberto era do outro idioma.
    ref.read(deckScopeProvider.notifier).state = null;
    // Palavra do dia (notificação e widget) passa a vir do novo idioma.
    ref.read(reminderProvider.notifier).refresh();
    refreshDailyWordWidget(ref);
    // Volta para o início, que já mostra as fichas do novo idioma.
    navigator.popUntil((route) => route.isFirst);
  }

  Future<void> _chooseNativeLanguage(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final current = ref.read(nativeLanguageProvider);
    final study = ref.read(studyLanguageProvider);
    final code = await showAppSheet<String>(
      context,
      (_) => _LanguageSheet(
        title: tr.nativeLanguageSheetTitle,
        description: tr.nativeLanguageSheetText,
        selected: current,
        options: [
          for (final l in NativeLanguages.all)
            _LanguageOption(
              l.code,
              _capitalize(tr.languageName(l.code)),
              l.nameNative,
              note: l.code == study ? tr.isTheLanguageYouStudy : null,
            ),
        ],
      ),
    );
    if (code == null || code == current) return;
    await ref.read(nativeLanguageProvider.notifier).select(code);
  }

  Future<void> _chooseAppLanguage(BuildContext context, WidgetRef ref) async {
    final current = ref.read(uiLanguageProvider);
    final choice = await showAppSheet<String>(
      context,
      (_) => _LanguageSheet(
        title: tr.appLanguageSheetTitle,
        description: tr.appLanguageSheetText,
        selected: current,
        options: [
          _LanguageOption(
            UiLanguageController.system,
            tr.systemLanguage,
            tr.systemLanguageSubtitle,
          ),
          // Cada idioma com o próprio nome, para quem não lê o atual.
          const _LanguageOption('pt', 'Português', 'Portuguese'),
          const _LanguageOption('en', 'English', 'English'),
          const _LanguageOption('es', 'Español', 'Spanish'),
        ],
      ),
    );
    if (choice == null || choice == current || !context.mounted) return;

    final navigator = Navigator.of(context);
    await ref.read(uiLanguageProvider.notifier).select(choice);
    // Lembrete e widget com os textos no novo idioma.
    ref.read(reminderProvider.notifier).refresh();
    refreshDailyWordWidget(ref);
    // Recria as telas abertas para todas mostrarem o novo idioma.
    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  Future<void> _choosePinnedWord(BuildContext context, WidgetRef ref) async {
    final current = ref.read(pinnedWordProvider)?.id;
    // Registro com um campo: distingue "Nenhuma" (null) de fechar a folha.
    final choice = await showAppSheet<(int?,)>(
      context,
      (_) => PinnedWordSheet(selected: current),
    );
    if (choice == null || choice.$1 == current) return;
    await setPinnedWord(ref, choice.$1);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppPalette.of(context);
    final uiChoice = ref.watch(uiLanguageProvider);
    final pinned = ref.watch(pinnedWordProvider);
    final nativeLang =
        NativeLanguages.byCode(ref.watch(nativeLanguageProvider));
    final studyCode = ref.watch(studyLanguageProvider);
    final study = StudyLanguages.all.firstWhere((l) => l.code == studyCode);
    final reminder = ref.watch(reminderProvider);
    final backup = ref.watch(backupProvider);
    final classCount = ref.watch(wordClassMapProvider).length;
    final textSize = ref.watch(textSizeProvider);

    return Scaffold(
      backgroundColor: p.page,
      appBar: ScreenHeader(eyebrow: 'MEIN NOTIZBUCH', title: tr.settings),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: [
              Text(tr.sectionDisplay, style: AppText.section(p)),
              const SizedBox(height: 12),
              _Group(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(tr.textSize, style: AppText.item(p)),
                        const SizedBox(height: 2),
                        Text(
                          tr.textSizeHint,
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
              Text(tr.sectionLanguages, style: AppText.section(p)),
              const SizedBox(height: 12),
              _Group(
                children: [
                  _SettingRow(
                    icon: Icons.translate,
                    title: tr.studyLanguage,
                    subtitle: '${_capitalize(tr.languageName(study.code))} '
                        '(${study.nameNative})',
                    onTap: () => _chooseStudyLanguage(context, ref),
                  ),
                  _SettingRow(
                    icon: Icons.record_voice_over_outlined,
                    title: tr.nativeLanguage,
                    subtitle: '${_capitalize(tr.languageName(nativeLang.code))} '
                        '(${nativeLang.nameNative})',
                    onTap: () => _chooseNativeLanguage(context, ref),
                  ),
                  _SettingRow(
                    icon: Icons.language,
                    title: tr.appLanguage,
                    subtitle: uiChoice == UiLanguageController.system
                        ? '${tr.systemLanguage} · '
                            '${AppStrings.all[UiLanguageController.deviceLanguage()]!.selfName}'
                        : AppStrings.all[uiChoice]!.selfName,
                    onTap: () => _chooseAppLanguage(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(tr.sectionVocabulary, style: AppText.section(p)),
              const SizedBox(height: 12),
              _Group(
                children: [
                  _SettingRow(
                    icon: Icons.palette_outlined,
                    title: tr.grammarClasses,
                    subtitle: tr.customClassesCount(classCount),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const WordClassesScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(tr.sectionDailyReminder, style: AppText.section(p)),
              const SizedBox(height: 12),
              _Group(
                children: [
                  _SettingRow(
                    icon: Icons.notifications_none_rounded,
                    title: tr.wordOfTheDay,
                    subtitle: tr.wordOfTheDayHint,
                    trailing: Switch(
                      value: reminder.enabled,
                      activeTrackColor: p.ink,
                      onChanged: reminder.loaded
                          ? (v) => _toggleReminder(context, ref, v)
                          : null,
                    ),
                  ),
                  if (DailyWordWidget.isSupported)
                    _SettingRow(
                      icon: Icons.widgets_outlined,
                      title: tr.homeWidget,
                      subtitle: tr.homeWidgetHint,
                      onTap: () => addDailyWordWidget(context),
                    ),
                  if (DailyWordWidget.isSupported)
                    _SettingRow(
                      icon: Icons.push_pin_outlined,
                      title: tr.pinnedWord,
                      subtitle: pinned == null
                          ? tr.pinnedNone
                          : '${pinned.germanWord} · '
                              '${pinned.portugueseTranslation}',
                      onTap: () => _choosePinnedWord(context, ref),
                    ),
                  if (reminder.enabled) ...[
                    _SettingRow(
                      icon: Icons.schedule_rounded,
                      title: tr.time,
                      trailing: _Value(reminder.timeLabel, mono: true),
                      onTap: () => _pickTime(context, ref),
                    ),
                    _SettingRow(
                      icon: Icons.send_outlined,
                      title: tr.sendTestNow,
                      onTap: () => _sendTest(context, ref),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              Text(tr.sectionBackup, style: AppText.section(p)),
              const SizedBox(height: 12),
              _Group(
                children: [
                  _SettingRow(
                    icon: backup.connected
                        ? Icons.cloud_done_outlined
                        : Icons.cloud_outlined,
                    title: 'Google Drive',
                    subtitle: backup.email ?? tr.off,
                    trailing: const _Value(''),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const BackupScreen(),
                      ),
                    ),
                  ),
                  _SettingRow(
                    icon: Icons.ios_share_rounded,
                    title: tr.exportToFile,
                    subtitle: tr.exportToFileHint,
                    onTap: () => _export(context, ref),
                  ),
                  _SettingRow(
                    icon: Icons.file_open_outlined,
                    title: tr.importFromFile,
                    subtitle: tr.importFromFileHint,
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

/// "alemão" → "Alemão" (o perfil guarda o nome em minúscula, para frases).
String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Uma opção da lista de idiomas.
class _LanguageOption {
  const _LanguageOption(this.code, this.title, this.subtitle, {this.note});

  final String code;
  final String title;
  final String subtitle;

  /// Motivo de a opção estar indisponível ("É o seu idioma nativo").
  final String? note;
}

/// Lista de idiomas para escolher. Devolve o código escolhido.
class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({
    required this.title,
    required this.description,
    required this.options,
    required this.selected,
  });

  final String title;
  final String description;
  final List<_LanguageOption> options;
  final String selected;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppText.section(p)),
        const SizedBox(height: 8),
        Text(description, style: AppText.meta(p)),
        const SizedBox(height: 12),
        _Group(
          children: [
            for (final o in options)
              Opacity(
                opacity: o.note == null ? 1 : 0.45,
                child: _SettingRow(
                  icon: Icons.language,
                  title: o.title,
                  subtitle: o.note ?? o.subtitle,
                  trailing: o.code == selected
                      ? Icon(Icons.check, color: p.text900)
                      : null,
                  onTap: o.note == null
                      ? () => Navigator.of(context).pop(o.code)
                      : null,
                  showChevron: false,
                ),
              ),
          ],
        ),
      ],
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
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Seta "›" das linhas tocáveis. Desligada nas listas de escolha.
  final bool showChevron;

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
          if (onTap != null && showChevron) ...[
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
        Text(tr.importBackupSheetTitle, style: AppText.section(p)),
        const SizedBox(height: 12),
        Text(
          date == null ? tr.notizbuchBackup : tr.fromDate(date),
          style: AppText.display(p, fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          tr.backupCounts(words, decks, sentences),
          style: AppText.meta(p),
        ),
        const SizedBox(height: 12),
        Text(
          tr.importWarning,
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
                label: tr.importAction,
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
              label: tr.textSizeSemantics(level.label),
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
          Text(tr.preview, style: AppText.caption(p)),
          const SizedBox(height: 6),
          Text(
            StudyLanguages.active.exampleHint,
            style: AppTheme.serif(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: p.text900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            NativeLanguages.active.exampleTranslationHint,
            style: AppText.body(p),
          ),
        ],
      ),
    );
  }
}
