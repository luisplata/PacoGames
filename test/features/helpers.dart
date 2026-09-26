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

/// Widget de la app con overrides (patrón del design):
/// - bridge con boot ya completado (el fire-and-forget real no corre)
/// - repo de ajustes con prefs in-memory
/// - diagnóstico con contenido fake (no toca assets reales)
///
/// Devuelve el `ProviderScope` listo para `tester.pumpWidget`.
Widget appConOverrides({
  required bool splashVisto,
  List<ErrorContenido> errores = const [],
  DiagnosticoContenido? diagnostico,
}) {
  final bridge = BootBridge()
    ..actualizar(splashVisto: splashVisto, errores: errores);
  return ProviderScope(
    overrides: [
      bootBridgeProvider.overrideWithValue(bridge),
      ajustesRepositoryProvider.overrideWithValue(
        AjustesRepository(prefs: SharedPreferencesAsync()),
      ),
      // El provider de diagnóstico es la fuente real de errores (el bridge
      // los copia). Si el test pasa errores, el fake los devuelve también.
      diagnosticoContenidoProvider.overrideWith(
        (ref) async =>
            diagnostico ??
            DiagnosticoContenido(
              contenidos: {
                'yo_nunca': const ContenidoJuego(
                  juegoId: 'yo_nunca',
                  generos: [Genero(nombre: 'Normal', cartas: ['A', 'B'])],
                ),
                'ruleta': const ContenidoJuego(
                  juegoId: 'ruleta',
                  generos: [Genero(nombre: 'Normal', cartas: ['C'])],
                ),
                'pictionary': const ContenidoJuego(
                  juegoId: 'pictionary',
                  generos: [Genero(nombre: 'Normal', cartas: ['D'])],
                ),
              },
              errores: errores,
            ),
      ),
    ],
    child: const App(),
  );
}

/// Arranca la app completa con overrides y prefs in-memory limpias.
Future<void> arrancarApp(
  WidgetTester tester, {
  required bool splashVisto,
  List<ErrorContenido> errores = const [],
  DiagnosticoContenido? diagnostico,
}) async {
  SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  await tester.pumpWidget(
    appConOverrides(
      splashVisto: splashVisto,
      errores: errores,
      diagnostico: diagnostico,
    ),
  );
  await tester.pumpAndSettle();
}

/// Navega hasta la ruta indicada tocando el camino real desde /home.
Future<void> navegarDesdeHome(WidgetTester tester, String textoBoton) async {
  await tester.tap(find.widgetWithText(FilledButton, textoBoton));
  await tester.pumpAndSettle();
}