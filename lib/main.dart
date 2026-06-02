import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'blocs/auth/auth_cubit.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_screen.dart';
import 'screens/add_pet_screen.dart';
import 'screens/health_screen.dart';
import 'screens/add_health_screen.dart';
import 'screens/weight_screen.dart';
import 'screens/map_screen.dart';
import 'screens/pet_detail_screen.dart';
import 'screens/edit_pet_screen.dart';
import 'screens/heat_cycle_screen.dart';

final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

Future<void> loadThemePreference() async {
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('dark_mode');
  if (isDark == null) {
    themeNotifier.value = ThemeMode.system;
  } else {
    themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}

Future<void> saveThemePreference(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  if (mode == ThemeMode.system) {
    await prefs.remove('dark_mode');
  } else {
    await prefs.setBool('dark_mode', mode == ThemeMode.dark);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) AndroidYandexMap.useAndroidViewSurface = false;
  await initializeDateFormatting('ru_RU', null);
  await loadThemePreference();
  await NotificationService.init();
  // Pre-warm DNS so Cloudinary images load on first launch without delay
  InternetAddress.lookup('res.cloudinary.com').catchError((_) => <InternetAddress>[]);
  runApp(
    BlocProvider(
      create: (_) => AuthCubit(),
      child: const PawCareApp(),
    ),
  );
}

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash',     builder: (c, s) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
    GoRoute(path: '/login',      builder: (c, s) => const LoginScreen()),
    GoRoute(path: '/register',   builder: (c, s) => const RegisterScreen()),
    GoRoute(path: '/home',       builder: (c, s) => const MainScreen()),
    GoRoute(path: '/add-pet',    builder: (c, s) => const AddPetScreen()),
    GoRoute(path: '/map',        builder: (c, s) => const MapScreen()),
    GoRoute(
      path: '/health/:petId/:petName',
      builder: (c, s) => HealthScreen(
        petId: s.pathParameters['petId']!,
        petName: s.pathParameters['petName']!,
      ),
    ),
    GoRoute(
      path: '/add-health/:petId',
      builder: (c, s) => AddHealthScreen(petId: s.pathParameters['petId']!),
    ),
    GoRoute(
      path: '/weight/:petId/:petName',
      builder: (c, s) => WeightScreen(
        petId: s.pathParameters['petId']!,
        petName: s.pathParameters['petName']!,
      ),
    ),
    GoRoute(
      path: '/pet-detail',
      builder: (c, s) => PetDetailScreen(
        pet: s.extra as Map<String, dynamic>,
      ),
    ),
    GoRoute(
      path: '/edit-pet',
      builder: (c, s) => EditPetScreen(
        pet: s.extra as Map<String, dynamic>,
      ),
    ),
    GoRoute(
      path: '/heat-cycles/:petId/:petName',
      builder: (c, s) => HeatCycleScreen(
        petId: s.pathParameters['petId']!,
        petName: s.pathParameters['petName']!,
      ),
    ),
  ],
);

class PawCareApp extends StatelessWidget {
  const PawCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) => MaterialApp.router(
        title: 'PawCare',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2C6E49),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2C6E49),
            brightness: Brightness.dark,
          ).copyWith(
            surface: const Color(0xFF1E1E1E),
            onSurface: const Color(0xFFEEEEEE),
            onSurfaceVariant: const Color(0xFFAAAAAA),
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
          scaffoldBackgroundColor: const Color(0xFF121212),
          cardColor: const Color(0xFF1E1E1E),
        ),
        locale: const Locale('ru', 'RU'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ru', 'RU')],
        themeMode: mode,
        routerConfig: _router,
      ),
    );
  }
}
