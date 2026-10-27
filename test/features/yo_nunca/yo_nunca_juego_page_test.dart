import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paco_game/core/contenido/entidades.dart';
import 'package:paco_game/features/home/presentation/home_page.dart';

import '../helpers.dart';

const _normal = Genero(nombre: 'Normal', cartas: ['N1', 'N2', 'N3']);
const _picante = Genero(nombre: 'Picante', cartas: ['P1', 'P2']);

const _diagnosticoFake = DiagnosticoContenido(
  contenidos: {
    'yo_nunca': ContenidoJuego(
      juegoId: 'yo_nunca',
      generos: [_normal, _picante],
    ),
    'ruleta': ContenidoJuego(
      juegoId: 'ruleta',
      generos: [
        Genero(nombre: 'Normal', cartas: ['R']),
      ],
    ),
    'pictionary': ContenidoJuego(
      juegoId: 'pictionary',
      generos: [
        Genero(nombre: 'Normal', cartas: ['Q']),
      ],
    ),
  },
  errores: [],
);

const _c1 = 'Juro solemnemente que mis intenciones no son buenas.';
const _c2 = 'Tocá para revelar';
const _c3 = 'Yo nunca nunca...';
const _c13 = 'Se acabaron las cartas: se mezclan de nuevo';
const _c15 = 'Poco contenido en este nivel';
const _c16 = 'Sin cartas disponibles en este nivel.';
const _bannerTexto = 'Modo sin alcohol: los tragos se leen como prendas';
const _cartasNormales = ['N1', 'N2', 'N3'];

const _fraseKey = Key('frase_yo_nunca');
const _cartaKey = Key('carta_yo_nunca');

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

