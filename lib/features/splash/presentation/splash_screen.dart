import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../vocabulary/presentation/screens/flashcards_screen.dart';

/// Caminho da logo recortada, com fundo transparente.
const String kLogoMark = 'assets/logo/logo_mark.png';

/// Abertura do app: a logo aparece (fade + leve subida), o nome surge logo
/// depois e, em seguida, a tela de fichas entra com um fade.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Tempo total na tela antes de abrir as fichas.
  static const Duration duration = Duration(milliseconds: 1800);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final Animation<double> _logo = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.7, curve: Curves.easeOutCubic),
  );

  late final Animation<double> _title = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.4, 1, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    Future<void>.delayed(SplashScreen.duration, _openFlashcards);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decodifica a logo antes do primeiro quadro para não "piscar".
    precacheImage(const AssetImage(kLogoMark), context);
  }

  void _openFlashcards() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => const FlashcardsScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return Scaffold(
      backgroundColor: p.page,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: _logo,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(_logo),
                child: Image.asset(
                  kLogoMark,
                  width: 180,
                  // Pinta a logo com a cor do texto: funciona no modo escuro.
                  color: p.text900,
                  colorBlendMode: BlendMode.srcIn,
                  semanticLabel: 'Mein Notizbuch',
                ),
              ),
            ),
            const SizedBox(height: 28),
            FadeTransition(
              opacity: _title,
              child: Text(
                'MEIN NOTIZBUCH',
                style: TextStyle(
                  fontSize: 13,
                  height: 16 / 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: p.text600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
