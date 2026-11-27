import 'package:material_ui/material_ui.dart';

import '../app/theme.dart';

/// Traits nets, calés sur les pixels de l'écran.
///
/// Sur un écran réglé à 125 % ou 150 %, un trait de 1 point fait 1,25 ou
/// 1,5 pixel : Flutter l'étale alors sur deux pixels, dont l'un plus pâle.
/// Un navigateur, lui, arrondit l'épaisseur d'une bordure à un nombre entier
/// de pixels. Ces traits font de même : 1 point donne 1 pixel, sans lissage,
/// donc d'une seule couleur, quelle que soit l'échelle de l'écran ou le zoom.

/// Nombre de pixels de l'écran par point, zoom de la feuille compris.
class PixelScale extends InheritedWidget {
  const PixelScale({super.key, required this.scale, required super.child});

  final double scale;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PixelScale>()?.scale ??
      MediaQuery.devicePixelRatioOf(context);

  @override
  bool updateShouldNotify(PixelScale old) => old.scale != scale;
}

/// Un trait : sa couleur et son épaisseur en points.
@immutable
final class Line {
  const Line(this.color, [this.width = 1]);

  final Color color;
  final double width;

  /// Épaisseur en points, arrondie à un nombre entier de pixels (au moins
  /// un), comme une bordure de navigateur.
  double snapped(double scale) {
    final pixels = (width * scale + 0.001).floor();
    return (pixels < 1 ? 1 : pixels) / scale;
  }

  @override
  bool operator ==(Object other) =>
      other is Line && other.color == color && other.width == width;

  @override
  int get hashCode => Object.hash(color, width);
}

/// Les traits des quatre côtés d'un rectangle, tracés à l'intérieur.
@immutable
final class Edges {
  const Edges({this.top, this.right, this.bottom, this.left});

  const Edges.all(Line line)
    : top = line,
      right = line,
      bottom = line,
      left = line;

  final Line? top;
  final Line? right;
  final Line? bottom;
  final Line? left;

  @override
  bool operator ==(Object other) =>
      other is Edges &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom &&
      other.left == left;

  @override
  int get hashCode => Object.hash(top, right, bottom, left);
}

/// Traits d'une cellule de la grille : à droite et en bas.
const gridCellEdges = Edges(
  right: Line(AppColors.gridLine),
  bottom: Line(AppColors.gridLine),
);

/// Traits d'un en-tête de ligne ou de colonne : à droite et en bas, plus
/// foncés.
const headerEdges = Edges(
  right: Line(AppColors.headerLine),
  bottom: Line(AppColors.headerLine),
);

/// Cadre de 2 points de la cellule ou de la case sélectionnée.
const selectionFrame = Edges.all(Line(AppColors.accent, 2));

/// Dessine des traits nets par-dessus [child], sans prendre de place, et
/// éventuellement un fond [color] dessous.
///
/// Les couches de [edges] sont tracées dans l'ordre : la dernière (le cadre
/// de sélection, par exemple) recouvre les précédentes. Le fond n'est pas
/// lissé non plus : lissé, celui d'une cellule déborderait à moitié sur le
/// trait de sa voisine et le pâlirait.
class Lined extends StatelessWidget {
  const Lined({
    super.key,
    required this.edges,
    required this.child,
    this.color,
  });

  final List<Edges> edges;
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scale = PixelScale.of(context);
    return CustomPaint(
      painter: color == null ? null : _FillPainter(color!),
      foregroundPainter: _LinesPainter(edges, scale),
      child: child,
    );
  }
}

class _FillPainter extends CustomPainter {
  _FillPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawRect(
    Offset.zero & size,
    Paint()
      ..color = color
      ..isAntiAlias = false,
  );

  @override
  bool shouldRepaint(_FillPainter old) => old.color != color;
}

/// Trait vertical de [height] points, net.
class VLine extends StatelessWidget {
  const VLine({super.key, required this.color, required this.height});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scale = PixelScale.of(context);
    final width = Line(color).snapped(scale);
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _LinesPainter([Edges(left: Line(color))], scale),
      ),
    );
  }
}

class _LinesPainter extends CustomPainter {
  _LinesPainter(this.edges, this.scale);

  final List<Edges> edges;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    for (final layer in edges) {
      void draw(Line? line, Rect Function(double width) rect) {
        if (line == null) return;
        canvas.drawRect(
          rect(line.snapped(scale)),
          Paint()
            ..color = line.color
            // Sans lissage : chaque pixel est entièrement de la couleur du
            // trait, ou pas du tout.
            ..isAntiAlias = false,
        );
      }

      draw(layer.top, (w) => Rect.fromLTWH(0, 0, size.width, w));
      draw(
        layer.bottom,
        (w) => Rect.fromLTWH(0, size.height - w, size.width, w),
      );
      draw(layer.left, (w) => Rect.fromLTWH(0, 0, w, size.height));
      draw(
        layer.right,
        (w) => Rect.fromLTWH(size.width - w, 0, w, size.height),
      );
    }
  }

  @override
  bool shouldRepaint(_LinesPainter old) =>
      old.scale != scale || !_sameEdges(old.edges, edges);

  static bool _sameEdges(List<Edges> a, List<Edges> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Comme un [Container] avec fond et bordures, mais avec des traits nets
/// (voir [Lined]).
class LinedBox extends StatelessWidget {
  const LinedBox({
    super.key,
    this.width,
    this.height,
    this.constraints,
    this.padding,
    this.alignment,
    this.color,
    this.edges = const [],
    this.child,
  });

  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;
  final Color? color;
  final List<Edges> edges;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Lined(
    color: color,
    edges: edges,
    child: Container(
      width: width,
      height: height,
      constraints: constraints,
      padding: padding,
      alignment: alignment,
      child: child,
    ),
  );
}
