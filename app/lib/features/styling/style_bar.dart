import 'package:excellium_core/excellium_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/theme.dart';
import '../../shared/app_icons.dart';
import '../../shared/pixel_lines.dart';
import '../../shared/controls.dart';
import '../../shared/popover.dart';
import '../../shared/providers.dart';
import '../../shared/segmented.dart';
import '../grid/calc_pane.dart' show calcRowCount;
import '../grid/column_type_ui.dart';
import '../grid/grid_providers.dart';
import 'colors.dart';

/// Barre de style, dans l'ordre de la maquette : annuler et rétablir, zoom,
/// affichage du type, format des nombres, police et taille, gras, italique,
/// souligné et couleur du texte, remplissage et bordures, alignement et
/// retour à la ligne, fonctions.
///
/// Les réglages portent sur la sélection : toute la colonne si elle est
/// sélectionnée, sinon la cellule. Seuls ceux qui ont un sens pour le type de
/// la colonne sont affichés.
class StyleBar extends ConsumerWidget {
  const StyleBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final column = ref.watch(selectedColumnProvider);
    final cell = ref.watch(selectedCellProvider);
    final selection = ref.watch(selectionProvider);
    final hasTarget =
        column != null && !(selection is CellSelected && cell == null);

    return LinedBox(
      // 32 px de boutons, 6 px de marge en haut et en bas, 1 px de bordure :
      // la barre a la même hauteur vide ou remplie.
      constraints: const BoxConstraints(minHeight: AppSizes.control + 13),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: AppColors.surface,
      edges: const [Edges(bottom: Line(AppColors.headerLine))],
      alignment: Alignment.centerLeft,
      child: _Groups([
        const _History(),
        const _ZoomButton(),
        if (hasTarget)
          ..._Controls(column: column, row: cell?.row).groups(context, ref)
        else
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Sélectionnez une cellule ou une colonne pour régler son style.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
      ]),
    );
  }
}

/// Groupes de boutons séparés par un trait vertical, comme dans la maquette.
class _Groups extends StatelessWidget {
  const _Groups(this.groups);

  final List<Widget> groups;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (final (index, group) in groups.indexed) ...[
        if (index > 0) const VSeparator(),
        group,
      ],
    ],
  );
}

/// Annuler et rétablir.
class _History extends ConsumerWidget {
  const _History();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state =
        ref.watch(undoStateProvider).value ?? (canUndo: false, canRedo: false);
    final service = ref.read(workbookServiceProvider);
    return _Buttons([
      IconBtn(
        tooltip: 'Annuler (Ctrl+Z)',
        icon: AppIcons.undo,
        onPressed: state.canUndo ? service.undo : null,
      ),
      IconBtn(
        tooltip: 'Rétablir (Ctrl+Y)',
        icon: AppIcons.redo,
        onPressed: state.canRedo ? service.redo : null,
      ),
    ]);
  }
}

/// Zoom de la feuille.
class _ZoomButton extends ConsumerWidget {
  const _ZoomButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoom = ref.watch(zoomProvider);
    return Popover(
      width: 160,
      anchorBuilder: (context, toggle, _) => _DropButton(
        tooltip: 'Zoom',
        label: zoomLabel(zoom),
        onPressed: toggle,
      ),
      panelBuilder: (context, close) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final level in Zoom.levels)
            PanelItem(
              label: zoomLabel(level),
              selected: level == zoom,
              onTap: () {
                ref.read(zoomProvider.notifier).set(level);
                close();
              },
            ),
        ],
      ),
    );
  }
}

/// « 125 % ».
String zoomLabel(double zoom) => '${(zoom * 100).round()} %';

/// Nom affiché d'une police.
String fontLabel(CellFont font) => switch (font) {
  CellFont.sans => 'Inter',
  CellFont.serif => 'Liberation Serif',
  CellFont.mono => 'JetBrains Mono',
};

/// Famille de caractères d'une police.
String fontFamily(CellFont font) => switch (font) {
  CellFont.sans => AppFonts.sans,
  CellFont.serif => AppFonts.serif,
  CellFont.mono => AppFonts.mono,
};

/// Les réglages de la sélection.
class _Controls {
  _Controls({required this.column, required this.row});

  final ColumnDef column;

  /// La ligne de la cellule sélectionnée ; `null` si c'est toute la colonne.
  final SheetRow? row;

