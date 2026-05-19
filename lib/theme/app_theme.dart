// lib/theme/app_theme.dart
// Defines the biotechnology / medical monitoring color palette and typography.

import 'package:flutter/material.dart';

class AppTheme {
  // ── Core Palette 
  static const Color navyDeep    = Color(0xFF050E1F);
  static const Color navyDark    = Color(0xFF0A1628);
  static const Color navyMid     = Color(0xFF0F2044);
  static const Color navyPanel   = Color(0xFF112254);
  static const Color cyanBright  = Color(0xFF00E5FF);
  static const Color cyanMid     = Color(0xFF00B8D4);
  static const Color cyanDim     = Color(0xFF0097A7);
  static const Color white       = Color(0xFFFFFFFF);
  static const Color whiteAlpha  = Color(0xCCFFFFFF);
  static const Color whiteDim    = Color(0xFF8DA9C4);
  static const Color safeGreen   = Color(0xFF00E676);
  static const Color safeGreenBg = Color(0xFF003D1E);
  static const Color riskRed     = Color(0xFFFF1744);
  static const Color riskRedBg   = Color(0xFF3D0010);
  static const Color riskOrange  = Color(0xFFFF6D00);
  static const Color gridLine    = Color(0x1A00E5FF);

  // ── Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navyDeep, navyDark, Color(0xFF081830)],
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [cyanBright, cyanMid],
  );

  static const LinearGradient safeGradient = LinearGradient(
    colors: [safeGreen, Color(0xFF00C853)],
  );

  static const LinearGradient riskGradient = LinearGradient(
    colors: [riskRed, riskOrange],
  );

  // ── Material 3 ThemeData 
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: cyanBright,
      secondary: cyanMid,
      surface: navyPanel,
      error: riskRed,
      onPrimary: navyDeep,
      onSecondary: navyDeep,
      onSurface: white,
    ),
    scaffoldBackgroundColor: navyDeep,
    fontFamily: 'Rajdhani',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Rajdhani',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: white,
        letterSpacing: 1.5,
      ),
    ),
    cardTheme: CardThemeData(
      color: navyPanel,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: gridLine, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: cyanBright,
        foregroundColor: navyDeep,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontFamily: 'Rajdhani',
          fontWeight: FontWeight.w700,
          fontSize: 16,
          letterSpacing: 1.2,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: cyanBright,
        textStyle: const TextStyle(
          fontFamily: 'Rajdhani',
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: navyPanel,
      contentTextStyle: TextStyle(
        fontFamily: 'Rajdhani',
        color: white,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: const DividerThemeData(color: gridLine),
  );
}
