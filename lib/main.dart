import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'utils/app_theme.dart';
import 'services/storage_service.dart';
import 'services/ai_service.dart';
import 'screens/home_screen.dart';
import 'screens/food_screen.dart';
import 'screens/meds_screen.dart';
import 'screens/water_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/history_screen.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';

import 'package:intl/date_symbol_data_local.dart'; // Import this

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Date Formatting
  await initializeDateFormatting('tr_TR', null);
  
  // Initialize Notifications FIRST (Sets up Timezone)
  await NotificationService().init(navigatorKey);
  
  // Initialize Storage (Uses Timezone for scheduling)
  final storage = StorageService();
  await storage.init();
  
  // Initialize Theme
  final themeProvider = ThemeProvider();
  await themeProvider.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: storage),
        ChangeNotifierProvider.value(value: themeProvider),
        Provider(create: (_) => AIService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Can Dostum',
          navigatorKey: navigatorKey, // Inject Key
          debugShowCheckedModeBanner: false,
          
          // Localization Setup
          supportedLocales: const [Locale('tr')],
          locale: const Locale('tr'),
          localizationsDelegates: const [
             GlobalMaterialLocalizations.delegate,
             GlobalWidgetsLocalizations.delegate,
             GlobalCupertinoLocalizations.delegate,
          ],

          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/',
          routes: {
            '/': (context) => const HomeScreen(),
            '/food': (context) => const FoodScreen(),
            '/meds': (context) => const MedsScreen(),
            '/water': (context) => const WaterScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/history': (context) => const HistoryScreen(),
          },
          builder: (context, child) {
            final scale = themeProvider.isLargeFont ? 1.2 : 1.0;
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: scale), // Using textScaleFactor for compatibility
              child: child!,
            );
          },
        );
      },
    );
  }
}