  List<Widget> groups(BuildContext context, WidgetRef ref) {
    final service = ref.read(workbookServiceProvider);
    final style = resolveStyle(column, row);
    final type = column.type;
    void apply(CellStyle patch) {
      final target = row;
      if (target == null) {
        service.styleColumn(column, patch);
      } else {
        service.styleCell(target, column, patch);
      }
    }

    final isNumber = type == ColumnType.number;
    final hasDecimals = isNumber || type == ColumnType.percent;
    final hasText =
        type.hasTextStyle ||
        (type == ColumnType.boolean && style.boolDisplay == BoolDisplay.text);
    final canWrap =
        type == ColumnType.text ||
        type == ColumnType.multiCategory ||
        type == ColumnType.reference;

    return [
      if (type == ColumnType.percent)
        _Labelled(
          label: 'Affichage',
          child: Segmented<PercentDisplay>(
            selected: style.percentDisplay,
            onSelected: (value) => apply(CellStyle(percentDisplay: value)),
            options: const [
              (
                value: PercentDisplay.value,
                label: 'Valeur',
                icon: AppIcons.percent,
              ),
              (
                value: PercentDisplay.bar,
                label: 'Barre de progression',
                icon: AppIcons.progressBar,
              ),
            ],
          ),
        ),
      if (type == ColumnType.boolean)
        _Labelled(
          label: 'Affichage',
          child: Segmented<BoolDisplay>(
            selected: style.boolDisplay,
            onSelected: (value) => apply(CellStyle(boolDisplay: value)),
            options: const [
              (
                value: BoolDisplay.checkbox,
                label: 'Case à cocher',
                icon: AppIcons.boolean,
              ),
              (
                value: BoolDisplay.toggle,
                label: 'Interrupteur',
                icon: AppIcons.toggle,
              ),
              (
                value: BoolDisplay.text,
                label: 'Vrai / Faux',
                icon: AppIcons.text,
              ),
            ],
          ),
        ),
      if (hasDecimals)
        _Buttons([
          if (isNumber) ...[
            IconBtn(
              tooltip: 'Format monétaire',
              on: style.numberFormat == NumberDisplay.currency,
              onPressed: () => apply(
                CellStyle(
                  numberFormat: style.numberFormat == NumberDisplay.currency
                      ? NumberDisplay.automatic
                      : NumberDisplay.currency,
                ),
              ),
              child: const Text('€', style: TextStyle(fontSize: 14)),
            ),
            IconBtn(
              tooltip: 'Format pourcentage (toute la colonne)',
              onPressed: () =>
                  service.changeColumnType(column, ColumnType.percent),
              child: const Text('%', style: TextStyle(fontSize: 14)),
            ),
          ],
          IconBtn(
            tooltip: 'Réduire les décimales',
            onPressed: () => apply(
              CellStyle(
                decimals: (_decimals(ref, style) - 1).clamp(
                  0,
                  CellStyle.maxDecimals,
                ),
              ),
            ),
            child: const Text(
              ',0',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          IconBtn(
            tooltip: 'Ajouter des décimales',
            onPressed: () => apply(
              CellStyle(
                decimals: (_decimals(ref, style) + 1).clamp(
                  0,
                  CellStyle.maxDecimals,
                ),
              ),
            ),
            child: const Text(
              ',00',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          if (isNumber) _NumberFormats(style: style, apply: apply),
        ]),
      if (hasText) ...[
        _Buttons([
          _FontButton(style: style, apply: apply),
          _SizeButton(style: style, apply: apply),
        ]),
        _Buttons([
          IconBtn(
            tooltip: 'Gras',
            on: style.bold,
            onPressed: () => apply(CellStyle(bold: !style.bold)),
            child: const Text(
              'G',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          IconBtn(
            tooltip: 'Italique',
            on: style.italic,
            onPressed: () => apply(CellStyle(italic: !style.italic)),
            child: const Text(
              'I',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          IconBtn(
            tooltip: 'Souligné',
            on: style.underline,
            onPressed: () => apply(CellStyle(underline: !style.underline)),
            child: const Text(
              'S',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          ColorButton.text(
            current: style.textColor,
            onPicked: (color) => apply(CellStyle(textColor: color ?? 0)),
          ),
        ]),
      ],
      _Buttons([
        ColorButton.fill(
          current: style.fillColor,
          onPicked: (color) => apply(CellStyle(fillColor: color ?? 0)),
        ),
        _BorderButton(style: style, apply: apply),
      ]),
      _Buttons([
        IconBtn(
          tooltip: 'Aligner à gauche',
          icon: AppIcons.alignLeft,
          on: style.align == TextAlignment.left,
          onPressed: () => apply(const CellStyle(align: TextAlignment.left)),
        ),
        IconBtn(
          tooltip: 'Centrer',
          icon: AppIcons.alignCenter,
          on: style.align == TextAlignment.center,
          onPressed: () => apply(const CellStyle(align: TextAlignment.center)),
        ),
        IconBtn(
          tooltip: 'Aligner à droite',
          icon: AppIcons.alignRight,
          on: style.align == TextAlignment.right,
          onPressed: () => apply(const CellStyle(align: TextAlignment.right)),
        ),
        if (canWrap)
          IconBtn(
            tooltip: 'Retour à la ligne automatique',
            icon: AppIcons.wrap,
            on: style.wrap,
            onPressed: () => apply(CellStyle(wrap: !style.wrap)),
          ),
      ]),
      if (isNumber) _FunctionsButton(column: column),
    ];
  }

  /// Décimales affichées aujourd'hui : celles choisies, sinon celles de la
  /// valeur la plus précise (de la cellule, ou de toute la colonne).
  int _decimals(WidgetRef ref, ResolvedStyle style) {
    if (style.decimals case final fixed?) return fixed;
    final rows = row == null
        ? ref.read(rowsProvider(column.sheetId)).value ?? const <SheetRow>[]
        : [row!];
    var most = 0;
    for (final candidate in rows) {
      if (candidate[column.id] case NumberValue(:final number)) {
        final text = formatNumber(number);
        final comma = text.indexOf(',');
        if (comma >= 0 && text.length - comma - 1 > most) {
          most = text.length - comma - 1;
        }
      }
    }
    return most;
  }
}

/// Boutons d'un même groupe, espacés de 2 px.
class _Buttons extends StatelessWidget {
  const _Buttons(this.buttons);

  final List<Widget> buttons;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final (index, button) in buttons.indexed) ...[
        if (index > 0) const SizedBox(width: 2),
        button,
      ],
    ],
  );
}

class _Labelled extends StatelessWidget {
  const _Labelled({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSubtle),
        ),
        const SizedBox(width: 8),
        child,
      ],
    );
  }
}

/// Bouton de 32 px de haut avec libellé et flèche (zoom, police, taille).
class _DropButton extends StatelessWidget {
  const _DropButton({
    required this.tooltip,
    required this.label,
    required this.onPressed,
    this.width,
  });

  final String tooltip;
  final String label;
  final VoidCallback onPressed;

  /// Largeur fixe (la police) ; sinon celle du libellé.
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: width,
            height: AppSizes.control,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  fit: width == null ? FlexFit.loose : FlexFit.tight,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppColors.text),
                  ),
                ),
                const SizedBox(width: 6),
                const AppIcon(AppIcons.chevronDown, size: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Choix de la police, chacune écrite dans sa propre police.
class _FontButton extends StatelessWidget {
  const _FontButton({required this.style, required this.apply});

  final ResolvedStyle style;
  final ValueChanged<CellStyle> apply;

  @override
  Widget build(BuildContext context) {
    return Popover(
      width: 220,
      anchorBuilder: (context, toggle, _) => _DropButton(
        tooltip: 'Police',
        label: fontLabel(style.font),
        width: 104,
        onPressed: toggle,
      ),
      panelBuilder: (context, close) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const PanelTitle('Police'),
          for (final font in CellFont.values)
            _FontItem(
              font: font,
              selected: font == style.font,
              onTap: () {
                apply(CellStyle(font: font));
                close();
              },
            ),
        ],
      ),
    );
  }
}

class _FontItem extends StatelessWidget {
  const _FontItem({
    required this.font,
    required this.selected,
    required this.onTap,
  });

