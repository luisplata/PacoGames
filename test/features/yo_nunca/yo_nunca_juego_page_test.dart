import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paco_game/core/contenido/entidades.dart';

import 'package:paco_game/features/home/presentation/home_page.dart';

import '../helpers.dart';

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
const _pocoContenido = 'Poco contenido en este nivel';
const _sinCartas = 'Sin cartas disponibles en este nivel.';
const _cartasNormales = ['N1', 'N2', 'N3'];

/// Camino real: home → Yo Nunca (reglas) → nivel → [Jugar] → juego.
/// El nivel se elige en reglas (el picker in-game ya no existe, D5).
Future<FakesAudio> irAlJuego(
  WidgetTester tester, {
  String nivel = 'Normal',
  bool modoAlcohol = false,
  bool sonido = true,
  bool vibracion = true,
  DiagnosticoContenido? diagnostico,
}) async {
  final fakes = await arrancarConAudio(
    tester,
    splashVisto: true,
    modoAlcohol: modoAlcohol,
    sonido: sonido,
    vibracion: vibracion,
    diagnostico: diagnostico ?? _diagnosticoFake,
  );
  await tester.tap(find.byKey(HomeKeys.yoNunca));
  await tester.pumpAndSettle();
  if (nivel != 'Normal') {
    await elegirNivelYoNunca(tester, nivel);
  }
  await tocarBoton(tester, 'Jugar'); // reglas → /yo-nunca/juego
  return fakes;
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
    testWidgets('sin picker: arranca directo con el nivel Normal', (tester) async {
      await irAlJuego(tester);

      expect(find.text('Elegí un género'), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.text('Nivel: Normal'), findsOneWidget);
      expect(_cartasNormales, contains(fraseActual(tester)));
      expect(find.widgetWithText(FilledButton, 'Siguiente'), findsOneWidget);
      // 3 cartas < 5 → aviso con la copy nueva (C15).
      expect(find.text(_pocoContenido), findsOneWidget);
      expect(find.text('Poco contenido en este género'), findsNothing);
      expect(find.text(_bannerTexto), findsNothing);
    });

    testWidgets('nivel Picante → aditivo: Normal + Picante, sin repetir',
        (tester) async {
      await irAlJuego(tester, nivel: 'Picante');

      expect(find.text('Nivel: Picante'), findsOneWidget);
      final vistas = <String>{fraseActual(tester)!};
      for (var i = 0; i < 4; i++) {
        await tocarBoton(tester, 'Siguiente');
        vistas.add(fraseActual(tester)!);
      }

      expect(vistas, {'N1', 'N2', 'N3', 'P1', 'P2'});
      // 5 cartas no disparan el aviso de poco contenido.
      expect(find.text(_pocoContenido), findsNothing);
    });

    testWidgets('nivel Normal no incluye cartas Picante', (tester) async {
      await irAlJuego(tester);

      final vistas = <String>{fraseActual(tester)!};
      for (var i = 0; i < 2; i++) {
        await tocarBoton(tester, 'Siguiente');
        vistas.add(fraseActual(tester)!);
      }

      expect(vistas, {'N1', 'N2', 'N3'});
      expect(vistas, isNot(contains('P1')));
      expect(vistas, isNot(contains('P2')));

      // Una más agota el mazo Normal (3 cartas).
      await tocarBoton(tester, 'Siguiente');
      expect(find.text('Se acabaron las cartas: se mezclan de nuevo'),
          findsOneWidget);
    });

    testWidgets('modo sin alcohol → banner y mazo solo Normal aunque se pida '
        'Picante', (tester) async {
      await irAlJuego(tester, nivel: 'Picante', modoAlcohol: true);

      expect(find.text(_bannerTexto), findsOneWidget);
      // Nivel efectivo sober = Normal.
      expect(find.text('Nivel: Normal'), findsOneWidget);

      final vistas = <String>{fraseActual(tester)!};
      for (var i = 0; i < 2; i++) {
        await tocarBoton(tester, 'Siguiente');
        vistas.add(fraseActual(tester)!);
      }
      expect(vistas, {'N1', 'N2', 'N3'});
    });

    testWidgets('[Mezclar de nuevo] → nuevo ciclo Normal sin errores',
        (tester) async {
      await irAlJuego(tester);

      for (var i = 0; i < 3; i++) {
        await tocarBoton(tester, 'Siguiente');
      }
      expect(find.text('Se acabaron las cartas: se mezclan de nuevo'),
          findsOneWidget);

      await tocarBoton(tester, 'Mezclar de nuevo');
      expect(find.widgetWithText(FilledButton, 'Siguiente'), findsOneWidget);
      expect(_cartasNormales, contains(fraseActual(tester)));
    });

    testWidgets('[Siguiente]/[Mezclar de nuevo] → click y carta (AH6)',
        (tester) async {
      final fakes = await irAlJuego(tester);

      // Arranque directo: la carta ya está a la vista, sin SFX de carta.
      expect(fakes.reproductor.llamadas, isEmpty);

      await tocarBoton(tester, 'Siguiente');
      expect(fakes.reproductor.llamadas.where((l) => l == 'click'), hasLength(1));
      expect(fakes.reproductor.llamadas.where((l) => l == 'carta'), hasLength(1));

      // Agotar (2 siguientes más; la última deja el mazo agotado) y mezclar.
      await tocarBoton(tester, 'Siguiente');
      await tocarBoton(tester, 'Siguiente');
      expect(fakes.reproductor.llamadas.where((l) => l == 'click'), hasLength(3));
      expect(fakes.reproductor.llamadas.where((l) => l == 'carta'), hasLength(2));

      await tocarBoton(tester, 'Mezclar de nuevo');
      expect(fakes.reproductor.llamadas.where((l) => l == 'click'), hasLength(4));
      expect(fakes.reproductor.llamadas.where((l) => l == 'carta'), hasLength(3));
    });

    testWidgets('sonido=false y vibracion=false → 0 llamadas a audio y '
        'hápticos en toda la partida (AH4/AH5/A2)', (tester) async {
      final fakes = await irAlJuego(tester, sonido: false, vibracion: false);

      for (var i = 0; i < 3; i++) {
        await tocarBoton(tester, 'Siguiente');
      }
      await tocarBoton(tester, 'Mezclar de nuevo');

      expect(fakes.reproductor.llamadas, isEmpty);
      expect(fakes.vibrador.llamadas, isEmpty);
    });

    testWidgets('salir mid-game → diálogo → cancelar conserva / confirmar '
        'descarta', (tester) async {
      await irAlJuego(tester);

      // Cancelar conserva la partida exactamente donde estaba.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('¿Salir de la partida?'), findsOneWidget);
      await tester.tap(find.text('Seguir jugando'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Siguiente'), findsOneWidget);
      expect(_cartasNormales, contains(fraseActual(tester)));

      // Confirmar → vuelve a reglas → back al Home.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salir'));
      await tester.pumpAndSettle();
      expect(find.text('Yo nunca'), findsOneWidget); // reglas
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('PACO'), findsOneWidget); // Home

      // Re-entrar → estado descartado (autoDispose) → arranca directo Normal.
      await tester.tap(find.byKey(HomeKeys.yoNunca));
      await tester.pumpAndSettle();
      await tocarBoton(tester, 'Jugar');
      expect(find.text('Elegí un género'), findsNothing);
      expect(find.text('Nivel: Normal'), findsOneWidget);
      expect(_cartasNormales, contains(fraseActual(tester)));
    });

    testWidgets('mazo vacío (solo Picante + modo sin alcohol) → C16 sin crash',
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
      await irAlJuego(
        tester,
        modoAlcohol: true,
        diagnostico: diagnostico,
      );

      expect(find.text(_sinCartas), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Siguiente'), findsNothing);
      expect(find.text(_pocoContenido), findsNothing);
      expect(find.text('Elegí un género'), findsNothing);
    });
  });
}
