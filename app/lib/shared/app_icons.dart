import 'package:material_ui/material_ui.dart';
import 'package:path_drawing/path_drawing.dart';

/// Un pictogramme de la maquette : un tracé SVG au trait, sur une grille de
/// [viewBox] × [viewBox] (16 × 16 en général, 10 × 10 pour les flèches).
@immutable
final class AppIconData {
  const AppIconData(
    this.path, {
    this.viewBox = 16,
    this.strokeWidth = 1.5,
    this.filled = false,
  });

  /// L'attribut `d` du tracé, recopié de la maquette.
  final String path;
  final double viewBox;
  final double strokeWidth;

  /// Vrai si l'intérieur du tracé est rempli (l'entonnoir d'un filtre actif).
  final bool filled;
}

/// Les pictogrammes de l'application. Les tracés viennent de la maquette
/// (`Main.dc.html`) ; ceux qu'elle n'a pas (supprimer, renommer, erreur)
/// suivent le même dessin : trait de 1,5, extrémités arrondies.
abstract final class AppIcons {
  // Flèches, sur 10 × 10.
  static const chevronDown = AppIconData('M2 3.5l3 3 3-3', viewBox: 10);
  static const chevronLeft = AppIconData('M6.5 2l-3 3 3 3', viewBox: 10);
  static const chevronRight = AppIconData('M3.5 2l3 3-3 3', viewBox: 10);

  static const logo = AppIconData(
    'M4 2.5h8a1.5 1.5 0 011.5 1.5v8a1.5 1.5 0 01-1.5 1.5H4a1.5 1.5 0 '
    '01-1.5-1.5V4A1.5 1.5 0 014 2.5zM2.5 6.5h11M6.5 6.5v7',
  );
  static const close = AppIconData('M4 4l8 8M12 4l-8 8');
  static const closeBold = AppIconData('M4 4l8 8M12 4l-8 8', strokeWidth: 1.75);
  static const plus = AppIconData('M8 3v10M3 8h10');
  static const minus = AppIconData('M3 8h10');
  static const check = AppIconData('M3.5 8.5l3 3 6-7', strokeWidth: 1.75);
  static const search = AppIconData(
    'M7 3a4 4 0 100 8 4 4 0 000-8zM10 10l3.5 3.5',
  );
  static const filter = AppIconData('M2.5 3.5h11l-4.2 5v4.5l-2.6-1.5v-3z');
  static const filterFilled = AppIconData(
    'M2.5 3.5h11l-4.2 5v4.5l-2.6-1.5v-3z',
    filled: true,
  );
  static const columns = AppIconData(
    'M3.5 3h9a1 1 0 011 1v8a1 1 0 01-1 1h-9a1 1 0 01-1-1V4a1 1 0 011-1z'
    'M6.2 3v10M9.8 3v10',
  );
  static const group = AppIconData('M2.5 4h11M6 8h7.5M6 12h7.5M3 7v5');
  static const groupBold = AppIconData(
    'M2.5 4h11M6 8h7.5M6 12h7.5M3 7v5',
    strokeWidth: 2,
  );
  static const hide = AppIconData(
    'M2 8s2.2-4 6-4 6 4 6 4-2.2 4-6 4-6-4-6-4zM8 6.5a1.5 1.5 0 100 3 1.5 1.5 '
    '0 000-3zM3 13L13 3',
  );
  static const bookmark = AppIconData('M4.5 2.5h7v11L8 11l-3.5 2.5z');
  static const sortAscending = AppIconData('M8 13V3M4 7l4-4 4 4');
  static const sortDescending = AppIconData('M8 3v10M4 9l4 4 4-4');
  static const sortAscendingBold = AppIconData(
    'M8 13V3M4 7l4-4 4 4',
    strokeWidth: 2,
  );
  static const sortDescendingBold = AppIconData(
    'M8 3v10M4 9l4 4 4-4',
    strokeWidth: 2,
  );
  static const alignLeft = AppIconData('M3 4h10M3 8h6M3 12h8');
  static const alignCenter = AppIconData('M3 4h10M5 8h6M4 12h8');
  static const alignRight = AppIconData('M3 4h10M7 8h6M5 12h8');

  // Affichages.
  static const grid = AppIconData('M2.5 3h11v10h-11zM2.5 6.5h11M6.5 6.5V13');
  static const kanban = AppIconData(
    'M3 3h2.5v9H3zM6.8 3h2.5v6H6.8zM10.5 3H13v7.5h-2.5z',
  );
  static const calendar = AppIconData(
    'M3 4.5h10v8.5H3zM3 7.5h10M5.5 2.5v3M10.5 2.5v3',
  );

  // Réglages d'affichage de la barre de style.
  static const progressBar = AppIconData(
    'M4 5.5h8a2.5 2.5 0 010 5H4a2.5 2.5 0 010-5zM4.5 8h4',
  );
  static const toggle = AppIconData(
    'M5 4.5h6a3.5 3.5 0 010 7H5a3.5 3.5 0 010-7zM11 6.5a1.5 1.5 0 100 3 1.5 '
    '1.5 0 000-3z',
  );