/// Toca un FilledButton asegurando que esté visible.
Future<void> tocarBoton(WidgetTester tester, String texto) async {
  final finder = find.widgetWithText(FilledButton, texto);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Tap sobre la carta boca abajo y deja terminar el flip (400 ms).
Future<void> revelar(WidgetTester tester) async {
  await tester.tap(find.byKey(_cartaKey));
  await tester.pumpAndSettle();
}

bool estaOculta(WidgetTester tester) =>
    find.byKey(const Key('dorso_yo_nunca')).evaluate().isNotEmpty;

/// Frase visible en la carta revelada (null si no hay carta / sigue oculta).
String? fraseActual(WidgetTester tester) {
  final finder = find.byKey(_fraseKey);
  if (finder.evaluate().isEmpty) return null;
  return tester.widget<Text>(finder).data;
}

String? dorsoActual(WidgetTester tester) {
  if (find.byKey(const Key('dorso_normal')).evaluate().isNotEmpty) {
    return 'normal';
  }
  if (find.byKey(const Key('dorso_picante')).evaluate().isNotEmpty) {
    return 'picante';
  }
  return null;
}

String? frenteActual(WidgetTester tester) {
  if (find.byKey(const Key('frente_normal')).evaluate().isNotEmpty) {
    return 'normal';
  }
  if (find.byKey(const Key('frente_picante')).evaluate().isNotEmpty) {
    return 'picante';
  }
  return null;
}

void main() {
  group('YoNuncaJuegoPage — arranque y flip', () {
    testWidgets('sin picker: primera carta boca abajo con C1 + C2 y sin '
        '[Siguiente]', (tester) async {
      await irAlJuego(tester);

      expect(find.text('Elegí un género'), findsNothing);
      expect(find.byType(ChoiceChip), findsNothing);
      expect(find.text('Nivel: Normal'), findsOneWidget);
      expect(estaOculta(tester), isTrue);
      expect(find.byKey(const Key('dorso_normal')), findsOneWidget);
      expect(find.text(_c1), findsOneWidget);
      expect(find.text(_c2), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Siguiente'), findsNothing);
      // 3 cartas < 5 → aviso con la copy nueva (C15).
      expect(find.text(_c15), findsOneWidget);
      expect(find.text('Poco contenido en este género'), findsNothing);
      expect(find.text(_bannerTexto), findsNothing);
    });

    testWidgets('tap → flip: C3 + frase cruda + [Siguiente] recién al '
        'terminar', (tester) async {
      await irAlJuego(tester);

      await tester.tap(find.byKey(_cartaKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        find.widgetWithText(FilledButton, 'Siguiente'),
        findsNothing,
        reason: 'input bloqueado / flip en curso',
      );

      await tester.pumpAndSettle();
      expect(estaOculta(tester), isFalse);
      expect(find.byKey(const Key('frente_yo_nunca')), findsOneWidget);
      expect(find.text(_c3), findsOneWidget);
      expect(find.text(_c2), findsNothing);
      expect(find.text(_c1), findsNothing);
      expect(_cartasNormales, contains(fraseActual(tester)));
      expect(find.widgetWithText(FilledButton, 'Siguiente'), findsOneWidget);
    });

    testWidgets('doble tap durante el flip → un solo SFX carta', (
      tester,
    ) async {
      final fakes = await irAlJuego(tester);

      await tester.tap(find.byKey(_cartaKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(_cartaKey));
      await tester.pumpAndSettle();

      expect(
        fakes.reproductor.llamadas.where((l) => l == 'carta'),
        hasLength(1),
      );
      expect(find.widgetWithText(FilledButton, 'Siguiente'), findsOneWidget);
    });

    testWidgets('reduce motion → el tap revela al instante', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await irAlJuego(tester);
      await tester.tap(find.byKey(_cartaKey));
      await tester.pump();

      expect(find.widgetWithText(FilledButton, 'Siguiente'), findsOneWidget);
      expect(find.text(_c3), findsOneWidget);
    });

    testWidgets('juramento solo en la primera carta; no vuelve al avanzar', (
      tester,
    ) async {
      await irAlJuego(tester);

      expect(find.text(_c1), findsOneWidget);
      await revelar(tester);
      expect(find.text(_c1), findsNothing);

      await tocarBoton(tester, 'Siguiente');
      expect(estaOculta(tester), isTrue);
      expect(find.text(_c2), findsOneWidget);
      expect(find.text(_c1), findsNothing);
    });
  });

  group('YoNuncaJuegoPage — nivel y dorso', () {
    testWidgets('dorso Picante → frente Picante coherentes', (tester) async {
      // Normal vacío + Picante ['P1'] → mazo determinista de 1 carta Picante.
      const diagnostico = DiagnosticoContenido(
        contenidos: {
          'yo_nunca': ContenidoJuego(
            juegoId: 'yo_nunca',
            generos: [
              Genero(nombre: 'Normal', cartas: []),
              Genero(nombre: 'Picante', cartas: ['P1']),
            ],
          ),
        },
        errores: [],
      );
      await irAlJuego(tester, nivel: 'Picante', diagnostico: diagnostico);

      expect(find.text('Nivel: Picante'), findsOneWidget);
      expect(find.byKey(const Key('dorso_picante')), findsOneWidget);
      expect(find.byKey(const Key('dorso_normal')), findsNothing);

      await revelar(tester);
      expect(find.byKey(const Key('frente_picante')), findsOneWidget);
      expect(find.byKey(const Key('frente_normal')), findsNothing);
      expect(fraseActual(tester), 'P1');
    });

    testWidgets(
      'nivel Picante → aditivo 5 cartas sin repetir y dorso = frente',
      (tester) async {
        await irAlJuego(tester, nivel: 'Picante');

        expect(find.text('Nivel: Picante'), findsOneWidget);
        final vistas = <String>{};
        for (var i = 0; i < 5; i++) {
          expect(estaOculta(tester), isTrue);
          final dorso = dorsoActual(tester);
          await revelar(tester);
          expect(frenteActual(tester), dorso, reason: 'dorso = frente');
          vistas.add(fraseActual(tester)!);
          if (i < 4) {
            await tocarBoton(tester, 'Siguiente');
          }
        }

        expect(vistas, {'N1', 'N2', 'N3', 'P1', 'P2'});
        expect(vistas, hasLength(5));
        // 5 cartas no disparan el aviso de poco contenido.
        expect(find.text(_c15), findsNothing);
      },
    );

    testWidgets('nivel Normal no incluye cartas Picante', (tester) async {
      await irAlJuego(tester);

      final vistas = <String>{};
      for (var i = 0; i < 3; i++) {
        expect(dorsoActual(tester), 'normal');
        await revelar(tester);
        vistas.add(fraseActual(tester)!);
        await tocarBoton(tester, 'Siguiente');
      }

      expect(vistas, {'N1', 'N2', 'N3'});
      expect(vistas, isNot(contains('P1')));
      expect(vistas, isNot(contains('P2')));
      // Una más agota el mazo Normal (3 cartas).
      expect(find.text(_c13), findsOneWidget);
    });

    testWidgets('modo sin alcohol → banner, chip Normal y mazo solo Normal', (
      tester,
    ) async {
      await irAlJuego(tester, modoAlcohol: true);

      expect(find.text(_bannerTexto), findsOneWidget);
      expect(find.text('Nivel: Normal'), findsOneWidget);

      final vistas = <String>{};
      for (var i = 0; i < 3; i++) {
        expect(dorsoActual(tester), 'normal');
        await revelar(tester);
        vistas.add(fraseActual(tester)!);
        await tocarBoton(tester, 'Siguiente');
      }
      expect(vistas, {'N1', 'N2', 'N3'});
    });
  });

  group('YoNuncaJuegoPage — fin de mazo y remezcla', () {
    testWidgets(
      'agotar → C13 + [Mezclar de nuevo] → boca abajo sin juramento',
      (tester) async {
        await irAlJuego(tester);

        for (var i = 0; i < 3; i++) {
          await revelar(tester);
          await tocarBoton(tester, 'Siguiente');
        }
        expect(find.text(_c13), findsOneWidget);
        expect(
          find.widgetWithText(FilledButton, 'Mezclar de nuevo'),
          findsOneWidget,
        );

        await tocarBoton(tester, 'Mezclar de nuevo');
        expect(estaOculta(tester), isTrue);
        expect(find.text(_c2), findsOneWidget);
        expect(find.text(_c1), findsNothing);
        expect(find.widgetWithText(FilledButton, 'Siguiente'), findsNothing);
      },
    );
  });

  group('YoNuncaJuegoPage — SFX (AH6)', () {
    testWidgets('carta al revelar; click en siguiente/mezclar', (tester) async {
      final fakes = await irAlJuego(tester);

      // La partida arranca boca abajo: todavía no sonó nada.
      expect(fakes.reproductor.llamadas, isEmpty);

      await revelar(tester);
      expect(
        fakes.reproductor.llamadas.where((l) => l == 'carta'),
        hasLength(1),
      );
      expect(fakes.reproductor.llamadas.where((l) => l == 'click'), isEmpty);

      await tocarBoton(tester, 'Siguiente');
      expect(
        fakes.reproductor.llamadas.where((l) => l == 'click'),
        hasLength(1),
      );

      await revelar(tester);
      await tocarBoton(tester, 'Siguiente');
      await revelar(tester);
      await tocarBoton(tester, 'Siguiente'); // agotado
      expect(
        fakes.reproductor.llamadas.where((l) => l == 'click'),
        hasLength(3),
      );
      expect(
        fakes.reproductor.llamadas.where((l) => l == 'carta'),
        hasLength(3),
      );

      await tocarBoton(tester, 'Mezclar de nuevo');
      expect(
        fakes.reproductor.llamadas.where((l) => l == 'click'),
        hasLength(4),
      );
      expect(
        fakes.reproductor.llamadas.where((l) => l == 'carta'),
        hasLength(3),
      );
    });

    testWidgets('sonido=false y vibracion=false → 0 llamadas (AH4/AH5)', (
      tester,
    ) async {
      final fakes = await irAlJuego(tester, sonido: false, vibracion: false);

      for (var i = 0; i < 3; i++) {
        await revelar(tester);
        await tocarBoton(tester, 'Siguiente');
      }
      await tocarBoton(tester, 'Mezclar de nuevo');

      expect(fakes.reproductor.llamadas, isEmpty);
      expect(fakes.vibrador.llamadas, isEmpty);
    });
  });

  group('YoNuncaJuegoPage — salida y defensivo', () {
    testWidgets('salir mid-game → cancelar conserva / confirmar descarta y '
        're-entrar muestra el juramento', (tester) async {
      await irAlJuego(tester);

      // Boca abajo: cancelar conserva el estado exacto.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('¿Salir de la partida?'), findsOneWidget);
      await tester.tap(find.text('Seguir jugando'));
      await tester.pumpAndSettle();
      expect(estaOculta(tester), isTrue);
      expect(find.text(_c1), findsOneWidget);

      // Revelada: cancelar también conserva el reveal.
      await revelar(tester);
      expect(find.widgetWithText(FilledButton, 'Siguiente'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Seguir jugando'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Siguiente'), findsOneWidget);

      // Confirmar → reglas → Home → re-entrar = partida nueva boca abajo.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salir'));
      await tester.pumpAndSettle();
      expect(find.text('Yo nunca'), findsOneWidget); // reglas
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('PACO'), findsOneWidget); // Home

      await tester.tap(find.byKey(HomeKeys.yoNunca));
      await tester.pumpAndSettle();
      await tocarBoton(tester, 'Jugar');
      expect(estaOculta(tester), isTrue);
      expect(find.text(_c1), findsOneWidget);
      expect(find.text('Nivel: Normal'), findsOneWidget);
    });

    testWidgets('mazo vacío (solo Picante + modo sin alcohol) → C16 sin '
        'diálogo', (tester) async {
      const diagnostico = DiagnosticoContenido(
        contenidos: {
          'yo_nunca': ContenidoJuego(
            juegoId: 'yo_nunca',
            generos: [
              Genero(nombre: 'Picante', cartas: ['P1', 'P2']),
            ],
          ),
        },
        errores: [],
      );
      await irAlJuego(tester, modoAlcohol: true, diagnostico: diagnostico);

      expect(find.text(_c16), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Siguiente'), findsNothing);
      expect(find.byKey(_cartaKey), findsNothing);
      expect(find.text(_c1), findsNothing);
      expect(find.text(_c15), findsNothing);

      // Sin cartas el pop es directo (YN8).
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('¿Salir de la partida?'), findsNothing);
      expect(find.text('Yo nunca'), findsOneWidget);
    });
  });
}
