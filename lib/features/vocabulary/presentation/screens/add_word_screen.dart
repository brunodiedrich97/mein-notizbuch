import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/grammar_colors.dart';
import '../../models/grammar_type.dart';
import '../../models/word_parser.dart';
import '../../providers/vocabulary_provider.dart';
import '../widgets/pronunciation_box.dart';

class AddWordScreen extends ConsumerStatefulWidget {
  const AddWordScreen({super.key});

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
  bool _articleAmbiguous = false;
  bool _saving = false;

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
      _categoryChosenByUser = true;
    });
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
      ipaPronunciation: _optional(_ipa),
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
    );

    try {
      await ref.read(databaseProvider).addWord(entry);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('«$german» foi adicionada ao caderno.')),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintColor = isDark ? Colors.white60 : Colors.black54;
    final c = _category;
    final hasForms = c != GrammarCategory.other;

    return Scaffold(
      appBar: AppBar(title: const Text('Nova palavra')),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                const _SectionLabel('Palavra'),
                _Field(
                  controller: _german,
                  label: 'Em alemão',
                  hint: 'der Hund, gehen, schön…',
                  germanInput: true,
                  autofocus: true,
                  onChanged: _onGermanChanged,
                  validator: _validateGerman,
                  suffix: IconButton(
                    icon: const Icon(Icons.volume_up),
                    tooltip: 'Ouvir pronúncia',
                    onPressed: () {
                      if (_german.text.trim().isEmpty) return;
                      speakWithFeedback(context, _germanToStore());
                    },
                  ),
                ),
                _Field(
                  controller: _translation,
                  label: 'Tradução',
                  hint: 'o cachorro',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Digite a tradução.'
                      : null,
                ),

                const _SectionLabel('Classe gramatical'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in GrammarCategory.values)
                      _CategoryChip(
                        category: category,
                        selected: category == c,
                        onSelected: () => _chooseCategory(category),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (!_categoryChosenByUser && _german.text.trim().isNotEmpty)
                  Text(
                    'Classe sugerida pelo que você digitou. Toque em outra '
                    'para corrigir.',
                    style: TextStyle(fontSize: 13, color: hintColor),
                  ),
                if (_articleAmbiguous && c == GrammarCategory.feminineNoun)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '"die" também é o artigo do plural. Se você digitou um '
                      'plural, cadastre a forma no singular.',
                      style: TextStyle(fontSize: 13, color: hintColor),
                    ),
                  ),

                if (hasForms) ...[
                  const _SectionLabel('Formas'),
                  if (c.isNoun)
                    _Field(
                      controller: _plural,
                      label: 'Plural',
                      hint: 'die Hunde',
                      germanInput: true,
                    ),
                  if (!c.isNoun)
                    _Field(
                      controller: _tagDetail,
                      label: 'Detalhe da classe (opcional)',
                      hint: c == GrammarCategory.preposition
                          ? 'dativo'
                          : 'irregular',
                    ),
                  if (c == GrammarCategory.verb) ...[
                    _Field(
                      controller: _verbForms,
                      label: 'Pretérito e particípio',
                      hint: 'ging · ist gegangen',
                      germanInput: true,
                    ),
                    _Field(
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
                    _Field(
                      controller: _degrees,
                      label: 'Graus',
                      hint: 'schön → schöner → am schönsten',
                      germanInput: true,
                    ),
                  if (c == GrammarCategory.preposition)
                    _Field(
                      controller: _prepositionCase,
                      label: 'Regra de regência',
                      hint: 'sempre com dativo: aus · bei · mit · nach',
                    ),
                ],

                const _SectionLabel('Pronúncia'),
                _Field(
                  controller: _ipa,
                  label: 'IPA',
                  hint: '[ˈɡeːən]',
                  germanInput: true,
                ),
                _Field(
                  controller: _approximation,
                  label: 'Aproximação em português',
                  hint: 'GUÊ-en',
                ),
                _Field(
                  controller: _tip,
                  label: 'Dica fonética',
                  hint: 'O g é sempre duro, como em "gato".',
                  maxLines: 3,
                ),

                const _SectionLabel('Exemplo'),
                _Field(
                  controller: _exampleDe,
                  label: 'Frase em alemão',
                  hint: 'Der Hund schläft im Garten.',
                  germanInput: true,
                  maxLines: 3,
                ),
                _Field(
                  controller: _examplePt,
                  label: 'Tradução da frase',
                  hint: 'O cachorro dorme no jardim.',
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
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
                      : const Text('Salvar no caderno'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white70 : const Color(0xFF2D3748),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
    this.suffix,
    this.germanInput = false,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int maxLines;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;

  /// Desliga a autocorreção (o corretor em português estraga o alemão).
  final bool germanInput;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixIcon: suffix,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onSelected,
  });

  final GrammarCategory category;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = GrammarColors.of(category, isDark: isDark);

    return ChoiceChip(
      label: Text(category.shortLabel),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onSelected(),
      avatar: selected
          ? null
          : Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
      selectedColor: color,
      shape: const StadiumBorder(),
      side: BorderSide(color: selected ? color : color.withValues(alpha: 0.4)),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: selected ? GrammarColors.onCategory(isDark: isDark) : color,
      ),
    );
  }
}
