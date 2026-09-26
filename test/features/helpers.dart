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
import 'package:paco_game/core/audio/sonido_provider.dart';
import 'package:paco_game/core/contenido/diagnostico.dart';
import 'package:paco_game/core/contenido/entidades.dart';

import '../core/audio/fakes.dart';

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
                  generos: [
                    Genero(
                      nombre: 'Normal',
                      cartas: ['D1', 'D2', 'D3', 'D4', 'D5', 'D6'],
                    ),
                  ],
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
///
/// Incluye los fakes de audio/hápticos (seam AH3): ningún widget test que
/// pueda llegar a una página de juego toca el plugin real.
Future<FakesAudio> arrancarApp(
  WidgetTester tester, {
  required bool splashVisto,
  List<ErrorContenido> errores = const [],
  DiagnosticoContenido? diagnostico,
}) async {
  return arrancarConAudio(
    tester,
    splashVisto: splashVisto,
    errores: errores,
    diagnostico: diagnostico,
  );
}

/// Fakes de audio/hápticos compartidos (6.1): registran cada llamada en
/// [llamadas] (strings) para assertar `sonido=false → 0 plays`,
/// `vibracion=false → 0 vibraciones`, fanfarria en onEnd, tick ≤10 s, etc.
class FakesAudio {
  FakesAudio();

  final ReproductorFake reproductor = ReproductorFake();
  final VibradorFake vibrador = VibradorFake();
}

/// Arranca la app completa con prefs in-memory presembradas (sonido/
/// vibracion configurables) y overrides de audio/hápticos con fakes.
///
/// Devuelve los fakes para assertar llamadas (nunca toca el plugin real).
Future<FakesAudio> arrancarConAudio(
  WidgetTester tester, {
  required bool splashVisto,
  bool sonido = true,
  bool vibracion = true,
  bool modoAlcohol = false,
  List<ErrorContenido> errores = const [],
  DiagnosticoContenido? diagnostico,
}) async {
  SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  final prefs = SharedPreferencesAsync();
  await prefs.setInt('ajustes.schemaVersion', 1);
  await prefs.setBool('ajustes.splashVisto', splashVisto);
  await prefs.setBool('ajustes.sonido', sonido);
  await prefs.setBool('ajustes.vibracion', vibracion);
  await prefs.setBool('ajustes.modoAlcohol', modoAlcohol);

  final fakes = FakesAudio();
  final bridge = BootBridge()
    ..actualizar(splashVisto: splashVisto, errores: errores);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bootBridgeProvider.overrideWithValue(bridge),
        ajustesRepositoryProvider.overrideWithValue(
          AjustesRepository(prefs: prefs),
        ),
        reproductorProvider.overrideWithValue(fakes.reproductor),
        vibradorProvider.overrideWithValue(fakes.vibrador),
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
                    generos: [
                      Genero(
                        nombre: 'Normal',
                        cartas: ['D1', 'D2', 'D3', 'D4', 'D5', 'D6'],
                      ),
                    ],
                  ),
                },
                errores: errores,
              ),
        ),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
  return fakes;
}

/// Navega hasta la ruta indicada tocando el camino real desde /home.
Future<void> navegarDesdeHome(WidgetTester tester, String textoBoton) async {
  await tester.tap(find.widgetWithText(FilledButton, textoBoton));
  await tester.pumpAndSettle();
}