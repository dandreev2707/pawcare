import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_screen.dart';
import 'screens/add_pet_screen.dart';
import 'screens/health_screen.dart';
import 'screens/add_health_screen.dart';
import 'screens/weight_screen.dart';
import 'screens/map_screen.dart';
import 'screens/pet_detail_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PawCareApp());
}

final _router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
    GoRoute(path: '/register', builder: (c, s) => const RegisterScreen()),
    GoRoute(path: '/home', builder: (c, s) => const MainScreen()),
    GoRoute(path: '/add-pet', builder: (c, s) => const AddPetScreen()),
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
    GoRoute(path: '/map', builder: (c, s) => const MapScreen()),
    GoRoute(
  path: '/pet-detail',
  builder: (context, state) => PetDetailScreen(
    pet: state.extra as Map<String, dynamic>,
  ),
),
  ],
);

class PawCareApp extends StatelessWidget {
  const PawCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PawCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2C6E49),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      routerConfig: _router,
    );
  }
  
}
