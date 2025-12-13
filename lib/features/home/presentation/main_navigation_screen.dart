import 'package:flutter/material.dart';
import 'package:bla_bla/features/home/presentation/home_screen.dart';
import 'package:bla_bla/features/map/presentation/map_screen.dart';
import 'package:bla_bla/features/home/presentation/activity_screen.dart';
import 'package:bla_bla/features/home/presentation/profile_screen.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bla_bla/features/auth/data/auth_repository_impl.dart';
import 'package:bla_bla/features/admin/presentation/admin_dashboard_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    final userRole = user?.userMetadata?['role'] ?? 'customer';

    // Define screens based on role
    final List<Widget> screens = [
      const HomeScreen(),
      const MapScreen(),
      if (userRole == 'admin') const AdminDashboardScreen() else const ActivityScreen(),
      const ProfileScreen(),
    ];
    
    // Define tabs based on role
    final List<NavigationDestination> destinations = [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        const NavigationDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map),
          label: 'Map',
        ),
        if (userRole == 'admin')
           const NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          )
        else
           const NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Activity',
          ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex < screens.length ? _currentIndex : 0, // Safety check
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex < destinations.length ? _currentIndex : 0,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: destinations,
      ),
    );
  }
}
