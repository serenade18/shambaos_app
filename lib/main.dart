import 'package:flutter/material.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/home_screen.dart'; // Import your home screen
import 'screens/profile/profile_screen.dart'; // Import the profile screen
import 'screens/tulip/tulip_screen.dart';
import 'screens/fields/fields_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'theme_notifier.dart';
import './services/app_theme.dart';
import './services/api_service.dart';

final ThemeNotifier themeNotifier = ThemeNotifier();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
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

          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),

          // Define named routes here
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/home': (context) => const HomeScreen(),
            '/chat': (context) => const TulipAiScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/fields': (context) => const FieldsScreen(),
            '/activity': (context) => const DashboardScreen(),
          },
        );
      },
    );
  }
}