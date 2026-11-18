import 'package:flutter/material.dart';

import '../../../../core/language/study_language.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_strings.dart';

/// Fala [text] no idioma de estudo e avisa se não houver voz instalada.
Future<void> speakWithFeedback(BuildContext context, String text) async {
  final ok = await TtsService.speak(text);
  if (ok || !context.mounted) return;
  final language = StudyLanguages.active;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          tr.noVoiceInstalled(
            tr.languageName(language.code),
            language.nameNative,
          ),
        ),
      ),
    );
}

/// Caixa cinza de pronúncia: botão de som, IPA em mono e a aproximação.
class PronunciationBox extends StatelessWidget {
  const PronunciationBox({
    super.key,
    required this.speakText,
    this.ipa,
    this.approximation,
  });

  final String speakText;
  final String? ipa;
  final String? approximation;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final ipa = this.ipa;
    final approximation = this.approximation;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.pronBox,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: tr.listenPronunciation,
            child: InkResponse(
              onTap: () => speakWithFeedback(context, speakText),
              radius: 20,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: SvgPathIcon(AppIcons.volumeUp, size: 20, color: p.text500),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text.rich(
                TextSpan(
                  children: [
                    if (ipa != null)
                      TextSpan(
                        text: ipa,
                        style: AppTheme.mono(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: p.text800,
                        ),
                      ),
                    if (ipa != null && approximation != null)
                      TextSpan(
                        text: '  ·  ',
                        style: TextStyle(color: p.text400),
                      ),
                    if (approximation != null)
                      TextSpan(
                        text: approximation,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: p.text900,
                        ),
                      ),
                    if (ipa == null && approximation == null)
                      TextSpan(
                        text: tr.listenPronunciation,
                        style: TextStyle(color: p.text500),
                      ),
                  ],
                ),
                style: TextStyle(fontSize: 16, height: 1.375, color: p.text800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
