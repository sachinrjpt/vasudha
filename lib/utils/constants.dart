import 'package:flutter/material.dart';

/// App color palette
class AppColors {
  static const Color primary    = Color(0xFF03C95A); // green brand color
  static const Color bg         = Color(0xFFF8F8F8);
  static const Color headerBg   = Colors.white;
  static const Color sidebarBg  = Colors.white;
  static const Color text       = Colors.black87;
  static const Color subtle     = Colors.black54;
  static const Color activeChip = Color(0xFFE6F8EE); // subtle green highlight
}

/// Sizes, paddings, radii
class AppDimens {
  static const double sidebarWidth     = 250;
  static const double headerHeight     = 60;
  static const double cardRadius       = 8;
  static const double gutter           = 16;
  static const double pagePadding      = 16;
  static const double maxContentWidth  = 1200;
}

/// Layout breakpoints
class AppBreakpoints {
  static const double tablet  = 700;
  static const double desktop = 900;
}

/// Handy context extensions
extension ContextX on BuildContext {
  Size get size => MediaQuery.of(this).size;
  bool get isDesktop => size.width >= AppBreakpoints.desktop;
  bool get isTablet  =>
      size.width >= AppBreakpoints.tablet && size.width < AppBreakpoints.desktop;
  bool get isMobile  => size.width < AppBreakpoints.tablet;
}

/// Centralized theme (green branding)
final ThemeData appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
  ),
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.bg,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.headerBg,
    elevation: 0,
    foregroundColor: AppColors.text,
  ),
  drawerTheme: const DrawerThemeData(
    backgroundColor: AppColors.sidebarBg,
    width: AppDimens.sidebarWidth,
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
  ),
);
