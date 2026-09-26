import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paco_game/core/contenido/entidades.dart';

import '../helpers.dart';

const _resultadoKey = Key('resultado_ruleta');
const _bannerRuleta = 'Modo sin alcohol: trago = punto/prenda';

const _normalUnico = Genero(nombre: 'Normal', cartas: ['Carta A', 'Carta B']);
const _soloPassTurn = Genero(nombre: 'Normal', cartas: ['volvé a girar']);
const _soloPicante = Genero(nombre: 'Picante', cartas: ['P1']);
const _dosGeneros = [
  Genero(nombre: 'Normal', cartas: ['N1']),
  Genero(nombre: 'Picante', cartas: ['P1']),
];

DiagnosticoContenido diagRuleta(List<Genero> generos) => DiagnosticoContenido(
      contenidos: {
        'ruleta': ContenidoJuego(juegoId: 'ruleta', generos: generos),
      },
      errores: const [],
    );

/// Camino real: home → selector → Ruleta (instrucciones) → [Jugar] → juego.
/// Con fakes de audio/hápticos (seam AH3) — devuelve los fakes.
Future<FakesAudio> irAlJuego(
  WidgetTester tester, {
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
    diagnostico: diagnostico ?? diagRuleta([_normalUnico]),
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Jugar'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ruleta'));
  await tester.pumpAndSettle();
  final jugar = find.widgetWithText(FilledButton, 'Jugar');
  await tester.ensureVisible(jugar);
  await tester.pumpAndSettle();
  await tester.tap(jugar);
  await tester.pumpAndSettle();
  return fakes;
}

/// Toca [Girar] y completa la animación (pump + 3 s + 100 ms + pump reveal).
///
/// Nota fake-clock (SDK 3.41.2): `pump(3s)` adelanta el controller al valor
/// final pero el status `completed` (→ onEnd) se entrega en el tick SIGUIENTE;
/// por eso hace falta un `pump(100ms)` extra antes del pump que renderiza el
/// reveal (verificado empíricamente; `pumpAndSettle` también lo logra).
Future<void> girarYEsperar(WidgetTester tester) async {
  final girar = find.widgetWithText(FilledButton, 'Girar');
  await tester.ensureVisible(girar);
  await tester.pumpAndSettle();
  await tester.tap(girar);
  await tester.pump(); // arranca AnimatedRotation
  await tester.pump(const Duration(seconds: 3)); // completa la animación
  await tester.pump(const Duration(milliseconds: 100)); // entrega completed → onEnd
  await tester.pump(); // renderiza el reveal (setState de onEnd)
}

