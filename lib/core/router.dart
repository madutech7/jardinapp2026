import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/garden/garden_screen.dart';
import '../features/plant_detail/plant_detail_screen.dart';
import '../features/plant_detail/add_plant_screen.dart';
import '../features/plant_detail/sensor_readings_screen.dart';
import '../features/plant_detail/notes_screen.dart';
import '../features/reminders/reminders_screen.dart';
import '../features/species/species_screen.dart';
import '../features/species/species_detail_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../shell/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthNotifier(ref);
  return GoRouter(
    initialLocation: '/garden',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final isLoading = authState.isLoading;
      if (isLoading) return null;

      final isLoggedIn = authState.value != null;
      final isAuthRoute =
          state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (!isLoggedIn && !isAuthRoute) return '/login';
      if (isLoggedIn && isAuthRoute) return '/garden';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/garden',
            name: 'garden',
            builder: (context, state) => const GardenScreen(),
          ),
          GoRoute(
            path: '/reminders',
            name: 'reminders',
            builder: (context, state) => const RemindersScreen(),
          ),
          GoRoute(
            path: '/species',
            name: 'species',
            builder: (context, state) => const SpeciesScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'edit-profile',
                builder: (context, state) => const EditProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/plant/add',
        name: 'add-plant',
        builder: (context, state) => const AddPlantScreen(),
      ),
      GoRoute(
        path: '/plant/:id',
        name: 'plant-detail',
        builder: (context, state) =>
            PlantDetailScreen(plantId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plant/:id/readings',
        name: 'sensor-readings',
        builder: (context, state) =>
            SensorReadingsScreen(plantId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/plant/:id/notes',
        name: 'plant-notes',
        builder: (context, state) =>
            PlantNotesScreen(plantId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/species/:id',
        name: 'species-detail',
        builder: (context, state) =>
            SpeciesDetailScreen(speciesId: state.pathParameters['id']!),
      ),
    ],
  );
});

// Notifieur d'authentification pour GoRouter
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(Ref ref) {
    ref.listen(authStateProvider, (previous, next) => notifyListeners());
  }
}

// Flux de rafraîchissement pour GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
