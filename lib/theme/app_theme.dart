import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors based on Kreativ Institute inspiration
  static const Color backgroundDark = Color(0xFF0D0D0D); // Deep dark background
  static const Color surfaceDark = Color(0xFF1A1A1A); // Slightly lighter for cards
  static const Color neonGreen = Color(0xFF00FF41); // KIO inspired Neon Green (Matrix style)
  static const Color textLight = Color(0xFFEEEEEE);
  static const Color textMuted = Color(0xFF9E9E9E);
  
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      primaryColor: neonGreen,
      colorScheme: const ColorScheme.dark(
        primary: neonGreen,
        secondary: neonGreen,
        surface: surfaceDark,
      ),
      fontFamily: 'Inter', // We can switch to a specific font later if needed
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: neonGreen),
        titleTextStyle: TextStyle(
          color: textLight,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: neonGreen,
        foregroundColor: backgroundDark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonGreen,
          foregroundColor: backgroundDark,
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: neonGreen,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
