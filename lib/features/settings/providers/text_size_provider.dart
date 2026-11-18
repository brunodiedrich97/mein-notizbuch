import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tamanho do texto do app, além do ajuste de acessibilidade do aparelho.
enum TextSizeLevel {
  normal('Normal', 1.0),
  large('Grande', 1.15),
  extraLarge('Muito grande', 1.3);

  const TextSizeLevel(this.label, this.factor);
  final String label;

  /// Multiplica a escala de texto do sistema.
  final double factor;
}

final textSizeProvider =
    NotifierProvider<TextSizeController, TextSizeLevel>(TextSizeController.new);

class TextSizeController extends Notifier<TextSizeLevel> {
  static const _key = 'display.textSize';

  @override
  TextSizeLevel build() {
    _load();
    return TextSizeLevel.normal;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_key);
    state = TextSizeLevel.values.firstWhere(
      (l) => l.name == name,
      orElse: () => TextSizeLevel.normal,
    );
  }

  Future<void> set(TextSizeLevel level) async {
    state = level;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, level.name);
  }
}
