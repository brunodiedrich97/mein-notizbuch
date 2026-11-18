import '../../../core/database/app_database.dart';

/// Texto da notificação da palavra do dia.
class ReminderContent {
  const ReminderContent({
    required this.title,
    required this.category,
    required this.meaning,
  });

  /// A palavra no idioma de estudo: "der Hund".
  final String title;

  /// Classe gramatical: "substantivo · masculino".
  final String category;

  /// Significado: "o cachorro".
  final String meaning;

  /// Classe entre parênteses: "(substantivo · masculino)".
  String get _categoryLine => '($category)';

  /// Classe numa linha e significado na seguinte.
  String get twoLines => '$_categoryLine\n$meaning';

  /// Tudo numa linha só (notificação recolhida no Android).
  String get oneLine => '$_categoryLine — $meaning';

  // Versões em HTML para o Android, com a classe em itálico. O iOS não
  // aceita formatação no texto da notificação.

  /// "<i>(substantivo · masculino)</i> — o cachorro".
  String get oneLineHtml =>
      '<i>${_escape(_categoryLine)}</i> — ${_escape(meaning)}';

  /// Classe em itálico numa linha e significado na seguinte.
  String get twoLinesHtml =>
      '<i>${_escape(_categoryLine)}</i><br>${_escape(meaning)}';

  static String _escape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  /// [customClass] é a classe criada pelo usuário da palavra, se houver
  /// (o nome dela substitui o da classe do método).
  factory ReminderContent.fromWord(
    WordEntry word, {
    WordClass? customClass,
  }) {
    final base = customClass?.name.toLowerCase() ?? word.category.label;
    final detail = word.tagDetail?.trim();
    final category =
        (detail == null || detail.isEmpty) ? base : '$base · $detail';
    return ReminderContent(
      title: word.germanWord,
      category: category,
      meaning: word.portugueseTranslation,
    );
  }
}