void main() {
  group('RuletaJuegoPage', () {
    testWidgets('1 género → auto-select sin picker, [Girar] visible, sin banner',
        (tester) async {
      await irAlJuego(tester);

      expect(find.text('Elegí un género'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Girar'), findsOneWidget);
      expect(find.text(_bannerRuleta), findsNothing);
    });

    testWidgets('modoAlcohol=true → banner EXACTO "trago = punto/prenda"',
        (tester) async {
      await irAlJuego(tester, modoAlcohol: true);

      expect(find.text(_bannerRuleta), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Girar'), findsOneWidget);
    });

    testWidgets(
        '[Girar] → deshabilitado durante la animación → pump(3s) → resultado '
        'en grande + [Siguiente] + [Girar] re-habilitado', (tester) async {
      await irAlJuego(tester);

      final girar = find.widgetWithText(FilledButton, 'Girar');
      await tester.ensureVisible(girar);
      await tester.pumpAndSettle();
      await tester.tap(girar);
      await tester.pump();

      // Bloqueado mientras gira (sin re-entradas) y resultado aún oculto.
      final durante = tester.widget<FilledButton>(girar);
      expect(durante.onPressed, isNull);
      expect(find.byKey(_resultadoKey), findsNothing);

      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(milliseconds: 100)); // entrega completed → onEnd
      await tester.pump(); // onEnd → reveal

      final resultado = tester.widget<Text>(find.byKey(_resultadoKey));
      expect(resultado.data, isNotNull);
      expect(resultado.data, isNotEmpty);
      expect(find.widgetWithText(FilledButton, 'Siguiente'), findsOneWidget);
      final re = tester.widget<FilledButton>(girar);
      expect(re.onPressed, isNotNull);
    });

    testWidgets('[Girar] → giro; onEnd → fanfarria + ruletaFrenar; '
        '[Siguiente] → click (AH6)', (tester) async {
      final fakes = await irAlJuego(tester);
      await girarYEsperar(tester);

      // Giro al arrancar + fanfarria al frenar + háptico medio.
      expect(fakes.reproductor.llamadas, ['giro', 'fanfarria']);
      expect(fakes.vibrador.llamadas, ['ruletaFrenar']);

      await tester.tap(find.widgetWithText(FilledButton, 'Siguiente'));
      await tester.pumpAndSettle();
      expect(fakes.reproductor.llamadas, ['giro', 'fanfarria', 'click']);
    });

    testWidgets('sonido=false y vibracion=false → 0 llamadas a audio y '
        'hápticos (AH4/AH5/A2)', (tester) async {
      final fakes = await irAlJuego(tester, sonido: false, vibracion: false);
      await girarYEsperar(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Siguiente'));
      await tester.pumpAndSettle();

      expect(fakes.reproductor.llamadas, isEmpty);
      expect(fakes.vibrador.llamadas, isEmpty);
    });

    testWidgets('pass-turn: aviso exacto tras reveal, sin re-giro automático',
        (tester) async {
      await irAlJuego(tester, diagnostico: diagRuleta([_soloPassTurn]));
      await girarYEsperar(tester);

      expect(find.text('Turno salvado, pasás el turno y gira el siguiente'),
          findsOneWidget);
      expect(find.byKey(_resultadoKey), findsOneWidget);
      final resultado = tester.widget<Text>(find.byKey(_resultadoKey));
      expect(resultado.data, 'volvé a girar');
      expect(find.widgetWithText(FilledButton, 'Siguiente'), findsOneWidget);
    });

    testWidgets('[Siguiente] limpia el resultado y se puede girar de nuevo',
        (tester) async {
      await irAlJuego(tester);
      await girarYEsperar(tester);
      expect(find.byKey(_resultadoKey), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Siguiente'));
      await tester.pumpAndSettle();
      expect(find.byKey(_resultadoKey), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Siguiente'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Girar'), findsOneWidget);

      // Segundo giro: la ventana sigue, sin crash.
      await girarYEsperar(tester);
      expect(find.byKey(_resultadoKey), findsOneWidget);
    });

    testWidgets('salir mid-game → diálogo → cancelar conserva / confirmar descarta',
        (tester) async {
      await irAlJuego(tester);

      // Cancelar conserva la partida exactamente donde estaba.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('¿Salir de la partida?'), findsOneWidget);
      expect(find.text('Perdés el historial de la ronda'), findsOneWidget);
      await tester.tap(find.text('Seguir jugando'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Girar'), findsOneWidget);

      // Confirmar → pop a instrucciones (D6) → back al selector.
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salir'));
      await tester.pumpAndSettle();
      expect(
        find.text('Tocá [Girar] y esperá la animación: la ruleta elige por vos'),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Elegí un juego'), findsOneWidget); // selector

      // Re-entrar → estado descartado (autoDispose) → auto-select fresco.
      await tester.tap(find.text('Ruleta'));
      await tester.pumpAndSettle();
      final jugar = find.widgetWithText(FilledButton, 'Jugar');
      await tester.ensureVisible(jugar);
      await tester.pumpAndSettle();
      await tester.tap(jugar);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Girar'), findsOneWidget);
      expect(find.text('Elegí un género'), findsNothing);
    });

    testWidgets('>1 género visible → picker "Elegí un género"; elegir → juega',
        (tester) async {
      await irAlJuego(tester, diagnostico: diagRuleta(_dosGeneros));

      expect(find.text('Elegí un género'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Picante'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Girar'), findsNothing);

      await tester.tap(find.text('Normal'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FilledButton, 'Girar'), findsOneWidget);
    });

    testWidgets('0 géneros visibles (solo Picante + modoAlcohol) → defensivo',
        (tester) async {
      await irAlJuego(
        tester,
        modoAlcohol: true,
        diagnostico: diagRuleta([_soloPicante]),
      );

      expect(find.text('Sin géneros disponibles en este modo'), findsOneWidget);
      expect(find.text('Elegí un género'), findsNothing);
    });
  });
}