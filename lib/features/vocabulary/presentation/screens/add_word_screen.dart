import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/grammar_colors.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../decks/presentation/deck_icon_data.dart';
import '../../../decks/presentation/widgets/new_deck_sheet.dart';
import '../../../decks/providers/deck_provider.dart';
import '../../../word_classes/presentation/word_appearance.dart';
import '../../../word_classes/presentation/word_class_form_screen.dart';
import '../../models/grammar_type.dart';
import '../../models/word_parser.dart';
import '../../providers/vocabulary_provider.dart';
import '../widgets/pronunciation_box.dart';

class AddWordScreen extends ConsumerStatefulWidget {
  const AddWordScreen({super.key, this.initialDeckId});

  /// Deck já escolhido ao abrir (ex.: "+ Adicionar" dentro de um deck).
  /// `null` = deck "Geral".
  final int? initialDeckId;

  @override
  ConsumerState<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends ConsumerState<AddWordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _german = TextEditingController();
  final _translation = TextEditingController();
  final _ipa = TextEditingController();
  final _approximation = TextEditingController();
  final _tip = TextEditingController();
  final _plural = TextEditingController();
  final _verbForms = TextEditingController();
  final _degrees = TextEditingController();
  final _prepositionCase = TextEditingController();
  final _tagDetail = TextEditingController();
  final _conjugation = TextEditingController();
  final _exampleDe = TextEditingController();
  final _examplePt = TextEditingController();

  GrammarCategory _category = GrammarCategory.other;
  bool _categoryChosenByUser = false;

  /// Classe criada pelo usuário escolhida (a categoria fica "outros").
  int? _customClassId;
  bool _articleAmbiguous = false;
  bool _saving = false;
  late int _deckId = widget.initialDeckId ?? AppDatabase.generalDeckId;

