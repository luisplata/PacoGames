import 'package:paco_game/core/audio/hapticos.dart';
import 'package:paco_game/core/audio/reproductor.dart';

/// Fake de [Reproductor] que registra cada llamada en [llamadas].
///
/// Compartido entre los unit tests de core/audio y los widget tests de
/// juego (test/features/helpers.dart) — el seam crítico del design (AH3):
/// nunca toca el plugin real.
class ReproductorFake implements Reproductor {
  final List<String> llamadas = [];

  @override
  Future<void> cargar() async => llamadas.add('cargar');

  @override
  Future<void> reproducirClick() async => llamadas.add('click');

  @override
  Future<void> reproducirTick() async => llamadas.add('tick');

  @override
  Future<void> reproducirFanfarria() async => llamadas.add('fanfarria');

  @override
  Future<void> reproducirGiro() async => llamadas.add('giro');

  @override
  Future<void> reproducirCarta() async => llamadas.add('carta');

  @override
  Future<void> detener() async => llamadas.add('detener');

  @override
  Future<void> dispose() async => llamadas.add('dispose');
}

/// Fake de [Vibrador] que registra cada llamada en [llamadas].
class VibradorFake implements Vibrador {
  final List<String> llamadas = [];

  @override
  Future<void> ruletaFrenar() async => llamadas.add('ruletaFrenar');

  @override
  Future<void> tickTimer() async => llamadas.add('tickTimer');

  @override
  Future<void> acierto() async => llamadas.add('acierto');
}