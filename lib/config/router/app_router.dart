import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bla_bla/features/auth/presentation/login_screen.dart';
import 'package:bla_bla/features/auth/data/auth_repository_impl.dart';
import 'package:bla_bla/features/home/presentation/main_navigation_screen.dart';
import 'package:bla_bla/features/ride/presentation/publish_ride_screen.dart';
import 'package:bla_bla/features/ride/presentation/search_results_screen.dart';
import 'package:bla_bla/features/ride/presentation/ride_detail_screen.dart';
import 'package:bla_bla/features/ride/domain/ride_model.dart';
import 'package:bla_bla/features/chat/presentation/chat_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges),
    redirect: (context, state) {
      final isLoggedIn = authRepository.currentUser != null;
      final isLoggingIn = state.uri.path == '/login';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }
      
      if (isLoggedIn && isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const MainNavigationScreen(),
      ),
       GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/publish',
        builder: (context, state) => const PublishRideScreen(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return SearchResultsScreen(
            origin: extras['origin'],
            destination: extras['destination'],
            date: extras['date'],
          );
        },
      ),
      GoRoute(
        path: '/ride_detail',
        builder: (context, state) {
          final ride = state.extra as Ride;
          return RideDetailScreen(ride: ride);
        },
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return ChatScreen(
            rideId: extras['rideId'],
            title: extras['title'],
          );
        },
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
