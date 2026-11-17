import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/grammar_colors.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../../core/widgets/screen_header.dart';
import '../../../vocabulary/models/grammar_type.dart';
import '../../../vocabulary/providers/vocabulary_provider.dart';
import '../../../word_classes/presentation/word_appearance.dart';
import '../../models/sentence_check.dart';
import '../../models/sentence_source.dart';
import '../widgets/umlaut_keys.dart';

/// Frase livre: o usuário escreve uma frase com a palavra da ficha, e ela
/// é salva em "Minhas frases".
class WriteSentenceScreen extends ConsumerStatefulWidget {
  const WriteSentenceScreen({super.key, required this.wordId});

  final int wordId;

  @override
  ConsumerState<WriteSentenceScreen> createState() =>
      _WriteSentenceScreenState();
}

class _WriteSentenceScreenState extends ConsumerState<WriteSentenceScreen> {
  final _german = TextEditingController();
  final _portuguese = TextEditingController();
  final _focus = FocusNode();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _german.addListener(() => setState(() {}));
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _german.dispose();
    _portuguese.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _german.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    final pt = _portuguese.text.trim();
    await ref.read(databaseProvider).addSentence(
          SentencesCompanion.insert(
            wordId: widget.wordId,
            german: text,
            portuguese: pt.isEmpty ? const Value.absent() : Value(pt),
            source: SentenceSource.free,
          ),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Frase salva na ficha.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final words = ref.watch(wordListProvider).valueOrNull ?? const [];
    final matches = words.where((w) => w.id == widget.wordId);
    final WordEntry? word = matches.isEmpty ? null : matches.first;

    if (word == null) {
      return const Scaffold(
        appBar: ScreenHeader(title: 'Escrever frase'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final text = _german.text.trim();
    final uses =
        text.isNotEmpty && sentenceUsesWord(text, word.germanWord, word.category);
    final lemma = stripArticle(word.germanWord);
    final example = word.exampleGerman?.trim();
    final examplePt = word.examplePortuguese?.trim();

    return Scaffold(
      backgroundColor: p.page,
      appBar: ScreenHeader(
        eyebrow: word.germanWord.toUpperCase(),
        title: 'Escrever frase',
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            children: [
              Text('ESCREVA UMA FRASE COM', style: AppText.caption(p)),
              const SizedBox(height: 8),
              Text(
                word.germanWord,
                style: AppTheme.serif(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  color: appearanceOf(context, word).titleColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(word.portugueseTranslation, style: AppText.body(p)),
              const SizedBox(height: 16),
              WritingField(
                controller: _german,
                focusNode: _focus,
                hint: 'Escreva aqui em alemão…',
                autofocus: true,
              ),
              const SizedBox(height: 8),
              UmlautKeys(controller: _german),
              const SizedBox(height: 12),
              if (text.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      uses ? Icons.check_rounded : Icons.info_outline_rounded,
                      size: 16,
                      color: uses
                          ? GrammarColors.of(
                              GrammarCategory.neuterNoun,
                              isDark: isDark,
                            )
                          : p.text400,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        uses
                            ? 'A frase usa "$lemma".'
                            : 'A frase ainda não usa "$lemma".',
                        style: AppText.meta(p).copyWith(
                          fontWeight: FontWeight.w600,
                          color: uses
                              ? GrammarColors.of(
                                  GrammarCategory.neuterNoun,
                                  isDark: isDark,
                                )
                              : p.text500,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              _BoxField(
                label: 'Tradução (opcional)',
                controller: _portuguese,
                hint: 'O que a frase quer dizer',
              ),
              if (example != null && example.isNotEmpty) ...[
                const SizedBox(height: 12),
                ReferenceBox(
                  label: 'Exemplo da ficha, para comparar',
                  german: example,
                  portuguese: examplePt,
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: WritingFooter(
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
              label: 'Salvar na ficha',
              onPressed: text.isEmpty || _saving ? null : _save,
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo grande de escrita em alemão (serifa), com borda escura no foco.
class WritingField extends StatelessWidget {
  const WritingField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    this.autofocus = false,
    this.enabled = true,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final bool autofocus;
  final bool enabled;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final focused = focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focused ? p.ink : p.outline,
          width: focused ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        enabled: enabled,
        minLines: 2,
        maxLines: 5,
        maxLength: 300,
        // O corretor em português estraga o alemão.
        autocorrect: false,
        enableSuggestions: false,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
        style: AppTheme.serif(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: p.text900,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppText.item(p).copyWith(
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
          disabledBorder: InputBorder.none,
        ),
      ),
    );
  }
}

/// Caixa clara com uma frase de referência (alemão + português).
class ReferenceBox extends StatelessWidget {
  const ReferenceBox({
    super.key,
    required this.label,
    required this.german,
    this.portuguese,
  });

  final String label;
  final String german;
  final String? portuguese;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final pt = portuguese;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: p.pronBox,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: AppText.caption(p)),
          const SizedBox(height: 6),
          Text(
            german,
            style: AppTheme.serif(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: p.text900,
            ),
          ),
          if (pt != null && pt.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(pt, style: AppText.body(p).copyWith(color: p.text500)),
          ],
        ],
      ),
    );
  }
}

class _BoxField extends StatelessWidget {
  const _BoxField({
    required this.label,
    required this.controller,
    required this.hint,
  });

  final String label;
  final TextEditingController controller;
  final String hint;

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
          Text(label.toUpperCase(), style: AppText.caption(p)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            style: AppText.item(p).copyWith(fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppText.item(p).copyWith(
                fontSize: 15,
                color: p.text400,
                fontWeight: FontWeight.w400,
              ),
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

/// Rodapé com botões, no estilo do rodapé das fichas.
class WritingFooter extends StatelessWidget {
  const WritingFooter({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.footer,
        border: Border(top: BorderSide(color: p.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(children: children),
            ),
          ),
        ),
      ),
    );
  }
}
