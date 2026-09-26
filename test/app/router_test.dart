import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:paco_game/app/app.dart';
import 'package:paco_game/app/boot.dart';
import 'package:paco_game/app/router.dart';
import 'package:paco_game/core/ajustes/ajustes_providers.dart';
import 'package:paco_game/core/ajustes/ajustes_repository.dart';
import 'package:paco_game/core/contenido/diagnostico.dart';
import 'package:paco_game/core/contenido/entidades.dart';

void main() {
  Future<ProviderContainer> arrancar({
    required bool splashVisto,
    List<ErrorContenido> errores = const [],
  }) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final bridge = BootBridge()..actualizar(splashVisto: splashVisto, errores: errores);
    final container = ProviderContainer(
      overrides: [
        bootBridgeProvider.overrideWithValue(bridge),
        ajustesRepositoryProvider.overrideWithValue(
          AjustesRepository(prefs: SharedPreferencesAsync()),
        ),
        // El bridge copia los errores del provider: el fake los devuelve
        // igual que el bridge los recibe (consistencia redirect ↔ página).
        diagnosticoContenidoProvider.overrideWith(
          (ref) async => DiagnosticoContenido(
            contenidos: {
              'yo_nunca': const ContenidoJuego(
                juegoId: 'yo_nunca',
                generos: [Genero(nombre: 'Normal', cartas: ['A'])],
              ),
              'ruleta': const ContenidoJuego(
                juegoId: 'ruleta',
                generos: [Genero(nombre: 'Normal', cartas: ['B'])],
              ),
              'pictionary': const ContenidoJuego(
                juegoId: 'pictionary',
                generos: [Genero(nombre: 'Normal', cartas: ['C'])],
              ),
            },
            errores: errores,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> pumpApp(WidgetTester tester, ProviderContainer container) async {
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const App()));
    await tester.pumpAndSettle();
  }

  group('router redirect (R1-R2)', () {
    testWidgets('splashVisto=false → arranca en /splash', (tester) async {
      final container = await arrancar(splashVisto: false);
      await pumpApp(tester, container);

      expect(find.widgetWithText(FilledButton, 'Entendido'), findsOneWidget);
      expect(find.text('Jugar'), findsNothing);
    });

    testWidgets('splashVisto=true y sano → arranca directo en /home', (tester) async {
      final container = await arrancar(splashVisto: true);
      await pumpApp(tester, container);

      expect(find.text('Jugar'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Entendido'), findsNothing);
    });

    testWidgets('splashVisto=true con errores → arranca en /diagnostico',
        (tester) async {
      final container = await arrancar(
        splashVisto: true,
        errores: const [
          ErrorContenido(archivo: 'ruleta.json', linea: 1, mensaje: 'error de sintaxis'),
        ],
      );
      await pumpApp(tester, container);

      expect(find.textContaining('ruleta.json:1'), findsOneWidget);
      expect(find.text('Jugar'), findsNothing);
    });

    testWidgets('flujo completo: Entendido → Home → Selector → Ajustes → Diagnóstico',
        (tester) async {
      final container = await arrancar(splashVisto: false);
      await pumpApp(tester, container);

      // Splash → Entendido → Home
      await tester.tap(find.widgetWithText(FilledButton, 'Entendido'));
      await tester.pumpAndSettle();
      expect(find.text('Jugar'), findsOneWidget);

      // Home → Selector
      await tester.tap(find.widgetWithText(FilledButton, 'Jugar'));
      await tester.pumpAndSettle();
      expect(find.text('Yo Nunca'), findsOneWidget);
      expect(find.text('Ruleta'), findsOneWidget);
      expect(find.text('Pictionary'), findsOneWidget);

      // Selector → back → Home
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Jugar'), findsOneWidget);

      // Home → Ajustes
      await tester.tap(find.widgetWithText(FilledButton, 'Ajustes'));
      await tester.pumpAndSettle();
      expect(find.text('Sonido'), findsOneWidget);

      // Ajustes → Diagnóstico
      await tester.tap(find.text('Diagnóstico'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Todo en orden'), findsOneWidget);
    });

    testWidgets('rutas nuevas protegidas por splash: /yo-nunca/juego → /splash',
        (tester) async {
      final container = await arrancar(splashVisto: false);
      await pumpApp(tester, container);
      expect(find.widgetWithText(FilledButton, 'Entendido'), findsOneWidget);

      // Solicitar la ruta del juego directamente: el redirect la protege.
      container.read(routerProvider).go('/yo-nunca/juego');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Entendido'), findsOneWidget);
      expect(find.text('Yo nunca'), findsNothing);
    });

    testWidgets('flujo M1: Selector → /yo-nunca → [Jugar] → /yo-nunca/juego',
        (tester) async {
      final container = await arrancar(splashVisto: true);
      await pumpApp(tester, container);

      // Home → Selector
      await tester.tap(find.widgetWithText(FilledButton, 'Jugar'));
      await tester.pumpAndSettle();
      expect(find.text('Yo Nunca'), findsOneWidget);

      // Selector → /yo-nunca (instrucciones)
      await tester.tap(find.text('Yo Nunca'));
      await tester.pumpAndSettle();
      expect(find.text('Yo nunca'), findsOneWidget);

      // [Jugar] → /yo-nunca/juego. El fake tiene 1 solo género visible
      // (Normal) → auto-select → carta con [Siguiente] (YN4).
      final jugar = find.widgetWithText(FilledButton, 'Jugar');
      await tester.ensureVisible(jugar);
      await tester.pumpAndSettle();
      await tester.tap(jugar);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Siguiente'), findsOneWidget);
    });
  });
}