/// Cronómetro de ronda de Pictionary puro e inmutable (P2).
///
/// Sin imports de Flutter a propósito: la mecánica es dominio puro y
/// testeable sin reloj. `tick()` decrementa 1 solo si está corriendo
/// (!pausado && !terminado) y nunca va a negativo; al llegar a 0 marca
/// `terminado`. Cada método devuelve UNA NUEVA instancia.
class CronometroPictionary {
  const CronometroPictionary._({
    required int segundosRestantes,
    required bool pausado,
  })  : _segundosRestantes = segundosRestantes,
        _pausado = pausado;

  /// Duración fija de la ronda (P5): 60 segundos.
  static const duracionRonda = Duration(seconds: 60);

  /// Nuevo cronómetro en 60, corriendo y sin terminar.
  factory CronometroPictionary.iniciar() {
    return const CronometroPictionary._(segundosRestantes: 60, pausado: false);
  }

  final int _segundosRestantes;
  final bool _pausado;

  int get segundosRestantes => _segundosRestantes;

  bool get pausado => _pausado;

  /// `true` cuando el countdown llegó a 0.
  bool get terminado => _segundosRestantes <= 0;

  /// Decrementa 1 si está corriendo; no-op si pausado o terminado.
  CronometroPictionary tick() {
    if (_pausado || terminado) return this;
    return CronometroPictionary._(
      segundosRestantes: _segundosRestantes - 1,
      pausado: false,
    );
  }

  /// Congela el countdown; no-op si ya terminó.
  CronometroPictionary pausar() {
    if (terminado) return this;
    return CronometroPictionary._(
      segundosRestantes: _segundosRestantes,
      pausado: true,
    );
  }

  /// Reanuda el countdown; no-op si ya terminó.
  CronometroPictionary reanudar() {
    if (terminado) return this;
    return CronometroPictionary._(
      segundosRestantes: _segundosRestantes,
      pausado: false,
    );
  }
}