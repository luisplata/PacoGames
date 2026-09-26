import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('RuletaInstruccionesPage', () {
    testWidgets('muestra título Ruleta, 3 bullets EXACTOS y "Qué necesitás"',
        (tester) async {
      await arrancarApp(tester, splashVisto: true);
      await navegarDesdeHome(tester, 'Jugar');
      await tester.tap(find.text('Ruleta'));
      await tester.pumpAndSettle();

      expect(find.text('Ruleta'), findsOneWidget);
      expect(
        find.text('Tocá [Girar] y esperá la animación: la ruleta elige por vos'),
        findsOneWidget,
      );
      expect(
        find.text('Leé el resultado en grande: no se repiten las últimas 5 finales'),
        findsOneWidget,
      );
      expect(
        find.text(
            'Si sale «volvé a girar»: turno salvado, pasás el turno y gira el siguiente'),
        findsOneWidget,
      );
      expect(find.text('Qué necesitás: nada, solo el teléfono'), findsOneWidget);
    });

    testWidgets('[Jugar] navega a /ruleta/juego (auto-select → [Girar])',
        (tester) async {
      await arrancarApp(tester, splashVisto: true);
      await navegarDesdeHome(tester, 'Jugar');
      await tester.tap(find.text('Ruleta'));
      await tester.pumpAndSettle();

      final jugar = find.widgetWithText(FilledButton, 'Jugar');
      await tester.ensureVisible(jugar);
      await tester.pumpAndSettle();
      await tester.tap(jugar);
      await tester.pumpAndSettle();

      // 1 género visible (Normal) → auto-select → rueda con [Girar], sin picker.
      expect(find.widgetWithText(FilledButton, 'Girar'), findsOneWidget);
      expect(find.text('Elegí un género'), findsNothing);
    });

    testWidgets('back desde instrucciones vuelve al selector', (tester) async {
      await arrancarApp(tester, splashVisto: true);
      await navegarDesdeHome(tester, 'Jugar');
      await tester.tap(find.text('Ruleta'));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Elegí un juego'), findsOneWidget);
    });
  });
}