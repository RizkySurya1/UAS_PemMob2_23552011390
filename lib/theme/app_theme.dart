import 'package:flutter/material.dart';

class AppTheme {
  // Primary Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color primaryDark = Color(0xFF1976D2);
  static const Color primaryLight = Color(0xFF64B5F6);
  
  // Accent Colors
  static const Color accentColor = Color(0xFFFF9800);
  static const Color accentLight = Color(0xFFFFB74D);
  
  // Neutral Colors
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color dividerColor = Color(0xFFE0E0E0);
  
  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color errorColor = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
  static const Color infoColor = Color(0xFF2196F3);
  
  // Order Status Colors
  static const Color pending = Color(0xFFFF9800);
  static const Color processing = Color(0xFF2196F3);
  static const Color shipped = Color(0xFF9C27B0);
  static const Color completed = Color(0xFF4CAF50);
  static const Color cancelled = Color(0xFFF44336);

  // Typography
  static const String fontFamily = 'Roboto';
  
  // Spacing
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 12.0;
  static const double spaceL = 16.0;
  static const double spaceXL = 24.0;
  static const double spaceXXL = 32.0;
  
  // Border Radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  
  // Elevation
  static const double elevationS = 2.0;
  static const double elevationM = 4.0;
  static const double elevationL = 8.0;

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: cardColor,
        error: error,
      ),
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontFamily: fontFamily,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: elevationS,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusM),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: spaceL,
          vertical: spaceS,
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusM),
          borderSide: const BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceL,
          vertical: spaceM,
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: elevationS,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceXL,
            vertical: spaceL,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: fontFamily,
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: spaceL,
            vertical: spaceM,
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: fontFamily,
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(
            horizontal: spaceXL,
            vertical: spaceL,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: fontFamily,
          ),
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: elevationM,
        selectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          fontFamily: fontFamily,
        ),
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFamily: fontFamily,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFamily: fontFamily,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFamily: fontFamily,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFamily: fontFamily,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFamily: fontFamily,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFamily: fontFamily,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textPrimary,
          fontFamily: fontFamily,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          fontFamily: fontFamily,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textPrimary,
          fontFamily: fontFamily,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textSecondary,
          fontFamily: fontFamily,
        ),
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: backgroundColor,
        selectedColor: primaryColor,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontFamily: fontFamily,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: spaceM,
          vertical: spaceS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusS),
        ),
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: spaceL,
      ),
      
      fontFamily: fontFamily,
    );
  }

  // Helper methods for status colors
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return pending;
      case 'diproses':
      case 'processing':
        return processing;
      case 'dikirim':
      case 'shipped':
        return shipped;
      case 'selesai':
      case 'completed':
        return completed;
      case 'dibatalkan':
      case 'cancelled':
        return cancelled;
      default:
        return textSecondary;
    }
  }

  // Helper method for gradient
  static LinearGradient primaryGradient = const LinearGradient(
    colors: [primaryColor, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient accentGradient = const LinearGradient(
    colors: [accentColor, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
