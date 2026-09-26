import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:paco_game/app/app.dart';
import 'package:paco_game/app/boot.dart';
import 'package:paco_game/core/ajustes/ajustes_providers.dart';
import 'package:paco_game/core/ajustes/ajustes_repository.dart';
import 'package:paco_game/core/contenido/diagnostico.dart';
import 'package:paco_game/core/contenido/entidades.dart';

import 'helpers.dart';

void main() {
  group('SplashPage', () {
    testWidgets('primera vez (splashVisto=false) → aviso +18 y botón Entendido',
        (tester) async {
      await arrancarApp(tester, splashVisto: false);

      expect(find.text('PacoGame'), findsOneWidget);
      expect(find.textContaining('18'), findsOneWidget);
      expect(find.textContaining('alcohol'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Entendido'), findsOneWidget);
    });

    testWidgets('[Entendido] persiste el flag y navega a /home', (tester) async {
      await arrancarApp(tester, splashVisto: false);

      await tester.tap(find.widgetWithText(FilledButton, 'Entendido'));
      await tester.pumpAndSettle();

      // Llegamos al Home: botón Jugar visible, splash ya no está.
      expect(find.text('Jugar'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Entendido'), findsNothing);
    });

    testWidgets('splashVisto=true → salta el splash y va directo a /home',
        (tester) async {
      await arrancarApp(tester, splashVisto: true);

      expect(find.text('Jugar'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Entendido'), findsNothing);
    });

    testWidgets(
        'REGRESIÓN: boot async completa después del primer build → el spinner '
        'desaparece y se muestra el contenido (bridge null → actualizar)',
        (tester) async {
      // Reproduce el bug real: el bridge empieza en null (boot cargando) y
      // recién después del primer build el fire-and-forget del boot lo
      // actualiza. Sin ListenableBuilder el widget nunca se reconstruye y
      // el spinner queda eterno.
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      final bridge = BootBridge(); // splashVisto == null

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bootBridgeProvider.overrideWithValue(bridge),
            ajustesRepositoryProvider.overrideWithValue(
              AjustesRepository(prefs: SharedPreferencesAsync()),
            ),
            diagnosticoContenidoProvider.overrideWith(
              (ref) async => const DiagnosticoContenido(contenidos: {}, errores: []),
            ),
          ],
          child: const App(),
        ),
      );

      // Mientras el boot carga: spinner.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Entendido'), findsNothing);

      // El boot completa (equivale al bridge.actualizar del fire-and-forget).
      bridge.actualizar(splashVisto: false, errores: const []);
      await tester.pump();

      // El ListenableBuilder re-construyó: spinner fuera, contenido visible.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Entendido'), findsOneWidget);
    });
  });
}