  // Types de colonne.
  static const text = AppIconData('M3.5 4h9M8 4v8.5');
  static const number = AppIconData(
    'M6.2 2.5L5 13.5M11 2.5L9.8 13.5M3 6h10.5M2.5 10H13',
  );
  static const percent = AppIconData(
    'M4 12l8-8M5 3.5a1.5 1.5 0 100 3 1.5 1.5 0 000-3zM11 9.5a1.5 1.5 0 100 '
    '3 1.5 1.5 0 000-3z',
  );
  static const date = calendar;
  static const duration = AppIconData(
    'M8 2.5a5.5 5.5 0 100 11 5.5 5.5 0 000-11zM8 5v3l2 1.5',
  );
  static const singleCategory = AppIconData(
    'M5.5 5.5h5a2.5 2.5 0 010 5h-5a2.5 2.5 0 010-5z',
  );
  static const multiCategory = AppIconData(
    'M5 2.8h6a2 2 0 010 4H5a2 2 0 010-4zM5 9.2h6a2 2 0 010 4H5a2 2 0 010-4z',
  );
  static const boolean = AppIconData('M3.5 3.5h9v9h-9zM5.8 8.2l1.6 1.6 3-3.4');
  static const reference = AppIconData(
    'M6.5 9.5l3-3M7.2 4.8l1-1a2.5 2.5 0 013.5 3.5l-1 1M8.8 11.2l-1 1a2.5 2.5 '
    '0 01-3.5-3.5l1-1',
  );
  static const formula = AppIconData(
    'M10.5 3.2c-1.6-.6-2.7.2-3 1.9L6.3 12c-.3 1.6-1.4 2.2-2.8 1.6M4.8 7.5h4.4'
    'M10 9.5l3.5 4M13.5 9.5l-3.5 4',
  );

  // Barre de style.
  static const undo = AppIconData(
    'M6 3.5L3 6.5l3 3M3 6.5h6.5a3.5 3.5 0 010 7H7',
  );
  static const redo = AppIconData(
    'M10 3.5l3 3-3 3M13 6.5H6.5a3.5 3.5 0 000 7H9',
  );
  static const fill = AppIconData(
    'M8 2c2.4 2.8 3.8 4.9 3.8 6.7a3.8 3.8 0 01-7.6 0C4.2 6.9 5.6 4.8 8 2z',
  );
  static const borders = AppIconData('M2.5 2.5h11v11h-11zM8 2.5v11M2.5 8h11');
  static const wrap = AppIconData(
    'M3 4h10M3 8h8a2 2 0 010 4H9M3 12h3M10.2 10.8L9 12l1.2 1.2',
  );

  // Absents de la maquette, dessinés dans le même style.
  static const borderNone = AppIconData('M2.5 2.5h11v11h-11zM3 13L13 3');
  static const borderBottom = AppIconData('M2.5 13.5h11M2.5 3v7M13.5 3v7');
  static const borderBox = AppIconData('M2.5 2.5h11v11h-11z');
  static const rename = AppIconData('M10.5 3l2.5 2.5L6 12.5H3.5V10z');
  static const delete = AppIconData(
    'M3 4.5h10M6.5 4.5V3h3v1.5M4.5 4.5l.6 8.5h5.8l.6-8.5',
  );
  static const error = AppIconData(
    'M8 2.5a5.5 5.5 0 100 11 5.5 5.5 0 000-11zM8 5.2v3.3M8 10.8v.01',
  );
}

/// Dessine un [AppIconData] à la taille [size], dans la couleur [color]
/// (par défaut celle du thème d'icônes, comme une [Icon]).
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size = 16,
    this.color,
    this.semanticLabel,
    this.turns = 0,
  });

  final AppIconData icon;
  final double size;
  final Color? color;
  final String? semanticLabel;

  /// Rotation, en quarts de tour dans le sens horaire.
  final int turns;

  @override
  Widget build(BuildContext context) {
    final color =
        this.color ?? IconTheme.of(context).color ?? const Color(0xFF3A414C);
    Widget child = CustomPaint(
      size: Size.square(size),
      painter: _IconPainter(icon, color),
    );
    if (turns != 0) child = RotatedBox(quarterTurns: turns, child: child);
    return Semantics(
      container: semanticLabel != null,
      label: semanticLabel,
      excludeSemantics: semanticLabel == null,
      child: SizedBox.square(dimension: size, child: child),
    );
  }
}

/// Les tracés, lus une fois pour toutes.
final Map<String, Path> _paths = {};

class _IconPainter extends CustomPainter {
  _IconPainter(this.icon, this.color);

  final AppIconData icon;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _paths.putIfAbsent(
      icon.path,
      () => parseSvgPathData(icon.path),
    );
    final scale = size.width / icon.viewBox;
    canvas.save();
    canvas.scale(scale);
    if (icon.filled) {
      canvas.drawPath(path, Paint()..color = color);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = icon.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.icon != icon || old.color != color;
}