  final CellFont font;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.text;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.accentTint : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    fontLabel(font),
                    style: TextStyle(
                      fontFamily: fontFamily(font),
                      fontSize: 14,
                      color: color,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (selected) AppIcon(AppIcons.check, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Taille de police, en points.
class _SizeButton extends StatelessWidget {
  const _SizeButton({required this.style, required this.apply});

  final ResolvedStyle style;
  final ValueChanged<CellStyle> apply;

  @override
  Widget build(BuildContext context) {
    return Popover(
      width: 120,
      anchorBuilder: (context, toggle, _) => _DropButton(
        tooltip: 'Taille de police',
        label: '${style.fontSize}',
        onPressed: toggle,
      ),
      panelBuilder: (context, close) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final size in CellStyle.fontSizes)
            PanelItem(
              label: '$size',
              height: 32,
              selected: size == style.fontSize,
              onTap: () {
                apply(CellStyle(fontSize: size));
                close();
              },
            ),
        ],
      ),
    );
  }
}

/// Autres formats d'un nombre (« 123 »).
class _NumberFormats extends StatelessWidget {
  const _NumberFormats({required this.style, required this.apply});

  final ResolvedStyle style;
  final ValueChanged<CellStyle> apply;

  @override
  Widget build(BuildContext context) {
    final automatic =
        style.numberFormat == NumberDisplay.automatic && style.decimals == null;
    final fixed =
        style.numberFormat == NumberDisplay.automatic && style.decimals == 2;
    final currency =
        style.numberFormat == NumberDisplay.currency && style.decimals == 2;
    Widget sample(String text) => Text(
      text,
      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
    );
    return Popover(
      width: 260,
      anchorBuilder: (context, toggle, _) => _DropButton(
        tooltip: 'Autres formats de nombre',
        label: '123',
        onPressed: toggle,
      ),
      panelBuilder: (context, close) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const PanelTitle('Format du nombre'),
          PanelItem(
            label: 'Automatique',
            selected: automatic,
            trailing: automatic ? null : sample('1234,5'),
            onTap: () {
              apply(
                const CellStyle(
                  numberFormat: NumberDisplay.automatic,
                  decimals: -1,
                ),
              );
              close();
            },
          ),
          PanelItem(
            label: 'Nombre',
            selected: fixed,
            trailing: fixed ? null : sample('1 234,50'),
            onTap: () {
              apply(
                const CellStyle(
                  numberFormat: NumberDisplay.automatic,
                  decimals: 2,
                ),
              );
              close();
            },
          ),
          PanelItem(
            label: 'Monétaire',
            selected: currency,
            trailing: currency ? null : sample('1 234,50 €'),
            onTap: () {
              apply(
                const CellStyle(
                  numberFormat: NumberDisplay.currency,
                  decimals: 2,
                ),
              );
              close();
            },
          ),
        ],
      ),
    );
  }
}

