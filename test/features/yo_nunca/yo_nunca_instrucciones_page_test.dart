import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';
import 'package:paco_game/features/home/presentation/home_page.dart';
import 'package:paco_game/features/yo_nunca/application/carta_yo_nunca.dart';

const _c4nivel = 'Nivel';
const _c5normal = 'Normal';
const _c5picante = 'Picante';
const _c6 = 'Normal usa solo las cartas normales.';
const _c7 = 'Picante suma las cartas picantes a las normales.';
const _c8 =
    'Modo sin alcohol activo: Picante no está disponible. Desactivalo en Ajustes.';
const _c9 =
    'Elegí el nivel: barajamos las cartas y no se repiten hasta agotar el mazo';

void main() {
  group('YoNuncaInstruccionesPage', () {
    Future<void> irAInstrucciones(
      WidgetTester tester, {
      bool modoAlcohol = false,
    }) async {
      // Siempre explícito: el default de la app es sobrio (A3), y estos
      // tests de nivel necesitan alcohol salvo el caso sober.
      await arrancarConAudio(
        tester,
        splashVisto: true,
        modoAlcohol: modoAlcohol,
      );
      await navegarDesdeHome(tester, find.byKey(HomeKeys.yoNunca));
    }

    SegmentedButton<NivelYoNunca> segmented(WidgetTester tester) =>
        tester.widget<SegmentedButton<NivelYoNunca>>(
          find.byType(SegmentedButton<NivelYoNunca>),
        );

    testWidgets('muestra título, 3 bullets exactos y qué necesitás',
        (tester) async {
      await irAInstrucciones(tester);

      expect(find.text('Yo nunca'), findsOneWidget);
      expect(find.text(_c9), findsOneWidget);
      expect(find.text('Pasá el teléfono y leé la frase en voz alta'),
          findsOneWidget);
      expect(
        find.text('Si la hiciste, ¡traguito! Si no, pasá el teléfono'),
        findsOneWidget,
      );
      expect(find.text('Qué necesitás: nada, solo el teléfono'), findsOneWidget);
      // El bullet viejo de género ya no existe.
      expect(
        find.textContaining('Elegí el género'),
        findsNothing,
      );
    });

    testWidgets('bloque Nivel: default Normal + C6', (tester) async {
      await irAInstrucciones(tester);

      expect(find.text(_c4nivel), findsOneWidget);
      expect(find.text(_c5normal), findsOneWidget);
      expect(find.text(_c5picante), findsOneWidget);
      expect(segmented(tester).selected, {NivelYoNunca.normal});
      expect(find.text(_c6), findsOneWidget);
      expect(find.text(_c7), findsNothing);
      expect(find.text(_c8), findsNothing);
    });

    testWidgets('elegir Picante → nota C7 y queda seleccionado', (tester) async {
      await irAInstrucciones(tester);

      await elegirNivelYoNunca(tester, 'Picante');

      expect(segmented(tester).selected, {NivelYoNunca.picante});
      expect(find.text(_c7), findsOneWidget);
      expect(find.text(_c6), findsNothing);
    });

    testWidgets('[Jugar] conserva Picante en el juego y al volver',
        (tester) async {
      await irAInstrucciones(tester);
      await elegirNivelYoNunca(tester, 'Picante');

      final jugar = find.widgetWithText(FilledButton, 'Jugar');
      await tester.ensureVisible(jugar);
      await tester.pumpAndSettle();
      await tester.tap(jugar);
      await tester.pumpAndSettle();

      // YN3: el nivel sobrevive el push (chip con el nivel efectivo).
      expect(find.text('Nivel: Picante'), findsOneWidget);

      // Volver al juego → reglas conserva Picante (la página sigue montada).
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('¿Salir de la partida?'), findsOneWidget);
      await tester.tap(find.text('Salir'));
      await tester.pumpAndSettle();

      expect(find.text(_c7), findsOneWidget);
      expect(segmented(tester).selected, {NivelYoNunca.picante});
    });

    testWidgets('modo sin alcohol → Picante deshabilitado + C8', (tester) async {
      await irAInstrucciones(tester, modoAlcohol: true);

      expect(find.text(_c8), findsOneWidget);
      expect(find.text(_c6), findsNothing);
      expect(find.text(_c7), findsNothing);
      expect(segmented(tester).segments.last.enabled, isFalse);
      expect(segmented(tester).selected, {NivelYoNunca.normal});

      // Tocar el segmento deshabilitado no cambia la selección.
      await elegirNivelYoNunca(tester, 'Picante');
      expect(segmented(tester).selected, {NivelYoNunca.normal});
      expect(find.text(_c8), findsOneWidget);
      expect(find.text(_c7), findsNothing);
    });

    testWidgets('back desde instrucciones vuelve al Home', (tester) async {
      await irAInstrucciones(tester);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('PACO'), findsOneWidget);
    });
  });
}
