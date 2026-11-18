import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/app_navigator.dart';
import 'core/theme/app_theme.dart';
import 'features/reminders/data/reminder_service.dart';
import 'features/settings/providers/text_size_provider.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/vocabulary/presentation/screens/word_detail_screen.dart';
import 'features/word_classes/presentation/word_appearance.dart';
import 'features/word_classes/providers/word_class_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tocar na notificação da palavra do dia abre a ficha dela.
  final reminders = ReminderService.instance;
  reminders.onOpenWord = (wordId) => appNavigatorKey.currentState?.push(
        MaterialPageRoute<void>(
          builder: (_) => WordDetailScreen(wordId: wordId),
        ),
      );
  await reminders.init();

  runApp(const ProviderScope(child: DeutschNotizbuchApp()));
}

class DeutschNotizbuchApp extends StatelessWidget {
  const DeutschNotizbuchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Mein Notizbuch',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR'), Locale('pt')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Consumer(
        builder: (context, ref, _) {
          // Tamanho do texto escolhido em Ajustes, somado ao do aparelho.
          // O aumento do app vai até 2x no total, para as telas não
          // quebrarem; a escala do próprio aparelho nunca é reduzida.
          final media = MediaQuery.of(context);
          final level = ref.watch(textSizeProvider);
          final system = media.textScaler.scale(16) / 16;
          final scale = math.min(system * level.factor, math.max(2.0, system));
          return MediaQuery(
            data: media.copyWith(textScaler: TextScaler.linear(scale)),
            // Classes criadas pelo usuário, disponíveis em todas as telas.
            child: WordClassScope(
              classes: ref.watch(wordClassMapProvider),
              child: child!,
            ),
          );
        },
      ),
      home: const SplashScreen(),
    );
  }
}