  List<TextEditingController> get _controllers => [
        _german,
        _translation,
        _ipa,
        _approximation,
        _tip,
        _plural,
        _verbForms,
        _degrees,
        _prepositionCase,
        _tagDetail,
        _conjugation,
        _exampleDe,
        _examplePt,
      ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onGermanChanged(String value) {
    final parsed = WordParser.parse(value);
    setState(() {
      _articleAmbiguous = parsed.articleIsAmbiguous;
      if (!_categoryChosenByUser) _category = parsed.category;
    });
  }

  void _chooseCategory(GrammarCategory category) {
    setState(() {
      _category = category;
      _customClassId = null;
      _categoryChosenByUser = true;
    });
  }

  void _chooseCustomClass(int id) {
    setState(() {
      _category = GrammarCategory.other;
      _customClassId = id;
      _categoryChosenByUser = true;
    });
  }

  Future<void> _createClass() async {
    final id = await Navigator.of(context).push<int>(
      MaterialPageRoute(builder: (_) => const WordClassFormScreen()),
    );
    if (id != null && mounted) _chooseCustomClass(id);
  }

  /// Para substantivos, grava sempre com o artigo da classe escolhida:
  /// "Hund" + masculino -> "der Hund".
  String _germanToStore() {
    final parsed = WordParser.parse(_german.text);
    final article = _category.article;
    if (article != null) return '$article ${parsed.lemma}';
    return parsed.display;
  }

  /// Campo vazio ou que não vale para a classe atual vira "ausente".
  Value<String?> _optional(TextEditingController c, {bool applies = true}) {
    final text = c.text.trim();
    if (!applies || text.isEmpty) return const Value.absent();
    return Value(text);
  }

  /// O campo já mostra os colchetes; aqui eles são acrescentados ao salvar.
  /// Se o usuário digitou os colchetes mesmo assim, não duplica.
  /// Transcrição fonêmica entre barras (/…/) é mantida como está.
  Value<String?> _ipaToStore() {
    var text = _ipa.text.trim();
    if (text.isEmpty) return const Value.absent();
    if (text.length > 1 && text.startsWith('/') && text.endsWith('/')) {
      return Value(text);
    }
    if (text.startsWith('[')) text = text.substring(1);
    if (text.endsWith(']')) text = text.substring(0, text.length - 1);
    text = text.trim();
    if (text.isEmpty) return const Value.absent();
    return Value('[$text]');
  }

  Future<void> _createDeck() async {
    final id = await NewDeckSheet.show(context);
    if (id != null && mounted) setState(() => _deckId = id);
  }

  String? _validateGerman(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Digite a palavra em alemão.';
    if (_category.isNoun && GrammarCategory.fromArticle(text) != null) {
      return 'Digite o substantivo depois do artigo.';
    }
    if (_germanToStore().length > 100) return 'Use no máximo 100 caracteres.';
    return null;
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final german = _germanToStore();
    final c = _category;
    final entry = WordEntriesCompanion.insert(
      germanWord: german,
      portugueseTranslation: _translation.text.trim(),
      category: c,
      ipaPronunciation: _ipaToStore(),
      brazilianApproximation: _optional(_approximation),
      phoneticTip: _optional(_tip),
      pluralForm: _optional(_plural, applies: c.isNoun),
      tagDetail: _optional(_tagDetail, applies: !c.isNoun),
      verbForms: _optional(_verbForms, applies: c == GrammarCategory.verb),
      conjugation: _optional(_conjugation, applies: c == GrammarCategory.verb),
      degrees: _optional(
        _degrees,
        applies: c == GrammarCategory.adjective || c == GrammarCategory.adverb,
      ),
      prepositionCase: _optional(
        _prepositionCase,
        applies: c == GrammarCategory.preposition,
      ),
      exampleGerman: _optional(_exampleDe),
      examplePortuguese: _optional(_examplePt),
      deckId: Value(_deckId),
      customClassId: Value(c == GrammarCategory.other ? _customClassId : null),
    );

    try {
      await ref.read(databaseProvider).addWord(entry);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$german" foi adicionada ao Notizbuch.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar a ficha: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = _category;
    final classes = WordClassScope.of(context);
    final customClass =
        c == GrammarCategory.other ? classes[_customClassId] : null;
    final accent = appearanceFor(c, customClass, isDark: isDark).color;
    final hasForms = c != GrammarCategory.other;

    return Scaffold(
      appBar: ScreenHeader(
        title: 'Registrar Palavra',
        trailing: HeaderActionButton(
          iconPath: AppIcons.volumeUp,
          label: 'TTS',
          tooltip: 'Ouvir pronúncia',
          onTap: () {
            if (_german.text.trim().isEmpty) return;
            speakWithFeedback(context, _germanToStore());
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              children: [
                _SectionCard(
                  icon: Icons.edit_note_rounded,
                  title: 'Palavra em alemão *',
                  trailing: const _MetaText('Obrigatório'),
                  accent: accent,
                  children: [
                    _InlineField(
                      controller: _german,
                      hint: 'der Hund, gehen, schön…',
                      germanInput: true,
                      serif: true,
                      autofocus: true,
                      onChanged: _onGermanChanged,
                      validator: _validateGerman,
                    ),
                  ],
                ),

                const Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 10),
                  child: Row(
                    children: [
                      Expanded(child: _SectionLabel('Deck')),
                      _MetaText('Toque para escolher'),
                    ],
                  ),
                ),
                _DeckPicker(
                  selectedId: _deckId,
                  onSelected: (id) => setState(() => _deckId = id),
                  onCreate: _createDeck,
                ),
                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: _SectionLabel('Classe gramatical (Wortart)'),
                      ),
                      _MetaText(
                        _categoryChosenByUser || _german.text.trim().isEmpty
                            ? 'Toque para ajustar'
                            : 'Sugerida',
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: chipRowHeight(context),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final category in GrammarCategory.values) ...[
                        _CategoryChip(
                          label: category.shortLabel,
                          color: GrammarColors.of(category, isDark: isDark),
                          selected: category == c && customClass == null,
                          onSelected: () => _chooseCategory(category),
                        ),
                        const SizedBox(width: 8),
                      ],
                      for (final wc in classes.values) ...[
                        _CategoryChip(
                          label: wc.name,
                          color: customClassColor(
                            Color(wc.color),
                            isDark: isDark,
                          ),
                          selected: customClass?.id == wc.id,
                          onSelected: () => _chooseCustomClass(wc.id),
                        ),
                        const SizedBox(width: 8),
                      ],
                      _NewClassChip(onTap: _createClass),
                    ],
                  ),
                ),
                if (_articleAmbiguous && c == GrammarCategory.feminineNoun)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '"die" também é o artigo do plural. Se você digitou um '
                      'plural, cadastre a forma no singular.',
                      style: TextStyle(fontSize: 12, color: p.text500),
                    ),
                  ),
                const SizedBox(height: 16),

                _SectionCard(
                  icon: Icons.translate_rounded,
                  title: 'Tradução em português *',
                  trailing: const _MetaText('Obrigatório'),
                  accent: accent,
                  children: [
                    _InlineField(
                      controller: _translation,
                      hint: 'o cachorro',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Digite a tradução.'
                          : null,
                    ),
                  ],
                ),

