import '../../vocabulary/providers/vocabulary_provider.dart' show WordFilter;

/// Em que ordem as fichas entram na sessão.
enum SessionOrder {
  smart('Novas e erradas primeiro'),
  random('Aleatória'),
  recent('Mais recentes');

  const SessionOrder(this.label);
  final String label;
}

/// Filtro, ordem e tamanho da sessão de estudo.
class StudySettings {
  const StudySettings({
    this.filter = WordFilter.all,
    this.order = SessionOrder.smart,
    this.size = defaultSize,
  });

  static const int defaultSize = 20;

  /// Opções de tamanho na folha de filtros. `null` = todas as fichas.
  static const List<int?> sizeOptions = [10, 20, 30, null];

  final WordFilter filter;
  final SessionOrder order;

  /// Quantas fichas por sessão. `null` = todas.
  final int? size;

  StudySettings copyWith({
    WordFilter? filter,
    SessionOrder? order,
    int? size,
    bool allCards = false,
  }) {
    return StudySettings(
      filter: filter ?? this.filter,
      order: order ?? this.order,
      size: allCards ? null : (size ?? this.size),
    );
  }
}
