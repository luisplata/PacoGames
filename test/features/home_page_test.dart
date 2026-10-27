import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paco_game/features/home/presentation/home_page.dart';

import 'helpers.dart';

void main() {
  group('HomePage', () {
    testWidgets('muestra título, los 3 juegos, ajustes y footer', (
      tester,
    ) async {
      await arrancarApp(tester, splashVisto: true);

      expect(find.text('PACO'), findsOneWidget);
      expect(find.text('Previas Argentinas Co'), findsOneWidget);

      expect(find.byKey(HomeKeys.yoNunca), findsOneWidget);
      expect(find.byKey(HomeKeys.ruleta), findsOneWidget);
      expect(find.byKey(HomeKeys.pictionary), findsOneWidget);

      expect(find.byKey(HomeKeys.ajustes), findsOneWidget);
      expect(find.byKey(HomeKeys.googlePlay), findsOneWidget);
      expect(find.byKey(HomeKeys.instagram), findsOneWidget);
      expect(find.byKey(HomeKeys.sonido), findsOneWidget);
      expect(find.byKey(HomeKeys.equipo), findsOneWidget);

      expect(find.textContaining('v0.1.0'), findsOneWidget);
    });

    testWidgets('cada botón abre las instrucciones de su juego', (
      tester,
    ) async {
      await arrancarApp(tester, splashVisto: true);

      await tester.tap(find.byKey(HomeKeys.yoNunca));
      await tester.pumpAndSettle();
      expect(find.text('Yo nunca'), findsOneWidget);
    });

    testWidgets('Ruleta abre sus instrucciones', (tester) async {
      await arrancarApp(tester, splashVisto: true);

      await tester.tap(find.byKey(HomeKeys.ruleta));
      await tester.pumpAndSettle();
      expect(find.text('Ruleta'), findsOneWidget);
    });

    testWidgets('Pictionary abre sus instrucciones', (tester) async {
      await arrancarApp(tester, splashVisto: true);

      await tester.tap(find.byKey(HomeKeys.pictionary));
      await tester.pumpAndSettle();
      expect(find.text('Pictionary'), findsOneWidget);
    });

    testWidgets('[Ajustes] abre los ajustes desde el engranaje', (
      tester,
    ) async {
      await arrancarApp(tester, splashVisto: true);

      await navegarDesdeHome(tester, find.byKey(HomeKeys.ajustes));

      expect(find.text('Sonido'), findsOneWidget);
    });

    testWidgets('el ícono de sonido alterna el estado', (tester) async {
      await arrancarApp(tester, splashVisto: true);

      expect(find.byTooltip('Silenciar'), findsOneWidget);

      await tester.tap(find.byKey(HomeKeys.sonido));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Activar sonido'), findsOneWidget);
    });

    testWidgets('el botón usa la variante presionada mientras se toca', (
      tester,
    ) async {
      await arrancarApp(tester, splashVisto: true);

      String? assetDelBoton() {
        final imagen = tester.widget<Image>(
          find.descendant(
            of: find.byKey(HomeKeys.yoNunca),
            matching: find.byType(Image),
          ),
        );
        return (imagen.image as AssetImage).assetName;
      }

      expect(assetDelBoton(), 'assets/images/home_yo_nunca.png');

      final gesto = await tester.startGesture(
        tester.getCenter(find.byKey(HomeKeys.yoNunca)),
      );
      // El tap compite con el scroll: onTapDown se resuelve al vencer el
      // deadline del reconocedor (~100 ms).
      await tester.pump(const Duration(milliseconds: 200));

      expect(assetDelBoton(), 'assets/images/home_yo_nunca_press.png');

      // Cancelar: vuelve al estado normal sin navegar.
      await gesto.cancel();
      await tester.pumpAndSettle();

      expect(assetDelBoton(), 'assets/images/home_yo_nunca.png');
    });

    testWidgets('el ícono de equipo abre el diálogo del estudio', (
      tester,
    ) async {
      await arrancarApp(tester, splashVisto: true);

      await tester.tap(find.byKey(HomeKeys.equipo));
      await tester.pumpAndSettle();

      expect(find.text('Bellseboss'), findsOneWidget);
      expect(find.text('Conocer el equipo'), findsOneWidget);

      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();

      expect(find.text('Conocer el equipo'), findsNothing);
    });
  });
}
