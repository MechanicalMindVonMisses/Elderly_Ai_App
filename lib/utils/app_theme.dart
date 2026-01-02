import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF007AFF);
  static const Color background = Color(0xFFF2F2F7);
  static const Color cardBg = Colors.white;
  static const Color text = Colors.black;
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color error = Color(0xFFFF3B30);
  static const Color success = Color(0xFF34C759);
}

class AppStrings {
  static const String appName = 'Can Dostum';
  static const String homeTitle = 'Merhaba';
  static const String medsTitle = 'İlaç Takibi';
  static const String foodTitle = 'Yemek Takibi';
  static const String waterTitle = 'Su Takibi';
  static const String settingsTitle = 'Ayarlar';
  
  // Chat
  static const String listening = 'Sizi dinliyorum...';
  static const String processing = 'Anlıyorum...';
  static const String tapToSpeak = 'Konuşmak için dokun';
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        background: AppColors.background,
      ),
      
      // Typography - Optimized for Elderly
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.text),
        displayMedium: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.text),
        titleLarge: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.text),
        titleMedium: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.text),
        bodyLarge: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.normal, color: AppColors.text),
        bodyMedium: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.text),
      ),
      
      // Card Theme
      cardTheme: CardTheme(
        color: AppColors.cardBg,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      
      // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)), // Pill shape
        ),
      ),
      
      // Input Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(20),
        labelStyle: TextStyle(fontSize: 18, color: AppColors.textSecondary),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: const Color(0xFF1C1C1E), // iOS Dark Gray
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        background: const Color(0xFF1C1C1E),
      ),
      
      // Typography
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        displayMedium: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        titleLarge: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
        titleMedium: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white),
        bodyLarge: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.normal, color: Colors.white70),
        bodyMedium: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.white70),
      ),
      
      // Card Theme
      cardTheme: CardTheme(
        color: const Color(0xFF2C2C2E),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),
      
       // Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        ),
      ),

      // Input Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(20),
        labelStyle: TextStyle(fontSize: 18, color: Colors.white54),
      ),
      
      // Switch Setup
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return Colors.white;
          return null;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return AppColors.primary;
          return null;
        }),
      ),
    );
  }
}
