import 'package:excellium_app/app/startup_error_app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('explique l\'échec d\'ouverture et montre le détail', (
    tester,
  ) async {
    await tester.pumpWidget(
      const StartupErrorApp(error: 'dossier de données introuvable'),
    );

    expect(find.text('Le classeur n\'a pas pu être ouvert'), findsOneWidget);
    expect(
      find.textContaining('dossier de données introuvable'),
      findsOneWidget,
    );
  });
}
