import 'package:flutter/material.dart';

/// Cixio brand color palette
/// Primary Blue: #1259FB  |  Deep Navy: #1236AE  |  Dark: #0B1E6B
class CixioColors {
  CixioColors._();

  static const Color blue   = Color(0xFF1259FB); // primary electric blue
  static const Color navy   = Color(0xFF1236AE); // deep navy
  static const Color dark   = Color(0xFF0B1E6B); // darkest navy (headers/sidebar)
  static const Color light  = Color(0xFFEEF3FF); // light blue tint (backgrounds)
  static const Color bg     = Color(0xFFF4F7FF); // page background
  static const Color hover  = Color(0xFF0E4DE0); // on hover / pressed
  static const Color muted  = Color(0xFF6B88D4); // secondary text / icon
  static const Color white  = Color(0xFFFFFFFF);
}

class CixioTheme {
  CixioTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary:   CixioColors.blue,
          onPrimary: CixioColors.white,
          primaryContainer: CixioColors.light,
          onPrimaryContainer: CixioColors.dark,
          secondary: CixioColors.navy,
          onSecondary: CixioColors.white,
          secondaryContainer: CixioColors.light,
          onSecondaryContainer: CixioColors.dark,
          surface:   CixioColors.white,
          onSurface: Color(0xFF111827),
          error:     Color(0xFFDC2626),
          onError:   CixioColors.white,
          outline:   Color(0xFFD1D5DB),
          surfaceContainerHighest: CixioColors.bg,
        ),
        scaffoldBackgroundColor: CixioColors.bg,

        // AppBar — dark navy brand bar
        appBarTheme: const AppBarTheme(
          backgroundColor: CixioColors.dark,
          foregroundColor: CixioColors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: CixioColors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: 'Inter',
          ),
          iconTheme: IconThemeData(color: CixioColors.white),
          centerTitle: false,
        ),

        // Bottom nav bar
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: CixioColors.white,
          indicatorColor: CixioColors.light,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: CixioColors.blue, size: 24);
            }
            return const IconThemeData(color: CixioColors.muted, size: 24);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: CixioColors.blue,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              );
            }
            return const TextStyle(color: CixioColors.muted, fontSize: 11);
          }),
          elevation: 4,
          shadowColor: Colors.black12,
        ),

        // Filled buttons
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: CixioColors.blue,
            foregroundColor: CixioColors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),

        // Outlined buttons
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: CixioColors.blue,
            minimumSize: const Size.fromHeight(48),
            side: const BorderSide(color: CixioColors.blue),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),

        // Text buttons
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: CixioColors.blue),
        ),

        // Input fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: CixioColors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: CixioColors.blue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDC2626)),
          ),
          labelStyle: const TextStyle(color: CixioColors.muted),
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        ),

        // Cards
        cardTheme: CardThemeData(
          color: CixioColors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: CixioColors.light),
          ),
          margin: EdgeInsets.zero,
        ),

        // Checkbox
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? CixioColors.blue : null),
        ),

        // Switch
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? CixioColors.white : null),
          trackColor: WidgetStateProperty.resolveWith((s) =>
              s.contains(WidgetState.selected) ? CixioColors.blue : null),
        ),

        // FAB
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: CixioColors.blue,
          foregroundColor: CixioColors.white,
          elevation: 3,
          shape: StadiumBorder(),
        ),

        // Chip
        chipTheme: ChipThemeData(
          backgroundColor: CixioColors.light,
          selectedColor: CixioColors.blue,
          labelStyle: const TextStyle(fontSize: 12),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),

        // Snackbar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: CixioColors.dark,
          contentTextStyle: const TextStyle(color: CixioColors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          behavior: SnackBarBehavior.floating,
        ),

        // Divider
        dividerTheme: const DividerThemeData(color: CixioColors.light, space: 1),
      );
}
