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

const _normal = Genero(nombre: 'Normal', cartas: ['N1', 'N2', 'N3']);
const _picante = Genero(nombre: 'Picante', cartas: ['P1', 'P2']);

const _diagnosticoFake = DiagnosticoContenido(
  contenidos: {
    'yo_nunca': ContenidoJuego(juegoId: 'yo_nunca', generos: [_normal, _picante]),
    'ruleta': ContenidoJuego(
      juegoId: 'ruleta',
      generos: [Genero(nombre: 'Normal', cartas: ['R'])],
    ),
    'pictionary': ContenidoJuego(
      juegoId: 'pictionary',
      generos: [Genero(nombre: 'Normal', cartas: ['Q'])],
    ),
  },
  errores: [],
);

const _fraseKey = Key('frase_yo_nunca');
const _bannerTexto = 'Modo sin alcohol: los tragos se leen como prendas';
const _cartasNormales = ['N1', 'N2', 'N3'];

/// Arranca la app con prefs in-memory pre-sembradas (permite modoAlcohol
/// inicial sin pasar por la UI de Ajustes).
Future<void> arrancarConAjustes(
  WidgetTester tester, {
  required bool splashVisto,
  required bool modoAlcohol,
  DiagnosticoContenido? diagnostico,
}) async {
  SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  final prefs = SharedPreferencesAsync();
  await prefs.setInt('ajustes.schemaVersion', 1);
  await prefs.setBool('ajustes.splashVisto', splashVisto);
  await prefs.setBool('ajustes.modoAlcohol', modoAlcohol);
  await prefs.setBool('ajustes.sonido', true);
  await prefs.setBool('ajustes.vibracion', true);

  final bridge = BootBridge()
    ..actualizar(splashVisto: splashVisto, errores: const []);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bootBridgeProvider.overrideWithValue(bridge),
        ajustesRepositoryProvider.overrideWithValue(
          AjustesRepository(prefs: prefs),
        ),
        diagnosticoContenidoProvider.overrideWith(
          (ref) async => diagnostico ?? _diagnosticoFake,
        ),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Camino real: home → selector → Yo Nunca (instrucciones) → [Jugar] → juego.
Future<void> irAlJuego(
  WidgetTester tester, {
  bool modoAlcohol = false,
  DiagnosticoContenido? diagnostico,
}) async {
  await arrancarConAjustes(
    tester,
    splashVisto: true,
    modoAlcohol: modoAlcohol,
    diagnostico: diagnostico,
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Jugar'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Yo Nunca'));
  await tester.pumpAndSettle();
  await tocarBoton(tester, 'Jugar'); // [Jugar] de instrucciones → /yo-nunca/juego
}

