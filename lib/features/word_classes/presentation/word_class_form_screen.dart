import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/language/study_language.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/grammar_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/screen_header.dart';
import '../../vocabulary/providers/vocabulary_provider.dart';
import 'word_appearance.dart';

/// Cria ou edita uma classe gramatical do usuário (nome e cor livre).
/// Ao salvar, fecha a tela devolvendo o id da classe.
class WordClassFormScreen extends ConsumerStatefulWidget {
  const WordClassFormScreen({super.key, this.existing});

  /// Classe a editar. `null` = nova classe.
  final WordClass? existing;

  @override
  ConsumerState<WordClassFormScreen> createState() =>
      _WordClassFormScreenState();
}

class _WordClassFormScreenState extends ConsumerState<WordClassFormScreen> {
  static const Color _defaultColor = Color(0xFF0F766E);

  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _hex = TextEditingController();
  late HSVColor _hsv = HSVColor.fromColor(
    widget.existing == null ? _defaultColor : Color(widget.existing!.color),
  );
  bool _saving = false;

  Color get _color => _hsv.toColor();

  @override
  void initState() {
    super.initState();
    _hex.text = _toHex(_color);
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _hex.dispose();
    super.dispose();
  }

  static String _toHex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  static Color? _parseHex(String text) {
    final t = text.trim().replaceFirst('#', '');
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(t)) return null;
    return Color(0xFF000000 | int.parse(t, radix: 16));
  }

  /// Muda a cor pelo seletor e atualiza o campo hexadecimal.
  void _setHsv(HSVColor hsv) {
    setState(() {
      _hsv = hsv;
      _hex.text = _toHex(hsv.toColor());
    });
  }

  void _onHexChanged(String text) {
    final c = _parseHex(text);
    if (c != null) setState(() => _hsv = HSVColor.fromColor(c));
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    final db = ref.read(databaseProvider);
    final color = _color.toARGB32();
    final existing = widget.existing;
    final int id;
    if (existing == null) {
      id = await db.addWordClass(name, color);
    } else {
      await db.updateWordClass(existing.id, name, color);
      id = existing.id;
    }
    if (mounted) Navigator.of(context).pop(id);
  }

  Future<void> _delete(WordClass wc) async {
    final words = await ref.read(wordListProvider.future);
    final count = words.where((w) => w.customClassId == wc.id).length;
    if (!mounted) return;
    final confirmed = await showAppSheet<bool>(context, (ctx) {
      final p = AppPalette.of(ctx);
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('EXCLUIR CLASSE', style: AppText.section(p)),
          const SizedBox(height: 12),
          Text(wc.name, style: AppText.display(p, fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            switch (count) {
              0 => 'Nenhuma palavra usa esta classe.',
              1 => 'A palavra desta classe passa a ser "Outros".',
              _ => 'As $count palavras desta classe passam a ser "Outros".',
            },
            style: AppText.body(p),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SoftButton(
                  label: 'Cancelar',
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  label: 'Excluir',
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ),
            ],
          ),
        ],
      );
    });
    if (confirmed != true || !mounted) return;
    await ref.read(databaseProvider).deleteWordClass(wc.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final existing = widget.existing;
    final name = _name.text.trim();
    final similar = similarBuiltInClass(_color);

    return Scaffold(
      backgroundColor: p.page,
      appBar: ScreenHeader(
        eyebrow: 'CLASSES GRAMATICAIS',
        title: existing == null ? 'Nova classe' : 'Editar classe',
        trailing: existing == null
            ? null
            : HeaderIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Excluir classe',
                onPressed: () => _delete(existing),
              ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: [
              _NameField(controller: _name),
              const SizedBox(height: 24),
              Text('COR', style: AppText.section(p)),
              const SizedBox(height: 12),
              _SaturationValuePicker(hsv: _hsv, onChanged: _setHsv),
              const SizedBox(height: 16),
              _HueSlider(hsv: _hsv, onChanged: _setHsv),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: p.outline),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: p.pronBox,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: p.outline),
                      ),
                      child: TextField(
                        controller: _hex,
                        onChanged: _onHexChanged,
                        autocorrect: false,
                        enableSuggestions: false,
                        maxLength: 7,
                        style: AppTheme.mono(fontSize: 14, color: p.text900),
                        decoration: const InputDecoration(
                          counterText: '',
                          isDense: true,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _Preview(
                      name: name.isEmpty ? 'Classe' : name,
                      base: _color,
                      dark: false,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Preview(
                      name: name.isEmpty ? 'Classe' : name,
                      base: _color,
                      dark: true,
                    ),
                  ),
                ],
              ),
              if (similar != null) ...[
                const SizedBox(height: 12),
                _Warning(
                  'Parecida com "${similar.shortLabel}". Escolha um tom mais '
                  'distante para não confundir as classes.',
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: p.footer,
          border: Border(top: BorderSide(color: p.divider)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: SoftButton(
                    label: 'Cancelar',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    label: existing == null ? 'Criar classe' : 'Salvar',
                    onPressed: name.isEmpty || _saving ? null : _save,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: p.pronBox,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('NOME', style: AppText.caption(p)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            autofocus: true,
            maxLength: 40,
            textCapitalization: TextCapitalization.sentences,
            style: AppText.item(p).copyWith(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Conjunção, Pronome, Expressão…',
              hintStyle: AppText.item(p).copyWith(
                fontSize: 16,
                color: p.text400,
                fontWeight: FontWeight.w400,
              ),
              counterText: '',
              isDense: true,
              filled: false,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quadro de saturação (horizontal) e brilho (vertical) do matiz atual.
class _SaturationValuePicker extends StatelessWidget {
  const _SaturationValuePicker({required this.hsv, required this.onChanged});

  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  static const double height = 160;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        void update(Offset local) {
          final s = (local.dx / width).clamp(0.0, 1.0);
          final v = 1 - (local.dy / height).clamp(0.0, 1.0);
          onChanged(hsv.withSaturation(s).withValue(v));
        }

        return GestureDetector(
          onPanDown: (d) => update(d.localPosition),
          onPanUpdate: (d) => update(d.localPosition),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: height,
              child: Stack(
                children: [
                  // Matiz puro por baixo; branco por cima, da esquerda
                  // (sem saturação) para a direita.
                  Positioned.fill(
                    child: ColoredBox(
                      color: HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: hsv.saturation * width - 10,
                    top: (1 - hsv.value) * height - 10,
                    child: _Knob(color: hsv.toColor()),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Barra de matiz (0–360°).
class _HueSlider extends StatelessWidget {
  const _HueSlider({required this.hsv, required this.onChanged});

  final HSVColor hsv;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        void update(Offset local) {
          final hue = (local.dx / width).clamp(0.0, 1.0) * 360;
          onChanged(hsv.withHue(hue == 360 ? 359.9 : hue));
        }

        return GestureDetector(
          onPanDown: (d) => update(d.localPosition),
          onPanUpdate: (d) => update(d.localPosition),
          child: SizedBox(
            height: 24,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 14,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    gradient: LinearGradient(
                      colors: [
                        for (var h = 0; h <= 360; h += 60)
                          HSVColor.fromAHSV(1, h % 360, 1, 1).toColor(),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: hsv.hue / 360 * width - 12,
                  child: _Knob(
                    color: HSVColor.fromAHSV(1, hsv.hue, 1, 1).toColor(),
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Knob extends StatelessWidget {
  const _Knob({required this.color, this.size = 20});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 2),
        ],
      ),
    );
  }
}

/// Prévia da palavra e do chip num dos temas.
class _Preview extends StatelessWidget {
  const _Preview({required this.name, required this.base, required this.dark});

  final String name;
  final Color base;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final palette = dark ? AppPalette.dark : AppPalette.light;
    final color = customClassColor(base, isDark: dark);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? GrammarColors.paperCardDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dark ? 'TEMA ESCURO' : 'TEMA CLARO',
            style: AppText.caption(palette),
          ),
          const SizedBox(height: 8),
          Text(
            StudyLanguages.active.terms.sampleWord,
            style: AppTheme.serif(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: dark ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.45)),
            ),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.meta(palette).copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 16, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, height: 1.4, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}
