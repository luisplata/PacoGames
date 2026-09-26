import 'dart:math';

/// Sesión de Pictionary pura e inmutable (P1, espejo de `Mazo` M1 y
/// `Ruleta` M2).
///
/// Sin imports de Flutter a propósito: la mecánica es dominio puro y
/// testeable con seed. Estado: marcador A/B, turno del dibujante y las
/// palabras quemadas de la sesión. `sortearPalabras()` muestrea 3 SIN
/// reemplazo sobre el deck deduplicado por string exacto (la 'Pintar' x2
/// del JSON real NUNCA aparece 2 veces como opción) y excluyendo las
/// usadas; las 3 mostradas se consumen después (el dibujante las vio).
class SesionPictionary {
  const SesionPictionary._({
    required int marcadorA,
    required int marcadorB,
    required int turnoDibujante,
    required List<String> palabrasUsadas,
    required List<String> palabrasActuales,
  })  : _marcadorA = marcadorA,
        _marcadorB = marcadorB,
        _turnoDibujante = turnoDibujante,
        _palabrasUsadas = palabrasUsadas,
        _palabrasActuales = palabrasActuales;

  /// Nueva partida: marcador 0-0, turno del dibujante 1, sin palabras.
  factory SesionPictionary.iniciar() {
    return const SesionPictionary._(
      marcadorA: 0,
      marcadorB: 0,
      turnoDibujante: 1,
      palabrasUsadas: [],
      palabrasActuales: [],
    );
  }

  final int _marcadorA;
  final int _marcadorB;
  final int _turnoDibujante;
  final List<String> _palabrasUsadas;
  final List<String> _palabrasActuales;

  int get marcadorA => _marcadorA;
  int get marcadorB => _marcadorB;
  int get turnoDibujante => _turnoDibujante;

  /// Palabras quemadas de la sesión (ya mostradas al dibujante).
  List<String> get palabrasUsadas => List.unmodifiable(_palabrasUsadas);

  /// Las 3 opciones de la fase elegir (o las que haya, deck < 3).
  List<String> get palabrasActuales => List.unmodifiable(_palabrasActuales);

  /// Sorteo de la fase elegir: 3 palabras SIN reemplazo sobre
  /// `deck.toSet() - palabrasUsadas` (dedupe por string exacto, P2).
  ///
  /// Pool < 3 → remezcla automática (se resetean las usadas y se sortea del
  /// set completo — espejo regla Mazo, nunca deadlock). Deck < 3 distintos →
  /// sortea lo que haya (`min(3, pool)`); deck vacío → no-op (`this`).
  /// No consume: las 3 mostradas se queman con [consumirPalabras].
  SesionPictionary sortearPalabras(List<String> deck, {Random? random}) {
    final unicas = deck.toSet();
    if (unicas.isEmpty) return this; // defensivo: sin palabras, sin crash

    final disponibles = unicas.difference(_palabrasUsadas.toSet());
    final pool = disponibles.length < 3 ? unicas : disponibles;
    final usadasBase = disponibles.length < 3 ? const <String>[] : _palabrasUsadas;

    final rng = random ?? Random();
    final cantidad = min(3, pool.length);
    return SesionPictionary._(
      marcadorA: _marcadorA,
      marcadorB: _marcadorB,
      turnoDibujante: _turnoDibujante,
      palabrasUsadas: usadasBase,
      palabrasActuales: _muestrear(pool.toList(), cantidad, rng),
    );
  }

  /// Quema las palabras mostradas: se agregan a `palabrasUsadas`.
  SesionPictionary consumirPalabras(List<String> palabras) {
    return SesionPictionary._(
      marcadorA: _marcadorA,
      marcadorB: _marcadorB,
      turnoDibujante: _turnoDibujante,
      palabrasUsadas: [..._palabrasUsadas, ...palabras],
      palabrasActuales: _palabrasActuales,
    );
  }

  /// +1 para el equipo A (P6).
  SesionPictionary marcarPuntoA() {
    return SesionPictionary._(
      marcadorA: _marcadorA + 1,
      marcadorB: _marcadorB,
      turnoDibujante: _turnoDibujante,
      palabrasUsadas: _palabrasUsadas,
      palabrasActuales: _palabrasActuales,
    );
  }

  /// +1 para el equipo B (P6).
  SesionPictionary marcarPuntoB() {
    return SesionPictionary._(
      marcadorA: _marcadorA,
      marcadorB: _marcadorB + 1,
      turnoDibujante: _turnoDibujante,
      palabrasUsadas: _palabrasUsadas,
      palabrasActuales: _palabrasActuales,
    );
  }

  /// Pasa el turno al siguiente dibujante SIN punto (P5/P6).
  SesionPictionary siguienteDibujante() {
    return SesionPictionary._(
      marcadorA: _marcadorA,
      marcadorB: _marcadorB,
      turnoDibujante: _turnoDibujante + 1,
      palabrasUsadas: _palabrasUsadas,
      palabrasActuales: _palabrasActuales,
    );
  }

  /// Nueva ronda: limpia las opciones de la fase elegir; conserva marcador,
  /// turno y palabras usadas (P6).
  SesionPictionary nuevaRonda() {
    return SesionPictionary._(
      marcadorA: _marcadorA,
      marcadorB: _marcadorB,
      turnoDibujante: _turnoDibujante,
      palabrasUsadas: _palabrasUsadas,
      palabrasActuales: const [],
    );
  }

  /// Muestreo sin reemplazo (Fisher-Yates parcial): determinista con seed.
  static List<String> _muestrear(List<String> pool, int cantidad, Random rng) {
    for (var i = 0; i < cantidad; i++) {
      final j = i + rng.nextInt(pool.length - i);
      final tmp = pool[i];
      pool[i] = pool[j];
      pool[j] = tmp;
    }
    return pool.take(cantidad).toList();
  }
}