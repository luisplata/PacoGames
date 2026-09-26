import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3 mantiene StateProvider detrás de legacy.dart (patrón M1 dev-3:
// el género seleccionado es StateProvider.autoDispose).
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/ajustes/ajustes_providers.dart';
import '../../../core/contenido/diagnostico.dart';
import 'cronometro_pictionary.dart';
import 'sesion_pictionary.dart';

/// Género seleccionado de la partida de pictionary (P3).
///
/// `null` = sin género → la UI hace auto-select (1 visible) o picker.
/// Efímero: autoDispose descarta el estado al salir de la ruta
/// (re-entrar = partida fresca).
final pictionaryGeneroProvider = StateProvider.autoDispose<String?>((ref) => null);

/// Sesión de la partida actual (P3): marcador A/B, turno y palabras.
/// Se descarta al salir (autoDispose → re-entrar = fresco, P8).
final sesionPictionaryProvider =
    NotifierProvider.autoDispose<SesionPictionaryNotifier, SesionPictionary>(
  SesionPictionaryNotifier.new,
);

/// Cronómetro de la ronda actual (P3/P5): posee el `Timer.periodic(1 s)`.
/// NO arranca en build (P4): la página llama `iniciar()` al entrar a la
/// fase ronda. El timer se cancela vía `ref.onDispose` (Riverpod 3.3.2:
/// Notifier sin dispose() overridable — verificado).
final pictionaryCronometroProvider =
    NotifierProvider.autoDispose<CronometroPictionaryNotifier, CronometroPictionary>(
  CronometroPictionaryNotifier.new,
);

class SesionPictionaryNotifier extends Notifier<SesionPictionary> {
  @override
  SesionPictionary build() {
    // Watch genero + diagnostico + ajustes (P8): la sesión se reconstruye
    // al cambiar el género; el deck se lee recién al sortear.
    ref.watch(pictionaryGeneroProvider);
    ref.watch(diagnosticoContenidoProvider);
    ref.watch(ajustesProvider);
    return SesionPictionary.iniciar();
  }

  /// Cartas del género seleccionado; desconocido/ausente → `[]` (sorteo
  /// defensivo, sin crash).
  List<String> _cartasDelGenero() {
    final genero = ref.read(pictionaryGeneroProvider);
    final diagnostico = ref.read(diagnosticoContenidoProvider).value;
    if (genero == null || diagnostico == null) return const [];
    final juego = diagnostico.contenidos['pictionary'];
    if (juego == null) return const [];
    for (final g in juego.generos) {
      if (g.nombre == genero) return g.cartas;
    }
    return const [];
  }

  /// Escribe el género seleccionado → la sesión se reconstruye (P9).
  void seleccionarGenero(String genero) {
    ref.read(pictionaryGeneroProvider.notifier).state = genero;
  }

  /// Sorteo de la fase elegir (P1): sortea 3 del deck del género y las
  /// consume AL INSTANTE (el dibujante las vio en el pase secreto). El
  /// consume se encadena sobre la sesión SORTEADA para que las 3 opciones
  /// queden en `palabrasActuales` (alimentan la UI de elegir) Y quemadas.
  void sortearPalabras([Random? random]) {
    final sorteada = state.sortearPalabras(_cartasDelGenero(), random: random);
    state = sorteada.consumirPalabras(sorteada.palabrasActuales);
  }

  void puntoA() => state = state.marcarPuntoA();

  void puntoB() => state = state.marcarPuntoB();

  void siguienteDibujante() => state = state.siguienteDibujante();

  void nuevaRonda() => state = state.nuevaRonda();
}

class CronometroPictionaryNotifier extends Notifier<CronometroPictionary> {
  Timer? _timer;

  @override
  CronometroPictionary build() {
    // P4: el timer se cancela al descartarse el provider (autoDispose al
    // salir de la ruta) — evita "Timer is still pending" y fugas.
    ref.onDispose(() => _timer?.cancel());
    return CronometroPictionary.iniciar();
  }

  /// Arranca el countdown (fase ronda): cancela un timer previo, reinicia
  /// el estado y crea el `Timer.periodic` que hace `tick()` cada segundo.
  void iniciar() {
    _timer?.cancel();
    state = CronometroPictionary.iniciar();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.tick();
      // Terminado → auto-cancel: no quedan ticks colgando (P4).
      if (state.terminado) _timer?.cancel();
    });
  }

  /// Pausa manual o por lifecycle (P5): congela el countdown y cancela el
  /// timer (el tick se reanuda al volver).
  void pausar() {
    state = state.pausar();
    _timer?.cancel();
  }

  /// Reanuda (P5): si no terminó, crea el timer de nuevo.
  void reanudar() {
    state = state.reanudar();
    if (!state.terminado) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        state = state.tick();
        if (state.terminado) _timer?.cancel();
      });
    }
  }
}