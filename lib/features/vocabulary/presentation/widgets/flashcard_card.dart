import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/grammar_colors.dart';
import 'pronunciation_box.dart';

/// Uma ficha do caderno, reproduzindo o `<article class="flashcard">` do
/// protótipo.
class FlashcardCard extends StatelessWidget {
  const FlashcardCard({
    super.key,
    required this.word,
    this.margin = const EdgeInsets.all(16),
    this.sentences = const [],
    this.onWriteSentence,
    this.onSentenceLongPress,
  });

  final WordEntry word;
  final EdgeInsetsGeometry margin;

  /// "Minhas frases": frases escritas com esta palavra.
  final List<Sentence> sentences;

  /// "Escrever frase". Sem ele (e sem frases), a seção não aparece.
  final VoidCallback? onWriteSentence;

  /// Toque longo numa frase (ex.: excluir).
  final ValueChanged<Sentence>? onSentenceLongPress;

  /// `max-w-md` (448) menos o `p-4` (16) de cada lado.
  static const double maxCardWidth = 416;

  static String? _clean(String? value) {
    final t = value?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final category = word.category;
    final color = GrammarColors.of(category, isDark: isDark);
    // sm:p-7 a partir de 640 px de largura
    final padding = MediaQuery.sizeOf(context).width >= 640 ? 28.0 : 24.0;

    final tagDetail = _clean(word.tagDetail);
    final plural = _clean(word.pluralForm);
    final verbForms = _clean(word.verbForms);
    final degrees = _clean(word.degrees);
    final conjugation = _clean(word.conjugation);
    final ipa = _clean(word.ipaPronunciation);
    final approximation = _clean(word.brazilianApproximation);
    final tip = _clean(word.phoneticTip);
    final exampleDe = _clean(word.exampleGerman);
    final examplePt = _clean(word.examplePortuguese);
    final rule = _clean(word.prepositionCase);

    final label =
        tagDetail == null ? category.label : '${category.label} · $tagDetail';

    // Conteúdo depois do divisor pontilhado, na ordem do protótipo.
    final lower = <Widget>[
      if (conjugation != null)
        _Section(
          label: 'presente',
          child: _LinesText(conjugation, fontSize: 17),
        ),
      if (degrees != null)
        _Section(label: 'graus', child: _LinesText(degrees, fontSize: 17)),
      // Todas as classes: rótulo "EXEMPLO", frase e tradução abaixo.
      if (exampleDe != null)
        _Section(
          label: 'exemplo',
          child: _Example(german: exampleDe, portuguese: examplePt),
        ),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxCardWidth),
        child: Container(
          margin: margin,
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Rótulo da classe
                Row(
                  children: [
                    CategoryIcon(category, color: color),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.35,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Palavra
                Text(
                  word.germanWord,
                  style: AppTheme.serif(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: GrammarColors.titleOf(category, isDark: isDark),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),

                // Linha de apoio gramatical
                _SupportLine(
                  plural: plural,
                  verbForms: verbForms,
                  translation: word.portugueseTranslation,
                  color: p.text600,
                ),
                const SizedBox(height: 16),

                // Pronúncia
                PronunciationBox(
                  speakText: word.germanWord,
                  ipa: ipa,
                  approximation: approximation,
                ),
                if (tip != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    tip,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.625,
                      color: p.text600,
                    ),
                  ),
                ],

                // Seções inferiores, cada grupo após um divisor pontilhado
                if (lower.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _DottedDivider(color: p.dots),
                  const SizedBox(height: 16),
                  for (var i = 0; i < lower.length; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    lower[i],
                  ],
                ],
                if (rule != null) ...[
                  SizedBox(height: lower.isEmpty ? 20 : 16),
                  _DottedDivider(color: p.dots),
                  const SizedBox(height: 16),
                  _RuleSection(rule),
                ],
                if (sentences.isNotEmpty || onWriteSentence != null) ...[
                  const SizedBox(height: 20),
                  _DottedDivider(color: p.dots),
                  const SizedBox(height: 16),
                  _SentencesSection(
                    sentences: sentences,
                    onWrite: onWriteSentence,
                    onLongPress: onSentenceLongPress,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "plural: die Hunde · o cachorro" ou "ging · ist gegangen · ir (a pé)".
class _SupportLine extends StatelessWidget {
  const _SupportLine({
    required this.plural,
    required this.verbForms,
    required this.translation,
    required this.color,
  });

  final String? plural;
  final String? verbForms;
  final String translation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: 16, height: 1.5, color: color);
    final plural = this.plural;
    final verbForms = this.verbForms;

    if (plural != null) {
      // Substantivo: ponto mais claro (opacity-60) com margem dos dois lados.
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'plural: $plural'),
            TextSpan(
              text: '  ·  ',
              style: TextStyle(color: color.withValues(alpha: 0.6)),
            ),
            TextSpan(text: translation),
          ],
        ),
        style: style,
      );
    }
    if (verbForms != null) {
      return Text('$verbForms · $translation', style: style);
    }
    return Text(translation, style: style);
  }
}

