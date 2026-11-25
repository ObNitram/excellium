import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Garde-fou de la séparation des responsabilités : seule la racine de
/// composition (`lib/bootstrap/`) a le droit de connaître le moteur de
/// stockage. Si ce test échoue, c'est qu'un écran ou un provider s'est mis à
/// dépendre de Drift, ce qui rendrait le changement de backend coûteux.
void main() {
  const forbidden = [
    'package:drift/',
    'package:drift_flutter/',
    'package:excellium_storage_drift/',
    'package:sqlite3/',
  ];

  test('seul lib/bootstrap/ importe le moteur de stockage', () {
    final offenders = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.startsWith('lib/bootstrap/'));

    for (final file in files) {
      for (final line in file.readAsLinesSync()) {
        final trimmed = line.trim();
        if (!trimmed.startsWith('import ') && !trimmed.startsWith('export ')) {
          continue;
        }
        if (forbidden.any(trimmed.contains)) {
          offenders.add('${file.path}: $trimmed');
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('le garde-fou parcourt bien les fichiers de l\'application', () {
    final checked = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.startsWith('lib/bootstrap/'));
    expect(checked.length, greaterThan(5));
    expect(File('lib/bootstrap/storage.dart').existsSync(), isTrue);
  });
}
