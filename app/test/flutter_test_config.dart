import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Charge les vraies polices avant les tests d'interface.
///
/// Par défaut, les tests de widgets utilisent une police factice dont chaque
/// caractère est un carré : les largeurs de texte n'ont alors rien à voir
/// avec l'application réelle, et les débordements signalés sont faux. Les
/// polices viennent du SDK Flutter ; si elles sont introuvables, les tests
/// tournent avec la police factice.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final dir = '$root/bin/cache/artifacts/material_fonts';
    await _load('Roboto', [
      '$dir/Roboto-Regular.ttf',
      '$dir/Roboto-Medium.ttf',
      '$dir/Roboto-Bold.ttf',
      '$dir/Roboto-Italic.ttf',
    ]);
    await _load('MaterialIcons', ['$dir/MaterialIcons-Regular.otf']);
  }
  await testMain();
}

Future<void> _load(String family, List<String> paths) async {
  final loader = FontLoader(family);
  var found = false;
  for (final path in paths) {
    final file = File(path);
    if (!file.existsSync()) continue;
    found = true;
    final bytes = file.readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  if (found) await loader.load();
}
