import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/cixio_theme.dart';

/// Shell widget that provides a single persistent AppBar + bottom navigation bar.
/// Tab screens must NOT have their own Scaffold/AppBar — they are just content widgets.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  static const _tabs = [
    _Tab(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Chat'),
    _Tab(icon: Icons.folder_outlined, activeIcon: Icons.folder, label: 'Documents'),
    _Tab(icon: Icons.check_circle_outline, activeIcon: Icons.check_circle, label: 'Todos'),
    _Tab(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final tabIndex = navigationShell.currentIndex;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: CixioColors.dark,
        leading: Padding(
          padding: const EdgeInsets.all(10),
          child: Image.asset(
            'assets/images/cixio-icon.png',
            fit: BoxFit.contain,
          ),
        ),
        title: Text(
          _tabs[tabIndex].label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class _Tab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _Tab({required this.icon, required this.activeIcon, required this.label});
}

