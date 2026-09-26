import 'reproductor.dart';

/// Servicio de sonido gated por el toggle real de Ajustes (AH4/A2).
///
/// Expone los 5 SFX con el mismo nombre que [Reproductor]; si `habilitado`
/// es false, NINGUNA llamada llega al reproductor (0 llamadas).
/// El provider lo reconstruye al cambiar `ajustes.sonido` (sin estado
/// mutable: gating automático).
class SonidoServicio {
  const SonidoServicio({required this.habilitado, required this.reproductor});

  final bool habilitado;
  final Reproductor reproductor;

  Future<void> reproducirClick() => _reproducir(reproductor.reproducirClick);

  Future<void> reproducirTick() => _reproducir(reproductor.reproducirTick);

  Future<void> reproducirFanfarria() =>
      _reproducir(reproductor.reproducirFanfarria);

  Future<void> reproducirGiro() => _reproducir(reproductor.reproducirGiro);

  Future<void> reproducirCarta() => _reproducir(reproductor.reproducirCarta);

  Future<void> _reproducir(Future<void> Function() accion) async {
    if (!habilitado) return;
    await accion();
  }
}