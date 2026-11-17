import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';
import '../../../core/theme/grammar_colors.dart';
import '../../vocabulary/models/grammar_type.dart';

/// Disponibiliza as classes criadas pelo usuário para toda a árvore de
/// widgets (colocado acima do Navigator, em `main.dart`).
class WordClassScope extends InheritedWidget {
  const WordClassScope({
    super.key,
    required this.classes,
    required super.child,
  });

  final Map<int, WordClass> classes;

  /// Classes por id. Sem o escopo (ex.: testes), um mapa vazio.
  static Map<int, WordClass> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WordClassScope>()?.classes ??
      const {};

  @override
  bool updateShouldNotify(WordClassScope oldWidget) =>
      oldWidget.classes != classes;
}

/// Nome e cores com que uma palavra aparece.
class WordAppearance {
  const WordAppearance({
    required this.label,
    required this.color,
    required this.titleColor,
    this.customClass,
  });

  /// Rótulo da classe: "substantivo · masculino", "conjunção".
  final String label;

  /// Cor da classe (rótulos, chips, ícones).
  final Color color;

  /// Cor da palavra grande.
  final Color titleColor;

  /// Classe criada pelo usuário, se for o caso.
  final WordClass? customClass;

  bool get isCustom => customClass != null;
}

/// Aparência de [word] no tema atual: classe do método ou criada.
WordAppearance appearanceOf(BuildContext context, WordEntry word) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final id = word.customClassId;
  final custom = id == null ? null : WordClassScope.of(context)[id];
  return appearanceFor(word.category, custom, isDark: isDark);
}

/// Mesma regra de [appearanceOf], sem `BuildContext`.
WordAppearance appearanceFor(
  GrammarCategory category,
  WordClass? custom, {
  required bool isDark,
}) {
  if (custom != null) {
    final color = customClassColor(Color(custom.color), isDark: isDark);
    return WordAppearance(
      label: custom.name.toLowerCase(),
      color: color,
      titleColor: color,
      customClass: custom,
    );
  }
  return WordAppearance(
    label: category.label,
    color: GrammarColors.of(category, isDark: isDark),
    titleColor: GrammarColors.titleOf(category, isDark: isDark),
  );
}

/// Ajusta uma cor livre para ser legível: no tema claro, escurece cores
/// muito claras; no escuro, clareia cores muito escuras.
Color customClassColor(Color base, {required bool isDark}) {
  final hsl = HSLColor.fromColor(base);
  if (isDark) {
    return hsl.lightness < 0.68 ? hsl.withLightness(0.68).toColor() : base;
  }
  return hsl.lightness > 0.42 ? hsl.withLightness(0.42).toColor() : base;
}

/// Classe do método com cor parecida com [color] (para o aviso ao criar
/// uma classe), ou `null` se nenhuma for parecida.
GrammarCategory? similarBuiltInClass(Color color) {
  final c = customClassColor(color, isDark: false);
  GrammarCategory? closest;
  var best = double.infinity;
  for (final category in GrammarCategory.values) {
    final other = GrammarColors.of(category, isDark: false);
    final dr = (c.r - other.r) * 255;
    final dg = (c.g - other.g) * 255;
    final db = (c.b - other.b) * 255;
    final distance = dr * dr + dg * dg + db * db;
    if (distance < best) {
      best = distance;
      closest = category;
    }
  }
  // ~ 55 de distância no espaço RGB (0–255): tons quase iguais.
  return best < 55 * 55 ? closest : null;
}
