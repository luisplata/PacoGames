import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('YoNuncaInstruccionesPage', () {
    Future<void> irAInstrucciones(WidgetTester tester) async {
      await arrancarApp(tester, splashVisto: true);
      await navegarDesdeHome(tester, 'Jugar'); // → selector
      await tester.tap(find.text('Yo Nunca')); // → /yo-nunca
      await tester.pumpAndSettle();
    }

    testWidgets('muestra título, 3 bullets exactos y qué necesitás',
        (tester) async {
      await irAInstrucciones(tester);

      expect(find.text('Yo nunca'), findsOneWidget);
      expect(
        find.text(
          'Elegí el género: barajamos las cartas y no se repiten hasta agotar el mazo',
        ),
        findsOneWidget,
      );
      expect(find.text('Pasá el teléfono y leé la frase en voz alta'),
          findsOneWidget);
      expect(
        find.text('Si la hiciste, ¡traguito! Si no, pasá el teléfono'),
        findsOneWidget,
      );
      expect(find.text('Qué necesitás: nada, solo el teléfono'), findsOneWidget);
    });

    testWidgets('[Jugar] navega a /yo-nunca/juego', (tester) async {
      await irAInstrucciones(tester);

      // El botón queda bajo el pliegue en la surface de test (800x600).
      final jugar = find.widgetWithText(FilledButton, 'Jugar');
      await tester.ensureVisible(jugar);
      await tester.pumpAndSettle();
      await tester.tap(jugar);
      await tester.pumpAndSettle();

      // Con el fake por defecto (1 género visible) el juego auto-selecciona
      // y muestra la carta con [Siguiente] (YN4).
      expect(find.widgetWithText(FilledButton, 'Siguiente'), findsOneWidget);
    });

    testWidgets('back desde instrucciones vuelve al selector', (tester) async {
      await irAInstrucciones(tester);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Elegí un juego'), findsOneWidget);
    });
  });
}