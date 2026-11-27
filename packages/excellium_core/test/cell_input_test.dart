import 'package:excellium_core/excellium_core.dart';
import 'package:test/test.dart';

CellValue? ok(ColumnType type, String input) {
  final result = parseCellInput(type, input);
  expect(result, isA<CellInputOk>(), reason: '« $input » devrait être accepté');
  return (result as CellInputOk).value;
}

CellInputError rejected(ColumnType type, String input) {
  final result = parseCellInput(type, input);
  expect(
    result,
    isA<CellInputRejected>(),
    reason: '« $input » devrait être refusé',
  );
  return (result as CellInputRejected).error;
}

void main() {
  group('parseCellInput', () {
    test('une saisie vide vide la cellule, quel que soit le type', () {
      for (final type in ColumnType.values) {
        expect(ok(type, ''), isNull, reason: type.name);
        expect(ok(type, '   '), isNull, reason: type.name);
      }
    });

    test('texte : conservé sans les espaces de bord', () {
      expect(
        ok(ColumnType.text, '  Import CSV '),
        const TextValue('Import CSV'),
      );
    });

    test('nombre : virgule ou point, espaces de milliers, signe', () {
      expect(ok(ColumnType.number, '1200'), const NumberValue(1200));
      expect(ok(ColumnType.number, '12,5'), const NumberValue(12.5));
      expect(ok(ColumnType.number, '12.5'), const NumberValue(12.5));
      expect(ok(ColumnType.number, '1 234,5'), const NumberValue(1234.5));
      expect(ok(ColumnType.number, '1 234'), const NumberValue(1234));
      expect(ok(ColumnType.number, '-0,25'), const NumberValue(-0.25));
    });

    test('nombre : refuse ce qui n\'en est pas un', () {
      expect(rejected(ColumnType.number, 'douze'), CellInputError.notANumber);
      expect(rejected(ColumnType.number, '1,2,3'), CellInputError.notANumber);
      expect(rejected(ColumnType.number, '12 %'), CellInputError.notANumber);
      expect(rejected(ColumnType.number, 'NaN'), CellInputError.notANumber);
      expect(rejected(ColumnType.number, '1e3'), CellInputError.notANumber);
    });

    test('pourcentage : accepte le signe %, 60 signifie 60 %', () {
      expect(ok(ColumnType.percent, '60'), const NumberValue(60));
      expect(ok(ColumnType.percent, '12,5 %'), const NumberValue(12.5));
      expect(rejected(ColumnType.percent, 'moitié'), CellInputError.notANumber);
    });

    test('date : JJ/MM/AAAA, variantes de séparateur, ou ISO', () {
      expect(ok(ColumnType.date, '04/12/2026'), DateValue(2026, 12, 4));
      expect(ok(ColumnType.date, '4/12/2026'), DateValue(2026, 12, 4));
      expect(ok(ColumnType.date, '04-12-2026'), DateValue(2026, 12, 4));
      expect(ok(ColumnType.date, '04.12.2026'), DateValue(2026, 12, 4));
      expect(ok(ColumnType.date, '2026-12-04'), DateValue(2026, 12, 4));
    });

    test('date : refuse les dates impossibles ou incomplètes', () {
      expect(rejected(ColumnType.date, '31/02/2026'), CellInputError.notADate);
      expect(rejected(ColumnType.date, '12/2026'), CellInputError.notADate);
      expect(rejected(ColumnType.date, 'demain'), CellInputError.notADate);
      expect(rejected(ColumnType.date, '04/13/2026'), CellInputError.notADate);
    });

    test('durée : 1:30, 1h30, 1 h 30, 2h, 45 min', () {
      const ninety = DurationValue(Duration(hours: 1, minutes: 30));
      expect(ok(ColumnType.duration, '1:30'), ninety);
      expect(ok(ColumnType.duration, '1h30'), ninety);
      expect(ok(ColumnType.duration, '1 h 30'), ninety);
      expect(
        ok(ColumnType.duration, '2h'),
        const DurationValue(Duration(hours: 2)),
      );
      expect(
        ok(ColumnType.duration, '45 min'),
        const DurationValue(Duration(minutes: 45)),
      );
    });

    test('durée : refuse des minutes au-delà de 59 et le texte libre', () {
      expect(
        rejected(ColumnType.duration, '1:75'),
        CellInputError.notADuration,
      );
      expect(
        rejected(ColumnType.duration, 'longtemps'),
        CellInputError.notADuration,
      );
      expect(rejected(ColumnType.duration, '90'), CellInputError.notADuration);
    });

    test('catégorie unique : tout le texte forme une seule catégorie', () {
      expect(
        ok(ColumnType.singleCategory, 'En cours, urgent'),
        CategoryValue.single('En cours, urgent'),
      );
    });

    test('catégorie multiple : séparée par virgule ou point-virgule', () {
      expect(
        ok(ColumnType.multiCategory, 'Design, Urgent ; Client'),
        CategoryValue(['Design', 'Urgent', 'Client']),
      );
    });

    test('catégorie multiple : ignore les doublons et les entrées vides', () {
      expect(
        ok(ColumnType.multiCategory, 'Design,, Design ,Urgent'),
        CategoryValue(['Design', 'Urgent']),
      );
      expect(ok(ColumnType.multiCategory, ' , ; '), isNull);
    });

    test('booléen : vrai/faux, oui/non, sans tenir compte de la casse', () {
      expect(ok(ColumnType.boolean, 'Vrai'), const BoolValue(true));
      expect(ok(ColumnType.boolean, 'oui'), const BoolValue(true));
      expect(ok(ColumnType.boolean, 'FAUX'), const BoolValue(false));
      expect(ok(ColumnType.boolean, 'non'), const BoolValue(false));
      expect(
        rejected(ColumnType.boolean, 'peut-être'),
        CellInputError.notABoolean,
      );
    });

    test('référence : ne se saisit pas au clavier', () {
      expect(
        rejected(ColumnType.reference, 'Camille'),
        CellInputError.notTypable,
      );
    });
  });

  group('cellInputText', () {
    test('est l\'inverse de parseCellInput pour chaque type saisissable', () {
      final cases = <(ColumnType, CellValue)>[
        (ColumnType.text, const TextValue('Atelier client')),
        (ColumnType.number, const NumberValue(1234.5)),
        (ColumnType.number, const NumberValue(-3)),
        (ColumnType.percent, const NumberValue(12.5)),
        (ColumnType.date, DateValue(2026, 1, 9)),
        (
          ColumnType.duration,
          const DurationValue(Duration(hours: 6, minutes: 5)),
        ),
        (ColumnType.singleCategory, CategoryValue.single('Terminé')),
        (ColumnType.multiCategory, CategoryValue(['Technique', 'Client'])),
        (ColumnType.boolean, const BoolValue(true)),
        (ColumnType.boolean, const BoolValue(false)),
      ];
      for (final (type, value) in cases) {
        expect(ok(type, cellInputText(value)), value, reason: '$type $value');
      }
    });

    test('écrit les nombres à la française, sans zéros inutiles', () {
      expect(cellInputText(const NumberValue(1200)), '1200');
      expect(cellInputText(const NumberValue(12.5)), '12,5');
      expect(cellInputText(DateValue(2026, 12, 4)), '04/12/2026');
      expect(
        cellInputText(const DurationValue(Duration(hours: 1, minutes: 5))),
        '1:05',
      );
      expect(cellInputText(null), '');
    });
  });

  group('convertCellValue', () {
    test('garde la valeur quand elle convient déjà au nouveau type', () {
      expect(
        convertCellValue(const NumberValue(60), ColumnType.percent),
        const NumberValue(60),
      );
      expect(
        convertCellValue(CategoryValue.single('A'), ColumnType.multiCategory),
        CategoryValue.single('A'),
      );
    });

    test('convertit un texte lisible dans le nouveau type', () {
      expect(
        convertCellValue(const TextValue('12,5'), ColumnType.number),
        const NumberValue(12.5),
      );
      expect(
        convertCellValue(const TextValue('04/12/2026'), ColumnType.date),
        DateValue(2026, 12, 4),
      );
      expect(
        convertCellValue(const TextValue('A, B'), ColumnType.multiCategory),
        CategoryValue(['A', 'B']),
      );
    });

    test('efface une valeur qui n\'a pas de sens dans le nouveau type', () {
      expect(
        convertCellValue(const TextValue('Import CSV'), ColumnType.number),
        isNull,
      );
      expect(
        convertCellValue(const NumberValue(3), ColumnType.reference),
        isNull,
      );
    });

    test(
      'ne garde que la première catégorie en passant à catégorie unique',
      () {
        expect(
          convertCellValue(
            CategoryValue(['Design', 'Urgent']),
            ColumnType.singleCategory,
          ),
          CategoryValue.single('Design'),
        );
      },
    );

    test('tout type devient un texte lisible', () {
      expect(
        convertCellValue(const NumberValue(12.5), ColumnType.text),
        const TextValue('12,5'),
      );
      expect(
        convertCellValue(DateValue(2026, 12, 4), ColumnType.text),
        const TextValue('04/12/2026'),
      );
    });
  });

  group('lettres de colonne', () {
    test('A, Z, AA, AZ, BA', () {
      expect(columnLetter(0), 'A');
      expect(columnLetter(25), 'Z');
      expect(columnLetter(26), 'AA');
      expect(columnLetter(51), 'AZ');
      expect(columnLetter(52), 'BA');
    });
  });
}
