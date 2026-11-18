import 'package:flutter_tts/flutter_tts.dart';

import '../language/study_language.dart';

/// Pronúncia no idioma de estudo, com o mecanismo de voz do próprio
/// aparelho.
///
/// Funciona offline quando a voz do idioma está instalada (ex.: "Deutsch
/// (Deutschland)"). No Android isso costuma exigir baixar o pacote de voz
/// nas configurações de texto para fala; sem ele, [speak] devolve `false`.
class TtsService {
  TtsService._();

  static final FlutterTts _tts = FlutterTts();
  static Future<bool>? _ready;
  static String? _locale;

  /// Prepara a voz do idioma de estudo atual (refaz se o idioma mudar).
  static Future<bool> init() {
    final locale = StudyLanguages.active.ttsLocale;
    if (_locale != locale) {
      _locale = locale;
      _ready = null;
    }
    return _ready ??= _initialize(locale);
  }

  static Future<bool> _initialize(String locale) async {
    try {
      final available = await _tts.isLanguageAvailable(locale);
      if (available != true && available != 1) {
        _ready = null; // tenta de novo depois (a voz pode ser instalada)
        return false;
      }
      await _tts.setLanguage(locale);
      await _tts.setSpeechRate(0.45); // um pouco mais lento, para quem aprende
      await _tts.setPitch(1.0);
      return true;
    } catch (_) {
      _ready = null;
      return false;
    }
  }

  /// Fala [text] no idioma de estudo. Devolve `false` se não houver voz.
  static Future<bool> speak(String text) async {
    if (!await init()) return false;
    final clean = text.replaceAll(RegExp(r'[\[\]]'), '').trim();
    if (clean.isEmpty) return true;
    await _tts.stop(); // evita sobrepor dois toques seguidos
    await _tts.speak(clean);
    return true;
  }

  static Future<void> stop() => _tts.stop();
}
