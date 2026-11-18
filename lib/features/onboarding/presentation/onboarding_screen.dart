import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/language/native_language.dart';
import '../../../core/language/native_language_provider.dart';
import '../../../core/language/study_language.dart';
import '../../../core/language/study_language_provider.dart';
import '../../../core/language/ui_language_provider.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/grammar_colors.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../l10n/app_strings.dart';
import '../../home/presentation/home_screen.dart';
import '../../splash/presentation/splash_screen.dart' show kLogoMark;
import '../../vocabulary/providers/vocabulary_provider.dart';
import '../data/onboarding.dart';

/// Primeira abertura: idioma do app, idioma nativo e idioma de estudo. Só
/// no fim o banco é criado, com as fichas iniciais nos idiomas escolhidos.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const int _steps = 3;

  int _step = 0;
  bool _busy = false;

  /// Idioma do app (já vem o do aparelho).
  late String _ui = UiLanguageController.resolve(ref.read(uiLanguageProvider));

  /// Idioma nativo: acompanha o do app até a pessoa escolher outro.
  late String _native = _ui;
  bool _nativeChosen = false;

  late String _study = _firstStudyFor(_native);

  static String _firstStudyFor(String native) => StudyLanguages.all
      .firstWhere((l) => l.code != native, orElse: () => german)
      .code;

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void _pickUi(String code) {
    // O idioma do aparelho fica como "Automático".
    final choice = code == UiLanguageController.deviceLanguage()
        ? UiLanguageController.system
        : code;
    ref.read(uiLanguageProvider.notifier).select(choice);
    setState(() {
      _ui = code;
      if (!_nativeChosen) _pickNativeSilently(code);
    });
  }

  void _pickNativeSilently(String code) {
    _native = code;
    if (_study == code) _study = _firstStudyFor(code);
  }

  void _pickNative(String code) => setState(() {
        _nativeChosen = true;
        _pickNativeSilently(code);
      });

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _next() async {
    if (_step < _steps - 1) {
      setState(() => _step++);
      return;
    }
    setState(() => _busy = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      // O nativo vem antes: as fichas iniciais são criadas nele.
      await ref.read(nativeLanguageProvider.notifier).select(_native);
      await ref
          .read(studyLanguageProvider.notifier)
          .start(ref.read(databaseProvider), _study);
      await Onboarding.markDone();
      ref.read(onboardingPendingProvider.notifier).state = false;
      navigator.pushReplacement(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text(tr.startFailed(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final (String title, String text, List<Widget> options, Widget? extra) =
        switch (_step) {
      0 => (tr.welcomeTitle, tr.welcomeText, _uiOptions(), null),
      1 => (tr.nativeTitle, tr.nativeText, _nativeOptions(), null),
      _ => (
          tr.studyTitle,
          tr.studyText,
          _studyOptions(),
          _FirstDeckPreview(study: _study, native: _native),
        ),
    };

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: p.page,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Header(step: _step, steps: _steps),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                      children: [
                        Text(title, style: AppText.display(p, fontSize: 32)),
                        const SizedBox(height: 10),
                        Text(text, style: AppText.body(p)),
                        const SizedBox(height: 22),
                        for (final o in options) ...[
                          o,
                          const SizedBox(height: 10),
                        ],
                        if (extra != null) ...[
                          const SizedBox(height: 12),
                          extra,
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Row(
                      children: [
                        if (_step > 0) ...[
                          Expanded(
                            child: SoftButton(
                              label: tr.back,
                              onPressed: _busy ? null : _back,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: PrimaryButton(
                            label: _step == _steps - 1
                                ? tr.start
                                : tr.continueAction,
                            chevron: true,
                            onPressed: _busy ? null : _next,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _uiOptions() {
    final device = UiLanguageController.deviceLanguage();
    return [
      for (final s in AppStrings.all.values)
        _LanguageCard(
          badge: s.code.toUpperCase(),
          title: s.selfName,
          subtitle: s.code == device
              ? tr.systemLanguageSubtitle
              : _capitalize(tr.languageName(s.code)),
          selected: s.code == _ui,
          onTap: () => _pickUi(s.code),
        ),
    ];
  }

  List<Widget> _nativeOptions() => [
        for (final l in NativeLanguages.all)
          _LanguageCard(
            badge: l.code.toUpperCase(),
            title: _capitalize(tr.languageName(l.code)),
            // Exemplo do que muda: "o cachorro · O cachorro dorme…".
            subtitle: '${l.translationHint} · ${l.exampleTranslationHint}',
            selected: l.code == _native,
            onTap: () => _pickNative(l.code),
          ),
      ];

  List<Widget> _studyOptions() => [
        for (final l in StudyLanguages.all)
          _LanguageCard(
            badge: l.code.toUpperCase(),
            title: _capitalize(tr.languageName(l.code)),
            subtitle: l.code == _native
                ? tr.isYourNativeLanguage
                : [l.nameNative, ...l.articles.values].join(' · '),
            selected: l.code == _study,
            onTap: l.code == _native
                ? null
                : () => setState(() => _study = l.code),
          ),
      ];
}

/// Logo, "MEIN NOTIZBUCH", "1 / 3" e a barra de progresso.
class _Header extends StatelessWidget {
  const _Header({required this.step, required this.steps});

  final int step;
  final int steps;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Image.asset(
                kLogoMark,
                height: 26,
                color: p.text600,
                colorBlendMode: BlendMode.srcIn,
                excludeFromSemantics: true,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('MEIN NOTIZBUCH', style: AppText.section(p)),
              ),
              Text(tr.onboardingStep(step + 1), style: AppText.meta(p)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < steps; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= step ? p.text900 : p.track,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Opção de idioma: sigla, nome, detalhe e marcação. Sem [onTap], aparece
/// apagada (indisponível).
class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String badge;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final radius = BorderRadius.circular(16);
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: Semantics(
        button: true,
        selected: selected,
        enabled: onTap != null,
        child: Material(
          color: p.card,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: selected ? p.text900 : p.cardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? p.ink : p.softButton,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontFamily: AppTheme.sansFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: selected ? p.onInk : p.text600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppText.item(p).copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.meta(p),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _Radio(selected: selected),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? p.ink : null,
        border: selected ? null : Border.all(color: p.text400, width: 1.5),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: 15, color: p.onInk)
          : null,
    );
  }
}

/// As três primeiras fichas iniciais, já nos idiomas escolhidos.
class _FirstDeckPreview extends StatelessWidget {
  const _FirstDeckPreview({required this.study, required this.native});

  final String study;
  final String native;

  static const int _shown = 3;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final seeds = AppDatabase.seedPreview(study, native);
    final rest = seeds.length - _shown;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr.yourFirstDeck, style: AppText.caption(p)),
          const SizedBox(height: 6),
          for (final w in seeds.take(_shown))
            Container(
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: p.divider)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      w.germanWord.value,
                      style: AppTheme.serif(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: GrammarColors.titleOf(
                          w.category.value,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    w.portugueseTranslation.value,
                    style: AppText.meta(p).copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
          if (rest > 0) ...[
            const SizedBox(height: 8),
            Text(
              tr.moreSampleCards(rest, tr.deckGeneral),
              style: AppText.meta(p),
            ),
          ],
        ],
      ),
    );
  }
}
