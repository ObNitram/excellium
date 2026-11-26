import 'package:material_ui/material_ui.dart';

/// Couleurs de l'interface, reprises telles quelles de la maquette.
abstract final class AppColors {
  static const accent = Color(0xFF3D4FD6);

  /// Teintes de l'accent mêlé au blanc, comme `color-mix(in srgb, accent
  /// N %, #FFFFFF)` dans la maquette.
  static const accentTint8 = Color(0xFFEFF1FC);
  static const accentTint12 = Color(0xFFE8EAFA);
  static const accentTint = Color(0xFFE4E6F9); // 14 %
  static const accentTint16 = Color(0xFFE0E3F8);
  static const accentTint18 = Color(0xFFDCDFF8);
  static const accentTint30 = Color(0xFFC5CAF3);

  /// Fond des cellules d'une colonne entièrement sélectionnée.
  static const columnTint = accentTint8;

  static const text = Color(0xFF1C2026);
  static const textSubtle = Color(0xFF3A414C);
  static const textMuted = Color(0xFF5A6270);
  static const surface = Color(0xFFFFFFFF);

  /// Fond des en-têtes, de la barre de vue, des onglets et des groupes.
  static const header = Color(0xFFF4F5F7);

  /// Fond des cases de calcul.
  static const calcSurface = Color(0xFFFAFBFC);

  /// Fond d'un sélecteur à segments et d'une colonne du kanban.
  static const track = Color(0xFFE6E9ED);

  /// Survol d'un bouton.
  static const hover = Color(0xFFE9ECF0);

  /// Survol d'un bouton posé sur un fond coloré (en-tête, colonne du kanban).
  static const hoverOnTint = Color(0x141C2026);

  /// Traits entre les cellules, sous la barre de titre, entre les entrées
  /// d'un menu.
  static const gridLine = Color(0xFFE3E6EA);

  /// Traits des en-têtes, sous les barres, séparateurs verticaux, bord des
  /// panneaux.
  static const headerLine = Color(0xFFD5D9DF);

  /// Bord des champs et des boutons à bordure.
  static const fieldBorder = Color(0xFF7A828E);
  static const danger = Color(0xFFB3261E);

  /// Bouton ou entrée inactifs.
  static const disabled = Color(0xFFA9AFB8);
}

/// Dimensions de l'interface.
abstract final class AppSizes {
  static const double rowHeight = 28;
  static const double rowHeaderWidth = 46;
  static const double titleBarHeight = 48;
  static const double styleBarHeight = 44;
  static const double barHeight = 48;
  static const double viewBarHeight = 40;
  static const double tabsHeight = 44;

  /// Hauteur des boutons et des champs des barres.
  static const double control = 32;

  /// Hauteur des boutons de la barre de vue, des pastilles et des segments.
  static const double smallControl = 28;
}

/// Ombres de la maquette.
abstract final class AppShadows {
  /// Panneau flottant : `0 8px 24px rgba(28, 32, 38, 0.14)`.
  static const panel = [
    BoxShadow(color: Color(0x241C2026), blurRadius: 24, offset: Offset(0, 8)),
  ];

  /// Segment choisi : `0 1px 2px rgba(28, 32, 38, 0.18)`.
  static const segment = [
    BoxShadow(color: Color(0x2E1C2026), blurRadius: 2, offset: Offset(0, 1)),
  ];

  /// Carte du kanban : `0 1px 2px rgba(28, 32, 38, 0.10)`.
  static const card = [
    BoxShadow(color: Color(0x1A1C2026), blurRadius: 2, offset: Offset(0, 1)),
  ];
}

/// Styles de texte récurrents.
abstract final class AppText {
  /// Titre de section d'un panneau : petites capitales espacées.
  static const panelTitle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.44,
    color: AppColors.textMuted,
  );

  /// Texte d'aide, sur 12 px.
  static const help = TextStyle(
    fontSize: 12,
    height: 1.4,
    color: AppColors.textMuted,
  );

  /// Police à chasse fixe des formules.
  static const mono = TextStyle(fontSize: 12, fontFamily: 'JetBrains Mono');
}

