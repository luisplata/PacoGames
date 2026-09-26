import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('SplashPage', () {
    testWidgets('primera vez (splashVisto=false) → aviso +18 y botón Entendido',
        (tester) async {
      await arrancarApp(tester, splashVisto: false);

      expect(find.text('PacoGame'), findsOneWidget);
      expect(find.textContaining('18'), findsOneWidget);
      expect(find.textContaining('alcohol'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Entendido'), findsOneWidget);
    });

    testWidgets('[Entendido] persiste el flag y navega a /home', (tester) async {
      await arrancarApp(tester, splashVisto: false);

      await tester.tap(find.widgetWithText(FilledButton, 'Entendido'));
      await tester.pumpAndSettle();

      // Llegamos al Home: botón Jugar visible, splash ya no está.
      expect(find.text('Jugar'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Entendido'), findsNothing);
    });

    testWidgets('splashVisto=true → salta el splash y va directo a /home',
        (tester) async {
      await arrancarApp(tester, splashVisto: true);

      expect(find.text('Jugar'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Entendido'), findsNothing);
    });
  });
}