/// Bordure de la cellule.
class _BorderButton extends StatelessWidget {
  const _BorderButton({required this.style, required this.apply});

  final ResolvedStyle style;
  final ValueChanged<CellStyle> apply;

  @override
  Widget build(BuildContext context) {
    return Popover(
      width: 220,
      anchorBuilder: (context, toggle, _) => IconBtn(
        tooltip: 'Bordures',
        icon: AppIcons.borders,
        on: style.border != CellBorder.none,
        onPressed: toggle,
      ),
      panelBuilder: (context, close) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const PanelTitle('Bordures'),
          for (final (border, label, icon) in const [
            (CellBorder.none, 'Aucune bordure', AppIcons.borderNone),
            (CellBorder.bottom, 'Bordure du bas', AppIcons.borderBottom),
            (CellBorder.box, 'Encadrer', AppIcons.borderBox),
          ])
            PanelItem(
              icon: icon,
              label: label,
              selected: border == style.border,
              onTap: () {
                apply(CellStyle(border: border));
                close();
              },
            ),
        ],
      ),
    );
  }
}

/// Σ : ajoute sous la colonne une case de calcul avec la fonction choisie.
class _FunctionsButton extends ConsumerWidget {
  const _FunctionsButton({required this.column});

  final ColumnDef column;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final functions = [
      for (final function in ref.watch(formulaEngineProvider).functions)
        if (function.kind == FormulaFunctionKind.column) function,
    ];
    return Popover(
      width: 240,
      anchorBuilder: (context, toggle, _) => IconBtn(
        tooltip: 'Fonctions',
        onPressed: toggle,
        child: const Text(
          'Σ',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      panelBuilder: (context, close) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const PanelTitle('Calculer sous la colonne'),
          for (final function in functions)
            PanelItem(
              label: function.name,
              trailing: Text(
                '=${function.name}(${formulaReference(column)})',
                style: AppText.mono.copyWith(color: AppColors.textMuted),
              ),
              onTap: () async {
                close();
                await _insert(ref, function.name);
              },
            ),
        ],
      ),
    );
  }

  /// Écrit le calcul dans la première case libre sous la colonne et la
  /// sélectionne, en dépliant le volet des cases de calcul.
  Future<void> _insert(WidgetRef ref, String function) async {
    var index = 0;
    while (index < calcRowCount - 1 &&
        (column.calcCells[index] ?? '').trim().isNotEmpty) {
      index++;
    }
    await ref
        .read(workbookServiceProvider)
        .setCalcCell(column, index, '=$function(${formulaReference(column)})');
    ref.read(calcPaneProvider.notifier).show();
    ref.read(selectionProvider.notifier).selectCalcCell(index, column.id);
  }
}

/// La colonne telle qu'on l'écrit dans une formule : son nom, entre
/// crochets s'il contient autre chose que des lettres et des chiffres, ou
/// sa lettre si elle n'a pas de nom.
String formulaReference(ColumnDef column) {
  final name = column.name.trim();
  if (name.isEmpty) return column.letter;
  final simple = RegExp(r'^[A-Za-zÀ-ÖØ-öø-ÿ_][A-Za-zÀ-ÖØ-öø-ÿ0-9_]*$');
  return simple.hasMatch(name) ? name : '[$name]';
}
