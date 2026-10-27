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
import 'package:paco_game/features/home/presentation/home_page.dart';

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
      expect(find.text('PACO'), findsNothing);
    });

    testWidgets('splashVisto=true y sano → arranca directo en /home', (tester) async {
      final container = await arrancar(splashVisto: true);
      await pumpApp(tester, container);

      expect(find.text('PACO'), findsOneWidget);
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
      expect(find.text('PACO'), findsNothing);
    });

    testWidgets('flujo completo: Entendido → Home → Pictionary → Ajustes → Diagnóstico',
        (tester) async {
      final container = await arrancar(splashVisto: false);
      await pumpApp(tester, container);

      // Splash → Entendido → Home
      await tester.tap(find.widgetWithText(FilledButton, 'Entendido'));
      await tester.pumpAndSettle();
      expect(find.text('PACO'), findsOneWidget);

      // Home → instrucciones de Pictionary
      await tester.tap(find.byKey(HomeKeys.pictionary));
      await tester.pumpAndSettle();
      expect(find.text('Pictionary'), findsOneWidget);

      // Instrucciones → back → Home
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('PACO'), findsOneWidget);

      // Home → Ajustes (engranaje)
      await tester.tap(find.byKey(HomeKeys.ajustes));
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

    testWidgets('splash protege la ruta nueva: /ruleta/juego → /splash',
        (tester) async {
      final container = await arrancar(splashVisto: false);
      await pumpApp(tester, container);
      expect(find.widgetWithText(FilledButton, 'Entendido'), findsOneWidget);

      // Solicitar la ruta del juego directamente: el redirect la protege.
      container.read(routerProvider).go('/ruleta/juego');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Entendido'), findsOneWidget);
      expect(find.text('Ruleta'), findsNothing);
    });

    testWidgets('splash protege la ruta nueva: /pictionary/juego → /splash',
        (tester) async {
      final container = await arrancar(splashVisto: false);
      await pumpApp(tester, container);
      expect(find.widgetWithText(FilledButton, 'Entendido'), findsOneWidget);

      // Solicitar la ruta del juego directamente: el redirect la protege.
      container.read(routerProvider).go('/pictionary/juego');
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Entendido'), findsOneWidget);
      expect(find.text('Pasá el teléfono al dibujante'), findsNothing);
    });

    testWidgets('flujo M3: Home → /pictionary → [Jugar] → /pictionary/juego',
        (tester) async {
      final container = await arrancar(splashVisto: true);
      await pumpApp(tester, container);

      // Home → /pictionary (instrucciones)
      await tester.tap(find.byKey(HomeKeys.pictionary));
      await tester.pumpAndSettle();
      expect(find.text('Pictionary'), findsOneWidget);

      // [Jugar] → /pictionary/juego. El fake tiene 1 solo género visible
      // (Normal) → auto-select → fase pase [Continuar] (P9).
      final jugar = find.widgetWithText(FilledButton, 'Jugar');
      await tester.ensureVisible(jugar);
      await tester.pumpAndSettle();
      await tester.tap(jugar);
      await tester.pumpAndSettle();
      expect(find.text('Pasá el teléfono al dibujante'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Continuar'), findsOneWidget);
    });

    testWidgets('flujo M2: Home → /ruleta → [Jugar] → /ruleta/juego',
        (tester) async {
      final container = await arrancar(splashVisto: true);
      await pumpApp(tester, container);

      // Home → /ruleta (instrucciones)
      await tester.tap(find.byKey(HomeKeys.ruleta));
      await tester.pumpAndSettle();
      expect(find.text('Ruleta'), findsOneWidget);

      // [Jugar] → /ruleta/juego. El fake tiene 1 solo género visible
      // (Normal) → auto-select → rueda con [Girar] (RU8).
      final jugar = find.widgetWithText(FilledButton, 'Jugar');
      await tester.ensureVisible(jugar);
      await tester.pumpAndSettle();
      await tester.tap(jugar);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Girar'), findsOneWidget);
    });

    testWidgets('flujo M1: Home → /yo-nunca → [Jugar] → /yo-nunca/juego',
        (tester) async {
      final container = await arrancar(splashVisto: true);
      await pumpApp(tester, container);

      // Home → /yo-nunca (instrucciones)
      await tester.tap(find.byKey(HomeKeys.yoNunca));
      await tester.pumpAndSettle();
      expect(find.text('Yo nunca'), findsOneWidget);

      // [Jugar] → /yo-nunca/juego. El fake tiene 1 solo género (Normal):
      // la partida arranca boca abajo con el juramento (YN6).
      final jugar = find.widgetWithText(FilledButton, 'Jugar');
      await tester.ensureVisible(jugar);
      await tester.pumpAndSettle();
      await tester.tap(jugar);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('dorso_yo_nunca')), findsOneWidget);
      expect(
        find.text('Juro solemnemente que mis intenciones no son buenas.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Siguiente'), findsNothing);

      // tap → flip → frente con C3 + [Siguiente] (YN6).
      await tester.tap(find.byKey(const Key('carta_yo_nunca')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('frente_yo_nunca')), findsOneWidget);
      expect(find.text('Yo nunca nunca...'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Siguiente'), findsOneWidget);
    });
  });
}