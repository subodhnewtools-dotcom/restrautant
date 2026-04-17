import 'package:flutter/material.dart';

/// App Theme Configuration
/// Material 3 theme with custom color palette

class AppColors {
  // Primary brand colors
  static const Color kPrimaryColor = Color(0xFFE8630A);   // Warm Orange
  static const Color kSecondaryColor = Color(0xFF1E1E1E); // Charcoal
  static const Color kBackgroundColor = Color(0xFFFFF8F2); // Soft Cream
  static const Color kSurfaceColor = Color(0xFFFFFFFF);
  
  // Status colors
  static const Color kSuccessColor = Color(0xFF43A047);   // Veg Green
  static const Color kDangerColor = Color(0xFFE53935);    // Non-Veg Red
  static const Color kWarningColor = Color(0xFFFFA000);
  static const Color kInfoColor = Color(0xFF2196F3);
  
  // Text colors
  static const Color kTextPrimary = Color(0xFF212121);
  static const Color kTextSecondary = Color(0xFF757575);
  static const Color kTextDisabled = Color(0xFFBDBDBD);
  static const Color kTextOnPrimary = Color(0xFFFFFFFF);
  
  // UI colors
  static const Color kDividerColor = Color(0xFFE0E0E0);
  static const Color kInputBorder = Color(0xFFE0E0E0);
  static const Color kShadowColor = Color(0x14000000);
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.kPrimaryColor,
      scaffoldBackgroundColor: AppColors.kBackgroundColor,
      colorScheme: const ColorScheme.light(
        primary: AppColors.kPrimaryColor,
        secondary: AppColors.kSecondaryColor,
        surface: AppColors.kSurfaceColor,
        error: AppColors.kDangerColor,
        onPrimary: AppColors.kTextOnPrimary,
        onSecondary: AppColors.kTextOnPrimary,
        onSurface: AppColors.kTextPrimary,
        onError: AppColors.kTextOnPrimary,
      ),
      
      // Typography - Using default fonts (Poppins/Inter can be added via google_fonts)
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'Roboto', fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.kTextPrimary),
        displayMedium: TextStyle(fontFamily: 'Roboto', fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.kTextPrimary),
        displaySmall: TextStyle(fontFamily: 'Roboto', fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.kTextPrimary),
        headlineLarge: TextStyle(fontFamily: 'Roboto', fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.kTextPrimary),
        headlineMedium: TextStyle(fontFamily: 'Roboto', fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.kTextPrimary),
        headlineSmall: TextStyle(fontFamily: 'Roboto', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.kTextPrimary),
        titleLarge: TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.kTextPrimary),
        titleMedium: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.kTextPrimary),
        titleSmall: TextStyle(fontFamily: 'Roboto', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.kTextPrimary),
        bodyLarge: TextStyle(fontFamily: 'Roboto', fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.kTextPrimary),
        bodyMedium: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.kTextPrimary),
        bodySmall: TextStyle(fontFamily: 'Roboto', fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.kTextSecondary),
        labelLarge: TextStyle(fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.kTextPrimary),
        labelMedium: TextStyle(fontFamily: 'Roboto', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.kTextSecondary),
        labelSmall: TextStyle(fontFamily: 'Roboto', fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.kTextSecondary),
      ),
      
      // Card theme
      cardTheme: CardTheme(
        color: AppColors.kSurfaceColor,
        elevation: 2,
        shadowColor: AppColors.kShadowColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.kPrimaryColor,
          foregroundColor: AppColors.kTextOnPrimary,
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
      ),
      
      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.kPrimaryColor,
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: const BorderSide(color: AppColors.kPrimaryColor, width: 1.5),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.kSurfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.kInputBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.kInputBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.kPrimaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.kDangerColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.kDangerColor, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.kTextSecondary),
        hintStyle: const TextStyle(color: AppColors.kTextDisabled),
      ),
      
      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.kSurfaceColor,
        foregroundColor: AppColors.kTextPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.kTextPrimary,
        ),
      ),
      
      // Bottom navigation bar theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.kSurfaceColor,
        selectedItemColor: AppColors.kPrimaryColor,
        unselectedItemColor: AppColors.kTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.kPrimaryColor,
        foregroundColor: AppColors.kTextOnPrimary,
        elevation: 4,
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.kSurfaceColor,
        deleteIconColor: AppColors.kTextSecondary,
        labelStyle: const TextStyle(color: AppColors.kTextPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      
      // Divider theme
      dividerTheme: const DividerThemeData(
        color: AppColors.kDividerColor,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
