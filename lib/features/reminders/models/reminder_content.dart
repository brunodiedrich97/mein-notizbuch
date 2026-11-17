import '../../../core/database/app_database.dart';

/// Idiomas de tradução. Hoje só existe o português do Brasil; outros
/// idiomas entram aqui, e [translationOf] passa a escolher a coluna certa.
enum TranslationLanguage { ptBR }

/// Tradução de [word] no idioma [language].
String translationOf(
  WordEntry word, {
  TranslationLanguage language = TranslationLanguage.ptBR,
}) {
  return switch (language) {
    TranslationLanguage.ptBR => word.portugueseTranslation,
  };
}

/// Texto da notificação da palavra do dia.
class ReminderContent {
  const ReminderContent({
    required this.title,
    required this.category,
    required this.meaning,
  });

  /// A palavra em alemão: "der Hund".
  final String title;

  /// Classe gramatical: "substantivo · masculino".
  final String category;

  /// Significado: "o cachorro".
  final String meaning;

  /// Classe numa linha e significado na seguinte.
  String get twoLines => '$category\n$meaning';

  /// Tudo numa linha só (notificação recolhida no Android).
  String get oneLine => '$category — $meaning';

  factory ReminderContent.fromWord(
    WordEntry word, {
    TranslationLanguage language = TranslationLanguage.ptBR,
  }) {
    final detail = word.tagDetail?.trim();
    final category = (detail == null || detail.isEmpty)
        ? word.category.label
        : '${word.category.label} · $detail';
    return ReminderContent(
      title: word.germanWord,
      category: category,
      meaning: translationOf(word, language: language),
    );
  }
}