/// Toca un FilledButton asegurando que esté visible (los botones de la
/// página de juego quedan bajo el pliegue en la surface 800x600 de test).
Future<void> tocarBoton(WidgetTester tester, String texto) async {
  final finder = find.widgetWithText(FilledButton, texto);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Frase visible en la carta actual (null si no hay carta: fin de mazo).
String? fraseActual(WidgetTester tester) {
  final finder = find.byKey(_fraseKey);
  if (finder.evaluate().isEmpty) return null;
  return tester.widget<Text>(finder).data;
}

void main() {
  group('YoNuncaJuegoPage', () {
    testWidgets('modoAlcohol=false → picker con Normal+Picante y sin banner',
        (tester) async {
      await irAlJuego(tester);

      expect(find.text('Elegí un género'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Picante'), findsOneWidget);
      expect(find.text(_bannerTexto), findsNothing);
    });

    testWidgets('modoAlcohol=true → auto-select Normal, sin picker, banner exacto',
        (tester) async {
      await irAlJuego(tester, modoAlcohol: true);

      expect(find.text('Elegí un género'), findsNothing);
      expect(find.text(_bannerTexto), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Siguiente'), findsOneWidget);
      expect(_cartasNormales, contains(fraseActual(tester)));
      // Normal tiene 3 cartas (< 5) → aviso de poco contenido, pero juega.
      expect(find.text('Poco contenido en este género'), findsOneWidget);
    });

    testWidgets('elegir género → frase + [Siguiente], juega igual, sin banner',
        (tester) async {
      await irAlJuego(tester);
      await tester.tap(find.text('Normal'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Siguiente'), findsOneWidget);
      expect(_cartasNormales, contains(fraseActual(tester)));
      expect(find.text('Poco contenido en este género'), findsOneWidget);
      expect(find.text(_bannerTexto), findsNothing);

      await tocarBoton(tester, 'Siguiente');
      expect(_cartasNormales, contains(fraseActual(tester)));
    });

    testWidgets('ciclo sin repetir hasta agotar → aviso fin de mazo',
        (tester) async {
      await irAlJuego(tester);
      await tester.tap(find.text('Normal'));
      await tester.pumpAndSettle();

      final vistas = <String>{fraseActual(tester)!};
      // N=3 cartas: tras la 3ra [Siguiente] se agota.
      for (var i = 0; i < 3; i++) {
        await tocarBoton(tester, 'Siguiente');
        final frase = fraseActual(tester);
        if (frase != null) {
          expect(vistas, isNot(contains(frase)), reason: 'sin repetir en el ciclo');
          vistas.add(frase);
        }
      }

      expect(find.text('Se acabaron las cartas: se mezclan de nuevo'),
          findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Mezclar de nuevo'), findsOneWidget);
      expect(vistas, {'N1', 'N2', 'N3'});
    });

    testWidgets('[Mezclar de nuevo] → nuevo ciclo sin errores (loop infinito)',
        (tester) async {
      await irAlJuego(tester);
      await tester.tap(find.text('Normal'));
      await tester.pumpAndSettle();

      // Agotar el mazo de 3 cartas.
      for (var i = 0; i < 3; i++) {
        await tocarBoton(tester, 'Siguiente');
      }
      expect(find.text('Se acabaron las cartas: se mezclan de nuevo'),
          findsOneWidget);

      await tocarBoton(tester, 'Mezclar de nuevo');
      expect(find.widgetWithText(FilledButton, 'Siguiente'), findsOneWidget);
      expect(_cartasNormales, contains(fraseActual(tester)));

      // Sigue jugando en el nuevo ciclo.
      await tocarBoton(tester, 'Siguiente');
      expect(_cartasNormales, contains(fraseActual(tester)));
    });

    testWidgets('salir mid-game → diálogo → cancelar conserva / confirmar descarta',
        (tester) async {
      await irAlJuego(tester);
      await tester.tap(find.text('Normal'));
      await tester.pumpAndSettle();

      // Cancelar conserva la partida exactamente donde estaba.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('¿Salir de la partida?'), findsOneWidget);
      await tester.tap(find.text('Seguir jugando'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Siguiente'), findsOneWidget);
      expect(_cartasNormales, contains(fraseActual(tester)));

      // Confirmar → pop a instrucciones (D6) → back al selector.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salir'));
      await tester.pumpAndSettle();
      expect(find.text('Yo nunca'), findsOneWidget); // instrucciones
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Elegí un juego'), findsOneWidget); // selector

      // Re-entrar → estado descartado (autoDispose) → picker de nuevo.
      await tester.tap(find.text('Yo Nunca'));
      await tester.pumpAndSettle();
      await tocarBoton(tester, 'Jugar');
      expect(find.text('Elegí un género'), findsOneWidget);
    });

    testWidgets('solo género Picante + modoAlcohol → mensaje defensivo sin crash',
        (tester) async {
      const diagnostico = DiagnosticoContenido(
        contenidos: {
          'yo_nunca': ContenidoJuego(
            juegoId: 'yo_nunca',
            generos: [Genero(nombre: 'Picante', cartas: ['P1', 'P2'])],
          ),
        },
        errores: [],
      );
      await irAlJuego(tester, modoAlcohol: true, diagnostico: diagnostico);

      expect(find.text('Sin géneros disponibles en este modo'), findsOneWidget);
      expect(find.text('Elegí un género'), findsNothing);
    });
  });
}