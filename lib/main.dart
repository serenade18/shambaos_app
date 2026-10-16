import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/onboarding/splash_screen.dart';
import 'screens/home_screen.dart'; // Import your home screen
import 'screens/profile/profile_screen.dart'; // Import the profile screen
import 'screens/tulip/tulip_chat_screen.dart';
import 'screens/fields/fields_screen.dart';
import 'screens/fields/field_scan_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'theme_notifier.dart';
import './services/app_theme.dart';
import './services/api_service.dart';
import 'l10n/language_scope.dart';

final ThemeNotifier themeNotifier = ThemeNotifier();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.init();
  // Dates and numbers formatted in the chosen language (day and month names).
  await initializeDateFormatting();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return LanguageScope(
      builder: (context) => ListenableBuilder(
        listenable: themeNotifier,
        builder: (context, _) {
          return MaterialApp(
            title: 'Shamba OS',
            debugShowCheckedModeBanner: false,
            themeMode: themeNotifier.mode,

            // Flutter's own words (date pickers, dialogs) follow the chosen language too.
            locale: Locale(ApiService.locale),
            supportedLocales: const [Locale('en'), Locale('sw'), Locale('fr')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,

            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),

            // Define named routes here
            initialRoute: '/',
            routes: {
              '/': (context) => const SplashScreen(),
              '/home': (context) => const HomeScreen(),
              '/chat': (context) => const TulipChatScreen(), // straight into the chat, as the design
              '/profile': (context) => const ProfileScreen(),
              '/fields': (context) => const FieldsScreen(),
              '/ai': (context) => const FieldScanScreen(),
              '/activity': (context) => const DashboardScreen(),
            },
          );
        },
      ),
    );
  }
}