/// Familles de caractères des polices proposées pour les cellules.
abstract final class AppFonts {
  static const sans = 'Inter';
  static const serif = 'Liberation Serif';
  static const mono = 'JetBrains Mono';

  /// Une taille en points devient des pixels : 10 points font les 13 px du
  /// texte de la grille.
  static double pixels(int points) => points * 1.3;
}

/// Bord d'un champ de saisie ou d'un bouton à bordure.
OutlineInputBorder fieldBorder({Color color = AppColors.fieldBorder}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: color),
    );

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    primary: AppColors.accent,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    error: AppColors.danger,
  );
  final base = ThemeData(colorScheme: scheme, fontFamily: 'Inter');
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.surface,
    visualDensity: VisualDensity.compact,
    // Dimensions de bureau, quelle que soit la plateforme : sans cela les
    // boutons seraient plus grands sur mobile, et dans les tests, qui
    // s'exécutent par défaut avec les réglages mobiles.
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    // Comme dans la maquette : un bouton survolé prend un fond gris, sans
    // onde au clic.
    hoverColor: AppColors.hover,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    focusColor: AppColors.hover,
    dividerColor: AppColors.headerLine,
    textTheme: _tabular(
      base.textTheme.copyWith(
        bodyMedium: const TextStyle(fontSize: 13, color: AppColors.text),
        bodyLarge: const TextStyle(fontSize: 13, color: AppColors.text),
        bodySmall: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        labelLarge: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        titleMedium: const TextStyle(fontSize: 13, color: AppColors.text),
      ),
    ),
    // Champs de 32 px : 20 px de texte et 6 px de marge en haut et en bas.
    // La densité compacte du reste de l'interface retirerait 4 px à ces
    // marges ; les champs gardent donc la densité normale.
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: AppColors.surface,
      visualDensity: VisualDensity.standard,
      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      border: fieldBorder(),
      enabledBorder: fieldBorder(),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      errorBorder: fieldBorder(color: AppColors.danger),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        // Hauteur exacte, sans la réduction de la densité compacte.
        visualDensity: VisualDensity.standard,
        minimumSize: const Size(0, AppSizes.smallControl),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ).copyWith(overlayColor: const WidgetStatePropertyAll(AppColors.hover)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        // Hauteur exacte, sans la réduction de la densité compacte.
        visualDensity: VisualDensity.standard,
        foregroundColor: AppColors.surface,
        minimumSize: const Size(0, AppSizes.smallControl),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        side: BorderSide(color: AppColors.headerLine),
      ),
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
      ),
    ),
    tooltipTheme: const TooltipThemeData(
      waitDuration: Duration(milliseconds: 600),
      textStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.surface,
      ),
      decoration: BoxDecoration(
        color: AppColors.text,
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    ),
  );
}

/// Chiffres à chasse fixe partout, comme `font-variant-numeric:
/// tabular-nums` dans la maquette : les nombres s'alignent en colonne.
TextTheme _tabular(TextTheme theme) {
  TextStyle? fix(TextStyle? style) => style?.copyWith(
    fontFamily: 'Inter',
    fontFeatures: const [FontFeature.tabularFigures()],
  );
  return theme.copyWith(
    displayLarge: fix(theme.displayLarge),
    displayMedium: fix(theme.displayMedium),
    displaySmall: fix(theme.displaySmall),
    headlineLarge: fix(theme.headlineLarge),
    headlineMedium: fix(theme.headlineMedium),
    headlineSmall: fix(theme.headlineSmall),
    titleLarge: fix(theme.titleLarge),
    titleMedium: fix(theme.titleMedium),
    titleSmall: fix(theme.titleSmall),
    bodyLarge: fix(theme.bodyLarge),
    bodyMedium: fix(theme.bodyMedium),
    bodySmall: fix(theme.bodySmall),
    labelLarge: fix(theme.labelLarge),
    labelMedium: fix(theme.labelMedium),
    labelSmall: fix(theme.labelSmall),
  );
}
