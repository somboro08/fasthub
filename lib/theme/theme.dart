import 'package:flutter/material.dart';

extension ColorExtension on Color {
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}

class FastHubTheme {
  static const Color primaryColor = Color(0xFF3b3b40);
  static const Color primaryDark = Color(0xFF1E1E1E);
  static const Color primaryLight = Color(0xFF4a4a4f);
  static const Color accentColor = Color(0xFFff69b4);
  static const Color backgroundColor = Color(0xFF1E1E1E);
  static const Color surfaceColor = Color(0xFF2d2d30);
  static const Color textColor = Colors.white;
  static const Color textSecondary = Colors.grey;
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      primaryColor: primaryColor,
      primaryColorDark: primaryDark,
      primaryColorLight: primaryLight,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 4,
        foregroundColor: textColor,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
        ),
        centerTitle: true,
      ),
      scaffoldBackgroundColor: backgroundColor,
      dialogBackgroundColor: surfaceColor,
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryLight,
        unselectedItemColor: textSecondary,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  static TextStyle get appTitleStyle {
    return const TextStyle(
      color: Colors.white,
      fontSize: 28,
      fontWeight: FontWeight.w900,
      fontFamily: 'Inter',
      letterSpacing: 1.5,
    );
  }

  static Gradient get primaryGradient {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color.fromARGB(255, 74, 73, 75), Color.fromARGB(255, 15, 10, 23)],
    );
  }

  static Color get dividerColor => const Color(0xFFEF4444);
   
}
