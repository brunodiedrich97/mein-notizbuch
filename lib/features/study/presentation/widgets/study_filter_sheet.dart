import 'package:flutter/material.dart';

import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/grammar_colors.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../vocabulary/models/grammar_type.dart';
import '../../../vocabulary/providers/vocabulary_provider.dart';
import '../../models/study_settings.dart';
import '../../../word_classes/presentation/word_appearance.dart';

/// Cor de cada filtro: a da classe correspondente. "Todos" não tem cor.
Color? filterColor(WordFilter f, {required bool isDark}) {
  final category = switch (f) {
    WordFilter.all => null,
    WordFilter.der => GrammarCategory.masculineNoun,
    WordFilter.die => GrammarCategory.feminineNoun,
    WordFilter.das => GrammarCategory.neuterNoun,
    WordFilter.verbs => GrammarCategory.verb,
    WordFilter.adjectives => GrammarCategory.adjective,
    WordFilter.prepositions => GrammarCategory.preposition,
    WordFilter.others => GrammarCategory.other,
  };
  return category == null ? null : GrammarColors.of(category, isDark: isDark);
}

/// Abre a folha de filtros. Retorna as novas configurações, ou `null` se o
/// usuário fechar sem aplicar.
///
/// Com [sessionOptions] falso, mostra só a classe gramatical (índice).
Future<StudySettings?> showStudyFilterSheet(
  BuildContext context,
  StudySettings initial, {
  bool sessionOptions = true,
}) {
  return showAppSheet<StudySettings>(
    context,
    (_) => _StudyFilterSheet(initial: initial, sessionOptions: sessionOptions),
  );
}

class _StudyFilterSheet extends StatefulWidget {
  const _StudyFilterSheet({
    required this.initial,
    required this.sessionOptions,
  });

  final StudySettings initial;
  final bool sessionOptions;

  @override
  State<_StudyFilterSheet> createState() => _StudyFilterSheetState();
}

class _StudyFilterSheetState extends State<_StudyFilterSheet> {
  late StudySettings _s = widget.initial;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('CLASSE GRAMATICAL', style: AppText.section(p)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in WordFilter.values)
              _FilterChip(
                label: f.label,
                color: filterColor(f, isDark: isDark),
                selected: _s.customClassId == null && f == _s.filter,
                onTap: () => setState(() => _s = _s.copyWith(filter: f)),
              ),
            // Classes criadas pelo usuário.
            for (final c in WordClassScope.of(context).values)
              _FilterChip(
                label: c.name,
                color: customClassColor(Color(c.color), isDark: isDark),
                selected: _s.customClassId == c.id,
                onTap: () =>
                    setState(() => _s = _s.copyWith(customClassId: c.id)),
              ),
          ],
        ),
        if (widget.sessionOptions) ...[
          const SizedBox(height: 24),
          Text('ORDEM DA SESSÃO', style: AppText.section(p)),
          const SizedBox(height: 4),
          for (final o in SessionOrder.values)
            _RadioRow(
              label: o.label,
              selected: o == _s.order,
              showDivider: o != SessionOrder.values.last,
              onTap: () => setState(() => _s = _s.copyWith(order: o)),
            ),
          const SizedBox(height: 20),
          Text('TAMANHO DA SESSÃO', style: AppText.section(p)),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final size in StudySettings.sizeOptions) ...[
                if (size != StudySettings.sizeOptions.first)
                  const SizedBox(width: 8),
                _SizePill(
                  label: size == null ? 'Todas' : '$size',
                  selected: size == _s.size,
                  onTap: () => setState(
                    () => _s = size == null
                        ? _s.copyWith(allCards: true)
                        : _s.copyWith(size: size),
                  ),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Aplicar',
          onPressed: () => Navigator.of(context).pop(_s),
        ),
      ],
    );
  }
}

/// Chip de classe: sempre na cor da classe; preenchido quando selecionado.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;

  /// Cor da classe. `null` = neutro ("Todos").
  final Color? color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final neutral = this.color == null;
    final color = this.color ?? p.ink;
    final radius = BorderRadius.circular(12);

    final Color background;
    final Color border;
    final Color text;
    if (selected) {
      background = color;
      border = color;
      text = neutral ? p.onInk : GrammarColors.onCategory(isDark: isDark);
    } else if (neutral) {
      background = p.card;
      border = p.outline;
      text = p.text700;
    } else {
      background = color.withValues(alpha: isDark ? 0.14 : 0.08);
      border = color.withValues(alpha: 0.45);
      text = color;
    }

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: border),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              label,
              style: AppText.button.copyWith(color: text),
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.label,
    required this.selected,
    required this.showDivider,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            border: showDivider
                ? Border(bottom: BorderSide(color: p.divider))
                : null,
          ),
          child: Row(
            children: [
              Expanded(child: Text(label, style: AppText.item(p))),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? p.ink : p.dots,
                    width: selected ? 6 : 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SizePill extends StatelessWidget {
  const _SizePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final radius = BorderRadius.circular(10);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? p.ink : p.card,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: selected ? p.ink : p.outline),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 52),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppText.button.copyWith(
                fontSize: 13,
                color: selected ? p.onInk : p.text700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