/// Bloco com rótulo em caixa alta ("EXEMPLO", "PRESENTE", "GRAUS").
class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            height: 16 / 12,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w600,
            color: p.text400,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

/// Linhas em sans, médio, cinza-900 (conjugação e graus).
class _LinesText extends StatelessWidget {
  const _LinesText(this.text, {required this.fontSize, this.letterSpacing});

  final String text;
  final double fontSize;
  final double? letterSpacing;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final lines = text.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 4),
            child: Text(
              lines[i],
              style: TextStyle(
                fontSize: fontSize,
                height: 1.5,
                fontWeight: FontWeight.w500,
                letterSpacing: letterSpacing,
                color: p.text900,
              ),
            ),
          ),
      ],
    );
  }
}

class _Example extends StatelessWidget {
  const _Example({required this.german, this.portuguese});

  final String german;
  final String? portuguese;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final portuguese = this.portuguese;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          german,
          style: AppTheme.serif(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            height: 1.375,
            color: p.text900,
          ),
        ),
        if (portuguese != null) ...[
          const SizedBox(height: 4),
          Text(
            portuguese,
            style: TextStyle(fontSize: 15, height: 1.5, color: p.text600),
          ),
        ],
      ],
    );
  }
}

/// "MINHAS FRASES · 2", as frases (com a data) e "Escrever frase".
class _SentencesSection extends StatelessWidget {
  const _SentencesSection({
    required this.sentences,
    this.onWrite,
    this.onLongPress,
  });

  final List<Sentence> sentences;
  final VoidCallback? onWrite;
  final ValueChanged<Sentence>? onLongPress;

  static String _date(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}';
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final label = sentences.isEmpty
        ? 'minhas frases'
        : 'minhas frases · ${sentences.length}';

    return _Section(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < sentences.length; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: onLongPress == null
                  ? null
                  : () => onLongPress!(sentences[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: i == sentences.length - 1
                      ? null
                      : Border(bottom: BorderSide(color: p.divider)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sentences[i].german,
                            style: AppTheme.serif(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                              color: p.text900,
                            ),
                          ),
                          if (sentences[i].portuguese != null)
                            Text(
                              sentences[i].portuguese!,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: p.text500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _date(sentences[i].createdAt),
                      style: AppTheme.mono(fontSize: 10.5, color: p.text400),
                    ),
                  ],
                ),
              ),
            ),
          if (onWrite != null)
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onWrite,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: sentences.isEmpty ? 0 : 8,
                    bottom: 4,
                    right: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, size: 16, color: p.text700),
                      const SizedBox(width: 6),
                      Text(
                        'Escrever frase',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: p.text700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Regra da preposição. "sempre com dativo: aus · bei · mit" vira o rótulo
/// "SEMPRE COM DATIVO" e a lista abaixo.
class _RuleSection extends StatelessWidget {
  const _RuleSection(this.rule);

  final String rule;

  @override
  Widget build(BuildContext context) {
    final colon = rule.indexOf(':');
    final label = colon > 0 ? rule.substring(0, colon).trim() : 'regência';
    final body = colon > 0 ? rule.substring(colon + 1).trim() : rule;
    return _Section(
      label: label,
      child: _LinesText(body, fontSize: 18, letterSpacing: 0.45),
    );
  }
}

/// `border-top: 1.5px dotted #d1d5db` — pontos redondos de 1,5 px.
class _DottedDivider extends StatelessWidget {
  const _DottedDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 1.5),
      painter: _DotsPainter(color),
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    const diameter = 1.5;
    const spacing = 3.0; // ponto + espaço do mesmo tamanho, como no navegador
    for (var x = diameter / 2; x < size.width; x += spacing) {
      canvas.drawCircle(Offset(x, diameter / 2), diameter / 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DotsPainter oldDelegate) =>
      oldDelegate.color != color;
}
