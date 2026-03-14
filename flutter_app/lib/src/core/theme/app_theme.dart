// File: lib/src/core/theme/app_theme.dart
import 'package:flutter/cupertino.dart';

/// iOS 26 konseptine uygun renk paleti — pastel tonlar + saf siyah/beyaz kontrast.
class AppColors {
  AppColors._();

  // ── Ana Renkler ──────────────────────────────────────────────────────────────
  static const Color primaryBlue    = Color(0xFF3B82F6);
  static const Color accentIndigo   = Color(0xFF6366F1);
  static const Color accentViolet   = Color(0xFF8B5CF6);

  // ── Arka Plan & Yüzey ────────────────────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF000000); // Saf siyah
  static const Color surfaceDark    = Color(0xFF0D0D0D); // Kartlar için çok koyu gri
  static const Color surfaceGlass   = Color(0x1AFFFFFF); // %10 beyaz (cam efekti dolgusu)
  static const Color glassBorder    = Color(0x33FFFFFF); // %20 beyaz (cam efekti kenarı)

  // ── Metin ────────────────────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFFFFFFFF);
  static const Color textSecondary  = Color(0xFF8E8E93); // iOS system gray
  static const Color textTertiary   = Color(0xFF636366); // iOS system gray 2

  // ── Durum Renkleri ───────────────────────────────────────────────────────────
  static const Color success        = Color(0xFF34D399); // Emerald green
  static const Color danger         = Color(0xFFFF453A); // iOS system red
  static const Color warning        = Color(0xFFFFD60A); // iOS system yellow
  static const Color incomeGreen    = Color(0xFF30D158); // iOS system green

  // ── Ayrıcı Çizgi ─────────────────────────────────────────────────────────────
  static const Color separator      = Color(0xFF2C2C2E); // iOS separator dark
}

/// Uygulama genelinde kullanılan CupertinoThemeData.
class AppTheme {
  AppTheme._();

  static const CupertinoThemeData cupertinoTheme = CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryBlue,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    barBackgroundColor: Color(0xCC000000), // %80 siyah — nav bar için frosted effect
    textTheme: CupertinoTextThemeData(
      primaryColor: AppColors.textPrimary,
      textStyle: TextStyle(
        fontFamily: '.SF Pro Text',
        color: AppColors.textPrimary,
        fontSize: 15,
      ),
      navTitleTextStyle: TextStyle(
        fontFamily: '.SF Pro Display',
        color: AppColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
      navLargeTitleTextStyle: TextStyle(
        fontFamily: '.SF Pro Display',
        color: AppColors.textPrimary,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.37,
      ),
      tabLabelTextStyle: TextStyle(
        fontFamily: '.SF Pro Text',
        color: AppColors.textSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