                if (hasForms)
                  _SectionCard(
                    icon: Icons.inventory_2_outlined,
                    title: c.isNoun ? 'Forma de plural' : 'Formas',
                    trailing: const _MetaText('Opcional'),
                    accent: accent,
                    children: [
                      if (c.isNoun)
                        _InlineField(
                          controller: _plural,
                          hint: 'die Hunde',
                          germanInput: true,
                          serif: true,
                        ),
                      if (!c.isNoun)
                        _BoxField(
                          controller: _tagDetail,
                          label: 'Detalhe da classe',
                          hint: c == GrammarCategory.preposition
                              ? 'dativo'
                              : 'irregular',
                        ),
                      if (c == GrammarCategory.verb) ...[
                        _BoxField(
                          controller: _verbForms,
                          label: 'Pretérito e particípio',
                          hint: 'ging · ist gegangen',
                          germanInput: true,
                        ),
                        _BoxField(
                          controller: _conjugation,
                          label: 'Presente (uma linha por grupo)',
                          hint: 'ich gehe · du gehst · er geht\n'
                              'wir gehen · ihr geht · sie gehen',
                          germanInput: true,
                          maxLines: 3,
                        ),
                      ],
                      if (c == GrammarCategory.adjective ||
                          c == GrammarCategory.adverb)
                        _BoxField(
                          controller: _degrees,
                          label: 'Graus',
                          hint: 'schön → schöner → am schönsten',
                          germanInput: true,
                        ),
                      if (c == GrammarCategory.preposition)
                        _BoxField(
                          controller: _prepositionCase,
                          label: 'Regra de regência',
                          hint: 'sempre com dativo: aus · bei · mit · nach',
                        ),
                    ],
                  ),

                _SectionCard(
                  icon: Icons.record_voice_over_outlined,
                  title: 'Pronúncia',
                  trailing: const _MetaText('Opcional'),
                  accent: accent,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _BoxField(
                            controller: _ipa,
                            label: 'Transcrição IPA',
                            hint: 'ˈɡeːən',
                            germanInput: true,
                            mono: true,
                            brackets: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _BoxField(
                            controller: _approximation,
                            label: 'Aproximação PT',
                            hint: 'GUÊ-en',
                          ),
                        ),
                      ],
                    ),
                    Divider(height: 1, color: p.outline),
                    const SizedBox(height: 12),
                    const _FieldLabel('Dica fonética'),
                    _InlineField(
                      controller: _tip,
                      hint: 'O g é sempre duro, como em "gato".',
                      italic: true,
                      maxLines: 3,
                    ),
                  ],
                ),

                _SectionCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Beispielsatz (frase de exemplo)',
                  trailing: const _MetaText('Opcional'),
                  accent: accent,
                  children: [
                    _BoxField(
                      controller: _exampleDe,
                      label: 'Em alemão',
                      hint: 'Der Hund schläft im Garten.',
                      germanInput: true,
                      serif: true,
                      maxLines: 3,
                    ),
                    _BoxField(
                      controller: _examplePt,
                      label: 'Tradução em português',
                      hint: 'O cachorro dorme no jardim.',
                      maxLines: 3,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Salvar no Notizbuch'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rótulo de seção em caixa alta (fora dos cartões).
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Text(
      text.toUpperCase(),
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: p.text600,
      ),
    );
  }
}

/// Texto auxiliar à direita dos cabeçalhos ("Obrigatório", "Opcional"…).
class _MetaText extends StatelessWidget {
  const _MetaText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 12, color: AppPalette.of(context).text400),
    );
  }
}

/// Rótulo pequeno em caixa alta, usado dentro dos cartões e caixas.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: AppPalette.of(context).text500,
        ),
      ),
    );
  }
}

/// Cartão de seção: ícone + título em caixa alta + texto à direita,
/// e o conteúdo abaixo.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.accent,
    required this.children,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Color accent;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: accent,
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

/// Estilo do texto digitado, compartilhado pelos dois tipos de campo.
TextStyle _inputStyle(
  AppPalette p, {
  required bool serif,
  bool mono = false,
  bool italic = false,
  double fontSize = 16,
}) {
  if (mono) return AppTheme.mono(fontSize: fontSize, color: p.text800);
  if (serif) {
    return AppTheme.serif(
      fontSize: fontSize + 2,
      fontWeight: FontWeight.w600,
      color: p.text900,
    );
  }
  return TextStyle(
    fontSize: fontSize,
    fontStyle: italic ? FontStyle.italic : FontStyle.normal,
    color: italic ? p.text600 : p.text900,
  );
}

InputDecoration _bareDecoration(AppPalette p, String? hint) => InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: p.text400, fontStyle: FontStyle.normal),
      isDense: true,
      filled: false,
      contentPadding: EdgeInsets.zero,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
    );

