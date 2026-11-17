import '../../../core/database/app_database.dart';
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
    this.customClassId,
    this.order = SessionOrder.smart,
    this.size = defaultSize,
  });

  static const int defaultSize = 20;

  /// Opções de tamanho na folha de filtros. `null` = todas as fichas.
  static const List<int?> sizeOptions = [10, 20, 30, null];

  final WordFilter filter;

  /// Classe criada pelo usuário escolhida no filtro. Quando preenchida,
  /// vale no lugar de [filter].
  final int? customClassId;

  final SessionOrder order;

  /// Quantas fichas por sessão. `null` = todas.
  final int? size;

  /// A palavra passa no filtro de classe?
  bool matches(WordEntry w) {
    final custom = customClassId;
    if (custom != null) return w.customClassId == custom;
    // "Outros" não inclui as classes criadas: elas têm filtro próprio.
    if (filter == WordFilter.others && w.customClassId != null) return false;
    return filter.matches(w.category);
  }

  /// Nome do filtro atual ("Todos", "der", "Conjunção"…).
  String filterLabel(Map<int, WordClass> classes) {
    final custom = customClassId;
    if (custom == null) return filter.label;
    return classes[custom]?.name ?? 'Classe excluída';
  }

  /// Escolher uma classe do método limpa a classe criada, e vice-versa.
  StudySettings copyWith({
    WordFilter? filter,
    int? customClassId,
    SessionOrder? order,
    int? size,
    bool allCards = false,
  }) {
    final pickedBuiltIn = filter != null;
    return StudySettings(
      filter: customClassId != null ? WordFilter.all : (filter ?? this.filter),
      customClassId: pickedBuiltIn
          ? null
          : (customClassId ?? this.customClassId),
      order: order ?? this.order,
      size: allCards ? null : (size ?? this.size),
    );
  }

  /// Sem filtro de classe.
  StudySettings withoutClassFilter() =>
      StudySettings(order: order, size: size);
}
