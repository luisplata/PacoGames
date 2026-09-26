import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('PictionaryInstruccionesPage', () {
    testWidgets('muestra título Pictionary, 3 bullets EXACTOS y "Qué necesitás"',
        (tester) async {
      await arrancarApp(tester, splashVisto: true);
      await navegarDesdeHome(tester, 'Jugar');
      await tester.tap(find.text('Pictionary'));
      await tester.pumpAndSettle();

      expect(find.text('Pictionary'), findsOneWidget);
      expect(
        find.text('Pasá el teléfono: el dibujante elige una de 3 palabras en secreto'),
        findsOneWidget,
      );
      expect(
        find.text('Dibujá en un papel mientras corre el timer de 60 segundos'),
        findsOneWidget,
      );
      expect(
        find.text(
            'Si adivinan: ¡punto para el equipo! Si no, el turno pasa sin sumar'),
        findsOneWidget,
      );
      expect(find.text('Qué necesitás: un papel y algo para dibujar'), findsOneWidget);
    });

    testWidgets('[Jugar] navega a /pictionary/juego (fase pase [Continuar])',
        (tester) async {
      await arrancarApp(tester, splashVisto: true);
      await navegarDesdeHome(tester, 'Jugar');
      await tester.tap(find.text('Pictionary'));
      await tester.pumpAndSettle();

      final jugar = find.widgetWithText(FilledButton, 'Jugar');
      await tester.ensureVisible(jugar);
      await tester.pumpAndSettle();
      await tester.tap(jugar);
      await tester.pumpAndSettle();

      // 1 género visible (Normal) → auto-select → fase pase del juego.
      expect(find.text('Pasá el teléfono al dibujante'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Continuar'), findsOneWidget);
    });

    testWidgets('back desde instrucciones vuelve al selector', (tester) async {
      await arrancarApp(tester, splashVisto: true);
      await navegarDesdeHome(tester, 'Jugar');
      await tester.tap(find.text('Pictionary'));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Elegí un juego'), findsOneWidget);
    });
  });
}