import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../vocabulary/providers/vocabulary_provider.dart';
import '../../models/deck_icon.dart';
import '../deck_icon_data.dart';
import 'deck_card.dart';

/// Folha inferior para criar um deck: nome em português, nome em alemão
/// (opcional) e ícone.
class NewDeckSheet extends ConsumerStatefulWidget {
  const NewDeckSheet({super.key});

  /// Abre a folha. Retorna o id do deck criado, ou `null` se cancelar.
  static Future<int?> show(BuildContext context) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppPalette.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const NewDeckSheet(),
    );
  }

  @override
  ConsumerState<NewDeckSheet> createState() => _NewDeckSheetState();
}

class _NewDeckSheetState extends ConsumerState<NewDeckSheet> {
  final _formKey = GlobalKey<FormState>();
  final _namePt = TextEditingController();
  final _nameDe = TextEditingController();
  DeckIcon _icon = DeckIcon.health;
  bool _saving = false;

  @override
  void dispose() {
    _namePt.dispose();
    _nameDe.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final nameDe = _nameDe.text.trim();
    try {
      final id = await ref.read(databaseProvider).addDeck(
            DecksCompanion.insert(
              namePt: _namePt.text.trim(),
              nameDe: nameDe.isEmpty ? const Value.absent() : Value(nameDe),
              icon: _icon,
            ),
          );
      if (mounted) Navigator.of(context).pop(id);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível criar o deck: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    const label = TextStyle(
      fontFamily: AppTheme.sansFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    );
    const buttonSize = Size.fromHeight(44);

    return Padding(
      // Sobe junto com o teclado.
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.dots,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'NOVO DECK',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: p.text600,
                  ),
                ),
                const SizedBox(height: 12),
                _SheetField(
                  controller: _namePt,
                  label: 'Nome em português',
                  hint: 'Saúde',
                  autofocus: true,
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return 'Dê um nome ao deck.';
                    if (t.length > 40) return 'Use no máximo 40 caracteres.';
                    return null;
                  },
                ),
                _SheetField(
                  controller: _nameDe,
                  label: 'Nome em alemão (opcional)',
                  hint: 'Gesundheit',
                  german: true,
                ),
                const SizedBox(height: 4),
                Text(
                  'ÍCONE',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: p.text500,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final icon in DeckIcon.values)
                      Semantics(
                        button: true,
                        selected: icon == _icon,
                        label: icon.label,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(11),
                          onTap: () => setState(() => _icon = icon),
                          child: DeckIconBox(
                            icon: icon.data,
                            size: 40,
                            selected: icon == _icon,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          minimumSize: buttonSize,
                          backgroundColor: p.softButton,
                          foregroundColor: p.text700,
                          textStyle: label,
                          shape: shape,
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _saving ? null : _create,
                        style: FilledButton.styleFrom(
                          minimumSize: buttonSize,
                          backgroundColor: p.ink,
                          foregroundColor: p.onInk,
                          textStyle: label,
                          shape: shape,
                        ),
                        child: const Text('Criar deck'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Campo em caixa clara com rótulo pequeno em cima.
class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.label,
    this.hint,
    this.validator,
    this.autofocus = false,
    this.german = false,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final bool autofocus;

  /// Desliga a autocorreção e usa itálico serifado, como o nome em alemão.
  final bool german;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: p.pronBox,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              color: p.text500,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            autofocus: autofocus,
            autocorrect: !german,
            enableSuggestions: !german,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            validator: validator,
            style: german
                ? AppTheme.serif(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: p.text900,
                  )
                : TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: p.text900,
                  ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: p.text400,
                fontStyle: FontStyle.normal,
                fontWeight: FontWeight.w400,
              ),
              isDense: true,
              filled: false,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}
