import 'package:flutter/material.dart';
import 'pages/onboarding/splash_screen.dart';
import 'theme_notifier.dart';
import './services/app_colors.dart';

final ThemeNotifier themeNotifier = ThemeNotifier();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeNotifier,
      builder: (context, _) {
        return MaterialApp(
          title: 'Shamba OS',
          debugShowCheckedModeBanner: false,
          themeMode: themeNotifier.mode,

          // ── Light ──────────────────────────────────────
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF109641),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: AppColors.light.scaffoldBackground,
            cardColor: AppColors.light.cardBackground,
            dividerColor: AppColors.light.divider,
            useMaterial3: true,
            extensions: const [AppColors.light],
          ),

          // ── Dark ───────────────────────────────────────
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF109641),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: AppColors.dark.scaffoldBackground,
            cardColor: AppColors.dark.cardBackground,
            dividerColor: AppColors.dark.divider,
            useMaterial3: true,
            extensions: const [AppColors.dark],
          ),

          home: const SplashScreen(),
        );
      },
    );
  }
}