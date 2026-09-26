import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paco_game/core/contenido/entidades.dart';

import '../helpers.dart';

const _timerKey = Key('timer_pictionary');
const _marcadorKey = Key('marcador_pictionary');
const _palabraKey = Key('palabra_pictionary');
const _bannerRuleta = 'Modo sin alcohol: trago = punto/prenda';

/// 6+ palabras distintas: mínimo para 6 rondas (remexcla en ronda 3, P13).
const _palabras = ['D1', 'D2', 'D3', 'D4', 'D5', 'D6'];
const _normalUnico = Genero(nombre: 'Normal', cartas: _palabras);
const _dosGeneros = [
  Genero(nombre: 'Normal', cartas: _palabras),
  Genero(nombre: 'Picante', cartas: ['Q1']),
];
const _soloPicante = Genero(nombre: 'Picante', cartas: ['Q1']);

DiagnosticoContenido diagPictionary(List<Genero> generos) =>
    DiagnosticoContenido(
      contenidos: {
        'pictionary': ContenidoJuego(juegoId: 'pictionary', generos: generos),
      },
      errores: const [],
    );

/// Camino real: home → selector → Pictionary (instrucciones) → [Jugar] → juego.
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
    diagnostico: diagnostico ?? diagPictionary([_normalUnico]),
  );
  await tester.tap(find.widgetWithText(FilledButton, 'Jugar'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Pictionary'));
  await tester.pumpAndSettle();
  final jugar = find.widgetWithText(FilledButton, 'Jugar');
  await tester.ensureVisible(jugar);
  await tester.pumpAndSettle();
  await tester.tap(jugar);
  await tester.pumpAndSettle();
  return fakes;
}

/// Avanza pase → elegir (el sorteo ocurre al entrar a elegir).
Future<void> avanzarAElegir(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
  await tester.pumpAndSettle(); // sin timer en pase/elegir → settle seguro
}

/// Entra a la fase ronda tocando la opción [indice].
Future<void> entrarARonda(WidgetTester tester, {int indice = 0}) async {
  await avanzarAElegir(tester);
  await tester.tap(find.byKey(Key('opcion_palabra_$indice')));
  await tester.pump(); // arranca el timer: NUNCA pumpAndSettle (D11)
}

/// Juega UNA ronda completa desde la fase pase y deja la partida en pase.
///
/// [adivinada] true → [¡Adivinado!] → [Equipo A|B] (punto);
/// false → fin de tiempo ([pump(60s)]) → [Siguiente dibujante] (sin punto).
/// Termina con el timer CANCELADO (regla D11).
Future<void> jugarRonda(
  WidgetTester tester, {
  required bool adivinada,
  bool equipoA = true,
}) async {
  await entrarARonda(tester);
  if (adivinada) {
    await tester.tap(find.widgetWithText(FilledButton, '¡Adivinado!'));
    await tester.pumpAndSettle(); // crono pausado (timer cancelado) → seguro
    expect(find.text('¿Quién adivinó?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, equipoA ? 'Equipo A' : 'Equipo B'));
    await tester.pumpAndSettle(); // vuelve a pase, sin timer
  } else {
    await tester.pump(const Duration(seconds: 60)); // fin de tiempo
    await tester.pump(); // ref.listen → setState resultado
    expect(find.text('¡Se acabó el tiempo! Nadie suma'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Siguiente dibujante'));
    await tester.pumpAndSettle(); // vuelve a pase, timer cancelado
  }
  expect(find.text('Pasá el teléfono al dibujante'), findsOneWidget);
}

String marcador(int a, int b) => 'Equipo A: $a — Equipo B: $b';

void main() {
  testWidgets(
      '1 género → auto-select sin picker ni banner, fase pase con marcador 0-0',
      (tester) async {
    await irAlJuego(tester);

    expect(find.text('Elegí un género'), findsNothing);
    expect(find.text(_bannerRuleta), findsNothing); // Pictionary sin banner (D9)
    expect(find.text('Pasá el teléfono al dibujante'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Continuar'), findsOneWidget);
    expect(find.byKey(_marcadorKey), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(_marcadorKey)).data,
      marcador(0, 0),
    );
  });

  testWidgets('[Continuar] → "Elegí una palabra" + 3 opciones DISTINTAS',
      (tester) async {
    await irAlJuego(tester);
    await avanzarAElegir(tester);

    expect(find.text('Elegí una palabra'), findsOneWidget);
    final opciones = <String>[
      for (var i = 0; i < 3; i++)
        tester.widget<Text>(find.byKey(Key('opcion_palabra_$i'))).data!,
    ];
    expect(opciones, hasLength(3));
    expect(opciones.toSet(), hasLength(3)); // 3 distintas
  });

  testWidgets(
      'tap palabra → ronda: palabra en grande + Key timer + [Pausa] + '
      '[¡Adivinado!] + marcador visible', (tester) async {
    await irAlJuego(tester);
    await entrarARonda(tester);

    expect(find.byKey(_palabraKey), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(_palabraKey)).data,
      isNotEmpty,
    );
    expect(find.byKey(_timerKey), findsOneWidget);
    expect(find.text('Pausa'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '¡Adivinado!'), findsOneWidget);
    expect(find.byKey(_marcadorKey), findsOneWidget);

    // Termina la ronda (timer cancelado) antes del fin del test (D11).
    await tester.tap(find.widgetWithText(FilledButton, '¡Adivinado!'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Equipo A'));
    await tester.pumpAndSettle();
  });

  testWidgets('countdown: ronda en 60 → pump(1s) → 59', (tester) async {
    await irAlJuego(tester);
    await entrarARonda(tester);

    expect(
      tester.widget<Text>(find.byKey(_timerKey)).data,
      '60',
    );
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester.widget<Text>(find.byKey(_timerKey)).data,
      '59',
    );

    // Fin de ronda para cancelar el timer (D11).
    await tester.pump(const Duration(seconds: 60));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Siguiente dibujante'));
    await tester.pumpAndSettle();
  });

  testWidgets('countdown ≤10s → 1 tick + 1 tickTimer por segundo; nada por '
      'encima de 10 ni en 0 (AH6)', (tester) async {
    final fakes = await irAlJuego(tester);
    await entrarARonda(tester);

    // Por encima de 10s: 0 ticks (guard del diseño A7).
    await tester.pump(const Duration(seconds: 49)); // 60 → 11
    expect(fakes.reproductor.llamadas.where((l) => l == 'tick'), isEmpty);
    expect(fakes.vibrador.llamadas, isEmpty);

    // 11 → 10: primer tick.
    await tester.pump(const Duration(seconds: 1));
    expect(fakes.reproductor.llamadas.where((l) => l == 'tick'), hasLength(1));

    // 10 → 1: 9 ticks más (10 en total), 1 por segundo.
    for (var i = 0; i < 9; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(fakes.reproductor.llamadas.where((l) => l == 'tick'), hasLength(10));
    expect(
      fakes.vibrador.llamadas.where((l) => l == 'tickTimer'),
      hasLength(10),
    );

    // 1 → 0: no suena (0 no es > 0) y termina la ronda (D11: timer cancelado).
    await tester.pump(const Duration(seconds: 1));
    expect(fakes.reproductor.llamadas.where((l) => l == 'tick'), hasLength(10));
    expect(find.text('¡Se acabó el tiempo! Nadie suma'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Siguiente dibujante'));
    await tester.pumpAndSettle();
  });

  testWidgets('[¡Adivinado!] → fanfarria + acierto; [Equipo A] → click (AH6)',
      (tester) async {
    final fakes = await irAlJuego(tester);
    await entrarARonda(tester);

    await tester.tap(find.widgetWithText(FilledButton, '¡Adivinado!'));
    await tester.pumpAndSettle();

    expect(find.text('¿Quién adivinó?'), findsOneWidget);
    // ['click' (Continuar)] + ['fanfarria' (¡Adivinado!)].
    expect(fakes.reproductor.llamadas, ['click', 'fanfarria']);
    expect(fakes.vibrador.llamadas, ['acierto']);

    await tester.tap(find.widgetWithText(FilledButton, 'Equipo A'));
    await tester.pumpAndSettle();
    expect(fakes.reproductor.llamadas, ['click', 'fanfarria', 'click']);
  });

  testWidgets('sonido=false y vibracion=false → 0 llamadas a audio y hápticos '
      'en partida completa (countdown + adivinado) (AH4/AH5/A2)',
      (tester) async {
    final fakes = await irAlJuego(tester, sonido: false, vibracion: false);

    // Ronda completa: countdown a 0 (60 ticks de timer) + [¡Adivinado!].
    await entrarARonda(tester);
    await tester.pump(const Duration(seconds: 60));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Siguiente dibujante'));
    await tester.pumpAndSettle();

    await entrarARonda(tester);
    await tester.tap(find.widgetWithText(FilledButton, '¡Adivinado!'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Equipo A'));
    await tester.pumpAndSettle();

    expect(fakes.reproductor.llamadas, isEmpty);
    expect(fakes.vibrador.llamadas, isEmpty);
  });

  testWidgets('fin de tiempo: "¡Se acabó el tiempo! Nadie suma" → '
      '[Siguiente dibujante] sin punto', (tester) async {
    await irAlJuego(tester);
    await jugarRonda(tester, adivinada: false);

    // Sin punto: el marcador sigue 0-0.
    expect(
      tester.widget<Text>(find.byKey(_marcadorKey)).data,
      marcador(0, 0),
    );
  });

  testWidgets('[¡Adivinado!] → "¿Quién adivinó?" → [Equipo A] → marcador 1-0 '
      'y vuelve a pase', (tester) async {
    await irAlJuego(tester);
    await jugarRonda(tester, adivinada: true, equipoA: true);

    expect(
      tester.widget<Text>(find.byKey(_marcadorKey)).data,
      marcador(1, 0),
    );
  });

  testWidgets('pausa manual congela: [Pausa] → pump(5s) congelado → '
      '[Reanudar] → pump(1s) baja', (tester) async {
    await irAlJuego(tester);
    await entrarARonda(tester);
    await tester.pump(const Duration(seconds: 10));
    expect(
      tester.widget<Text>(find.byKey(_timerKey)).data,
      '50',
    );

    await tester.tap(find.text('Pausa'));
    await tester.pumpAndSettle(); // timer cancelado → seguro
    expect(find.text('Reanudar'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    expect(
      tester.widget<Text>(find.byKey(_timerKey)).data,
      '50', // congelado
    );

    await tester.tap(find.text('Reanudar'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester.widget<Text>(find.byKey(_timerKey)).data,
      '49',
    );

    // Termina la ronda (timer cancelado) antes del fin (D11).
    await tester.tap(find.widgetWithText(FilledButton, '¡Adivinado!'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Equipo A'));
    await tester.pumpAndSettle();
  });

  testWidgets('lifecycle paused congela el timer; resumed lo reanuda '
      '(interrupción conserva estado)', (tester) async {
    addTearDown(() => tester.binding
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed));

    await irAlJuego(tester);
    await entrarARonda(tester);
    await tester.pump(const Duration(seconds: 10));
    expect(
      tester.widget<Text>(find.byKey(_timerKey)).data,
      '50',
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 5));
    expect(
      tester.widget<Text>(find.byKey(_timerKey)).data,
      '50', // congelado por lifecycle
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester.widget<Text>(find.byKey(_timerKey)).data,
      '49', // reanudado
    );

    // Termina la ronda (timer cancelado) antes del fin (D11).
    await tester.tap(find.widgetWithText(FilledButton, '¡Adivinado!'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Equipo A'));
    await tester.pumpAndSettle();
  });

  testWidgets('marcador persiste entre rondas (2 rondas adivinadas A y B)',
      (tester) async {
    await irAlJuego(tester);
    await jugarRonda(tester, adivinada: true, equipoA: true);
    expect(
      tester.widget<Text>(find.byKey(_marcadorKey)).data,
      marcador(1, 0),
    );

    await jugarRonda(tester, adivinada: true, equipoA: false);
    expect(
      tester.widget<Text>(find.byKey(_marcadorKey)).data,
      marcador(1, 1),
    );
  });

  testWidgets('partida completa de 6 rondas (verifica M3): marcador suma, '
      'turno 1→7, sin crash ni timer pendiente', (tester) async {
    await irAlJuego(tester);

    // Mezcla de adivinados (A/B) y fines de tiempo.
    final plan = [
      (adivinada: true, equipoA: true),
      (adivinada: false, equipoA: true),
      (adivinada: true, equipoA: false),
      (adivinada: true, equipoA: true),
      (adivinada: false, equipoA: true),
      (adivinada: true, equipoA: false),
    ];
    var puntosA = 0;
    var puntosB = 0;
    for (final ronda in plan) {
      await jugarRonda(
        tester,
        adivinada: ronda.adivinada,
        equipoA: ronda.equipoA,
      );
      if (ronda.adivinada) {
        if (ronda.equipoA) {
          puntosA++;
        } else {
          puntosB++;
        }
      }
    }

    expect(
      tester.widget<Text>(find.byKey(_marcadorKey)).data,
      marcador(puntosA, puntosB),
    );
    expect(find.text('Pasá el teléfono al dibujante'), findsOneWidget); // pase
    // Sin crash y sin timer pendiente: el test termina con el timer cancelado
    // (cada ronda terminó en adivinado o fin de tiempo — regla D11).
  });

  testWidgets('salir mid-game: diálogo EXACTO → [Seguir jugando] conserva / '
      '[Salir] descarta (re-entrar = fresco)', (tester) async {
    await irAlJuego(tester);
    // Punto para que el marcador NO sea 0-0 al salir.
    await jugarRonda(tester, adivinada: true, equipoA: true);
    expect(
      tester.widget<Text>(find.byKey(_marcadorKey)).data,
      marcador(1, 0),
    );

    // Mid-game: [Pausa] (timer cancelado, P12) y back → diálogo.
    await entrarARonda(tester);
    await tester.tap(find.text('Pausa'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('¿Salir de la partida?'), findsOneWidget);
    expect(find.text('Perdés el marcador de la partida'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Seguir jugando'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Salir'), findsOneWidget);

    // [Seguir jugando] → partida intacta (marcador 1-0, ronda pausada).
    await tester.tap(find.text('Seguir jugando'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(_marcadorKey)).data,
      marcador(1, 0),
    );

    // [Salir] → descarta (autoDispose) → re-entrar = fresco (0-0).
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir'));
    await tester.pumpAndSettle();
    expect(find.text('Pictionary'), findsOneWidget); // instrucciones

    final jugar = find.widgetWithText(FilledButton, 'Jugar');
    await tester.ensureVisible(jugar);
    await tester.pumpAndSettle();
    await tester.tap(jugar);
    await tester.pumpAndSettle();
    expect(find.text('Pasá el teléfono al dibujante'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(_marcadorKey)).data,
      marcador(0, 0), // fresco
    );
  });

  testWidgets('interrupción mid-ronda conserva estado (palabra, marcador, '
      'timer congelado y reanudado)', (tester) async {
    addTearDown(() => tester.binding
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed));

    await irAlJuego(tester);
    await jugarRonda(tester, adivinada: true, equipoA: true); // marcador 1-0

    await entrarARonda(tester);
    await tester.pump(const Duration(seconds: 10));
    final palabraAntes = tester.widget<Text>(find.byKey(_palabraKey)).data;
    expect(
      tester.widget<Text>(find.byKey(_timerKey)).data,
      '50',
    );

    // Interrupción: lifecycle paused → congelado → resumed → sigue.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 5));
    expect(
      tester.widget<Text>(find.byKey(_timerKey)).data,
      '50',
    );

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(
      tester.widget<Text>(find.byKey(_timerKey)).data,
      '49',
    );

    // Misma palabra y mismo marcador que antes de la interrupción.
    expect(tester.widget<Text>(find.byKey(_palabraKey)).data, palabraAntes);
    expect(
      tester.widget<Text>(find.byKey(_marcadorKey)).data,
      marcador(1, 0),
    );

    // Termina la ronda (timer cancelado) antes del fin (D11).
    await tester.tap(find.widgetWithText(FilledButton, '¡Adivinado!'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Equipo B'));
    await tester.pumpAndSettle();
  });

  testWidgets('>1 género visible → picker "Elegí un género"; elegir → juega',
      (tester) async {
    await irAlJuego(tester, diagnostico: diagPictionary(_dosGeneros));

    expect(find.text('Elegí un género'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);
    expect(find.text('Picante'), findsOneWidget);
    expect(find.text('Pasá el teléfono al dibujante'), findsNothing);

    await tester.tap(find.text('Normal'));
    await tester.pumpAndSettle();
    expect(find.text('Pasá el teléfono al dibujante'), findsOneWidget);
  });

  testWidgets('0 géneros visibles (solo Picante + modoAlcohol) → defensivo',
      (tester) async {
    // modoAlcohol=true filtra Picante → 0 visibles.
    await irAlJuego(
      tester,
      modoAlcohol: true,
      diagnostico: diagPictionary([_soloPicante]),
    );

    expect(find.text('Sin géneros disponibles en este modo'), findsOneWidget);
    expect(find.text('Elegí un género'), findsNothing);
  });
}