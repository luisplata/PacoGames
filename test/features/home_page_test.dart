import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('HomePage', () {
    testWidgets('muestra 3 botones y la versión', (tester) async {
      await arrancarApp(tester, splashVisto: true);

      expect(find.text('PacoGames'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Jugar'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Cómo se juega'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Ajustes'), findsOneWidget);
      expect(find.textContaining('v0.1.0'), findsOneWidget);
    });

    testWidgets('[Jugar] navega al selector de juegos', (tester) async {
      await arrancarApp(tester, splashVisto: true);

      await navegarDesdeHome(tester, 'Jugar');

      expect(find.text('Yo Nunca'), findsOneWidget);
      expect(find.text('Ruleta'), findsOneWidget);
      expect(find.text('Pictionary'), findsOneWidget);
    });

    testWidgets('[Cómo se juega] navega a los pasos', (tester) async {
      await arrancarApp(tester, splashVisto: true);

      await navegarDesdeHome(tester, 'Cómo se juega');

      expect(find.text('Cómo se juega'), findsOneWidget);
    });

    testWidgets('[Ajustes] navega a los ajustes', (tester) async {
      await arrancarApp(tester, splashVisto: true);

      await navegarDesdeHome(tester, 'Ajustes');

      expect(find.text('Sonido'), findsOneWidget);
    });
  });
}