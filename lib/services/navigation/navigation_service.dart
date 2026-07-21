// lib/services/navigation/navigation_service.dart
import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void goBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      // If can't pop, navigate to home
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  static void navigateTo(String routeName, {Object? arguments}) {
    navigatorKey.currentState?.pushNamed(routeName, arguments: arguments);
  }

  static void navigateAndReplace(String routeName, {Object? arguments}) {
    navigatorKey.currentState?.pushReplacementNamed(routeName, arguments: arguments);
  }

  static void navigateAndClearStack(String routeName, {Object? arguments}) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName, 
      (route) => false, 
      arguments: arguments,
    );
  }


  static bool canGoBack() {
    return navigatorKey.currentState?.canPop() ?? false;
  }

  // ============ SCREEN NAVIGATION ============

  static void navigateToHome(BuildContext context) {
    Navigator.pushNamed(context, '/home');
  }

  static void navigateToLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  static void navigateToWorkspace(BuildContext context, {String? workspaceId}) {
    Navigator.pushNamed(context, '/workspace');
  }

  // ✅ ADD THIS METHOD
  static void navigateToAI(BuildContext context, {String? workspaceId}) {
    Navigator.pushNamed(context, '/ai', arguments: workspaceId);
  }

  static void navigateToProfile(BuildContext context) {
    Navigator.pushNamed(context, '/profile');
  }

  static void navigateToCalendar(BuildContext context) {
    Navigator.pushNamed(context, '/calendar');
  }

  static void navigateToHelp(BuildContext context) {
    Navigator.pushNamed(context, '/help');
  }

  static void navigateToPrivacy(BuildContext context) {
    Navigator.pushNamed(context, '/privacy');
  }

  static void navigateToNotifications(BuildContext context) {
    Navigator.pushNamed(context, '/notifications');
  }

  static void navigateToSmartNote(BuildContext context) {
    Navigator.pushNamed(context, '/smart-note');
  }
}