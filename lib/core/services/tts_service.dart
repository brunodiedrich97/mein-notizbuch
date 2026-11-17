import 'package:flutter_tts/flutter_tts.dart';

/// Pronúncia em alemão usando o mecanismo de voz do próprio aparelho.
///
/// Funciona offline quando a voz "Deutsch (Deutschland)" está instalada.
/// No Android isso costuma exigir baixar o pacote de voz nas configurações
/// de texto para fala; sem ele, [speakGerman] devolve `false`.
class TtsService {
  TtsService._();

  static final FlutterTts _tts = FlutterTts();
  static Future<bool>? _ready;

  static Future<bool> init() => _ready ??= _initialize();

  static Future<bool> _initialize() async {
    try {
      final available = await _tts.isLanguageAvailable('de-DE');
      if (available != true && available != 1) {
        _ready = null; // tenta de novo depois (a voz pode ser instalada)
        return false;
      }
      await _tts.setLanguage('de-DE');
      await _tts.setSpeechRate(0.45); // um pouco mais lento, para quem aprende
      await _tts.setPitch(1.0);
      return true;
    } catch (_) {
      _ready = null;
      return false;
    }
  }

  /// Fala [text] em alemão. Devolve `false` se não houver voz alemã.
  static Future<bool> speakGerman(String text) async {
    if (!await init()) return false;
    final clean = text.replaceAll(RegExp(r'[\[\]]'), '').trim();
    if (clean.isEmpty) return true;
    await _tts.stop(); // evita sobrepor dois toques seguidos
    await _tts.speak(clean);
    return true;
  }

  static Future<void> stop() => _tts.stop();
}