/// Campo sem moldura, direto no cartão (palavra, tradução, plural, dica).
class _InlineField extends StatelessWidget {
  const _InlineField({
    required this.controller,
    this.hint,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
    this.germanInput = false,
    this.autofocus = false,
    this.serif = false,
    this.italic = false,
  });

  final TextEditingController controller;
  final String? hint;
  final int maxLines;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  /// Desliga a autocorreção (o corretor em português estraga o alemão).
  final bool germanInput;
  final bool autofocus;
  final bool serif;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 10),
      child: TextFormField(
        controller: controller,
        autofocus: autofocus,
        minLines: 1,
        maxLines: maxLines,
        autocorrect: !germanInput,
        enableSuggestions: !germanInput,
        textInputAction:
            maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
        validator: validator,
        onChanged: onChanged,
        style: _inputStyle(p, serif: serif, italic: italic, fontSize: 18),
        decoration: _bareDecoration(p, hint),
      ),
    );
  }
}

/// Caixa suave com rótulo pequeno em cima e o campo dentro
/// (IPA, aproximação, frases de exemplo, formas do verbo…).
class _BoxField extends StatelessWidget {
  const _BoxField({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.germanInput = false,
    this.serif = false,
    this.mono = false,
    this.brackets = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final bool germanInput;
  final bool serif;
  final bool mono;

  /// Mostra "[" e "]" fixos em volta do texto (IPA).
  final bool brackets;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final style = _inputStyle(p, serif: serif, mono: mono, fontSize: 15);
    final field = TextFormField(
      controller: controller,
      minLines: 1,
      maxLines: maxLines,
      autocorrect: !germanInput,
      enableSuggestions: !germanInput,
      textInputAction:
          maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
      style: style,
      decoration: _bareDecoration(p, hint),
    );
    final bracket = style.copyWith(color: p.text400);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: p.pronBox,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FieldLabel(label),
          if (brackets)
            Row(
              children: [
                Text('[', style: bracket),
                const SizedBox(width: 2),
                Expanded(child: field),
                const SizedBox(width: 2),
                Text(']', style: bracket),
              ],
            )
          else
            field,
        ],
      ),
    );
  }
}

/// Linha rolável com os decks (chips neutros) e o chip "+ Novo".
class _DeckPicker extends ConsumerWidget {
  const _DeckPicker({
    required this.selectedId,
    required this.onSelected,
    required this.onCreate,
  });

  final int selectedId;
  final ValueChanged<int> onSelected;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = AppPalette.of(context);
    final decks =
        ref.watch(deckSummariesProvider).valueOrNull ?? const <DeckSummary>[];
    // "Geral" primeiro aqui: é o padrão.
    final ordered = [
      ...decks.where((d) => d.isGeneral),
      ...decks.where((d) => !d.isGeneral),
    ];

    Widget chip({
      required IconData icon,
      required String label,
      required bool selected,
      required VoidCallback onTap,
      bool dashed = false,
    }) {
      final radius = BorderRadius.circular(12);
      return Material(
        color: selected ? p.ink : (dashed ? Colors.transparent : p.card),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? p.ink : (dashed ? p.dots : p.outline),
            width: dashed ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? p.onInk : p.text500,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? p.onInk : p.text700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: chipRowHeight(context),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final d in ordered) ...[
            chip(
              icon: d.deck.icon.data,
              label: d.deck.namePt,
              selected: d.deck.id == selectedId,
              onTap: () => onSelected(d.deck.id),
            ),
            const SizedBox(width: 8),
          ],
          chip(
            icon: Icons.add_rounded,
            label: 'Novo',
            selected: false,
            dashed: true,
            onTap: onCreate,
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(12);

    // A cor da classe aparece sempre: sem seleção, fundo levemente tingido
    // e borda/texto na cor; selecionado, preenchido com a cor.
    return Material(
      color: selected ? color : color.withValues(alpha: isDark ? 0.14 : 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: color.withValues(alpha: selected ? 1 : 0.45)),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onSelected,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected
                    ? GrammarColors.onCategory(isDark: isDark)
                    : color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Chip tracejado "+ Nova" no fim da linha de classes.
class _NewClassChip extends StatelessWidget {
  const _NewClassChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final radius = BorderRadius.circular(12);
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: p.dots, width: 1.5),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 16, color: p.text500),
              const SizedBox(width: 6),
              Text(
                'Nova',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: p.text500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Altura das linhas roláveis de chips: 40 px no tamanho normal, maior
/// quando o texto está aumentado (o chip tem texto de 14 px).
double chipRowHeight(BuildContext context) =>
    math.max(40, MediaQuery.textScalerOf(context).scale(14) * 1.4 + 20);
