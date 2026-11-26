import 'package:material_ui/material_ui.dart';

/// Couleurs et dimensions de l'interface, reprises de la maquette.
abstract final class AppColors {
  static const accent = Color(0xFF3D4FD6);
  static const accentTint = Color(0xFFE4E7FA);
  static const columnTint = Color(0xFFF3F4FD);
  static const text = Color(0xFF1C2026);
  static const textMuted = Color(0xFF5A6270);
  static const textSubtle = Color(0xFF3A414C);
  static const surface = Color(0xFFFFFFFF);
  static const header = Color(0xFFF4F5F7);
  static const gridLine = Color(0xFFE3E6EA);
  static const headerLine = Color(0xFFD5D9DF);
  static const fieldBorder = Color(0xFF7A828E);
  static const danger = Color(0xFFB3261E);
}

abstract final class AppSizes {
  static const double rowHeight = 28;
  static const double rowHeaderWidth = 46;
  static const double barHeight = 48;
  static const double tabsHeight = 44;
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    primary: AppColors.accent,
    surface: AppColors.surface,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.surface,
    visualDensity: VisualDensity.compact,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 13, color: AppColors.text),
      bodySmall: TextStyle(fontSize: 12, color: AppColors.textMuted),
    ),
  );
}
