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

    testWidgets('Yo Nunca navega a /yo-nunca (sin snackbar)', (tester) async {
      await arrancarApp(tester, splashVisto: true);
      await navegarDesdeHome(tester, 'Jugar');

      await tester.tap(find.text('Yo Nunca'));
      await tester.pumpAndSettle();

      // Instrucciones de Yo Nunca visibles; NO hay snackbar.
      expect(find.text('Yo nunca'), findsOneWidget);
      expect(find.textContaining('Próximamente'), findsNothing);
    });

    testWidgets('Ruleta y Pictionary → SnackBar "Próximamente (M2-M3)"',
        (tester) async {
      await arrancarApp(tester, splashVisto: true);
      await navegarDesdeHome(tester, 'Jugar');

      await tester.tap(find.text('Ruleta'));
      await tester.pumpAndSettle();
      expect(find.text('Próximamente (M2-M3)'), findsOneWidget);
      // Seguimos en el selector.
      expect(find.text('Ruleta'), findsOneWidget);

      // Dejar expirar el snackbar antes del próximo tap.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pictionary'));
      await tester.pumpAndSettle();
      expect(find.text('Próximamente (M2-M3)'), findsOneWidget);
      expect(find.text('Pictionary'), findsOneWidget);
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