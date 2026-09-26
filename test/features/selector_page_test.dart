import 'package:flutter_test/flutter_test.dart';

import 'package:paco_game/core/contenido/entidades.dart';

import 'helpers.dart';

void main() {
  group('SelectorPage', () {
    testWidgets('muestra las 3 tarjetas con nombre y descripción', (tester) async {
      await arrancarApp(tester, splashVisto: true);
      await navegarDesdeHome(tester, 'Jugar');

      expect(find.text('Yo Nunca'), findsOneWidget);
      expect(find.text('Ruleta'), findsOneWidget);
      expect(find.text('Pictionary'), findsOneWidget);
      expect(find.textContaining('¿Quién lo hizo?'), findsOneWidget);
      expect(find.textContaining('Girás y te toca'), findsOneWidget);
      expect(find.textContaining('Dibujá y adiviná'), findsOneWidget);
    });

    testWidgets('juego con contenido → SnackBar "Próximamente" y no navega',
        (tester) async {
      await arrancarApp(tester, splashVisto: true);
      await navegarDesdeHome(tester, 'Jugar');

      await tester.tap(find.text('Yo Nunca'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Próximamente'), findsOneWidget);
      // Seguimos en el selector (no navegó a un juego).
      expect(find.text('Yo Nunca'), findsOneWidget);
    });

    testWidgets('juego sin cartas → badge "sin contenido" y no entra',
        (tester) async {
      final diagnostico = DiagnosticoContenido(
        contenidos: {
          'yo_nunca': const ContenidoJuego(
            juegoId: 'yo_nunca',
            generos: [Genero(nombre: 'Normal', cartas: ['A'])],
          ),
          'ruleta': const ContenidoJuego(
            juegoId: 'ruleta',
            generos: [Genero(nombre: 'Normal', cartas: ['C'])],
          ),
          // pictionary NO tiene cartas válidas → ausente de contenidos
        },
        errores: const [],
      );
      await arrancarApp(tester, splashVisto: true, diagnostico: diagnostico);
      await navegarDesdeHome(tester, 'Jugar');

      expect(find.text('sin contenido'), findsOneWidget);

      await tester.tap(find.text('Pictionary'));
      await tester.pumpAndSettle();

      // No navegó: seguimos en el selector.
      expect(find.text('sin contenido'), findsOneWidget);
    });
  });
}