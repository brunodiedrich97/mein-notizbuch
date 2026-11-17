import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/app_navigator.dart';
import 'core/theme/app_theme.dart';
import 'features/reminders/data/reminder_service.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'features/vocabulary/presentation/screens/word_detail_screen.dart';

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
      home: const SplashScreen(),
    );
  }
}
