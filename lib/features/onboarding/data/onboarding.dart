import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/database/app_database.dart';

/// A primeira abertura está em andamento? Enquanto estiver, nada pode abrir
/// o banco (ele seria criado antes da escolha do idioma nativo).
final onboardingPendingProvider = StateProvider<bool>((_) => Onboarding.pending);

/// Primeira abertura do app: escolha dos idiomas antes de criar o banco.
class Onboarding {
  Onboarding._();

  static const _key = 'onboarding.done';

  /// A primeira abertura ainda precisa ser mostrada? Definido por [check].
  static bool pending = false;

  /// Vê se a primeira abertura falta. Quem já tinha o banco (versões
  /// anteriores a ela) é marcado como concluído e segue direto.
  static Future<bool> check() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_key) ?? false) return pending = false;
    if (await AppDatabase.fileExists()) {
      await prefs.setBool(_key, true);
      return pending = false;
    }
    return pending = true;
  }

  static Future<void> markDone() async {
    pending = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
