import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';
import 'package:paco_game/features/home/presentation/home_page.dart';

void main() {
  group('PictionaryInstruccionesPage', () {
    testWidgets('muestra título Pictionary, 3 bullets EXACTOS y "Qué necesitás"',
        (tester) async {
      await arrancarApp(tester, splashVisto: true);
      await navegarDesdeHome(tester, find.byKey(HomeKeys.pictionary));

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
      await navegarDesdeHome(tester, find.byKey(HomeKeys.pictionary));

      final jugar = find.widgetWithText(FilledButton, 'Jugar');
      await tester.ensureVisible(jugar);
      await tester.pumpAndSettle();
      await tester.tap(jugar);
      await tester.pumpAndSettle();

      // 1 género visible (Normal) → auto-select → fase pase del juego.
      expect(find.text('Pasá el teléfono al dibujante'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Continuar'), findsOneWidget);
    });

    testWidgets('back desde instrucciones vuelve al Home', (tester) async {
      await arrancarApp(tester, splashVisto: true);
      await navegarDesdeHome(tester, find.byKey(HomeKeys.pictionary));

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('PACO'), findsOneWidget);
    });
  });
}