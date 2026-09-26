import 'dart:math';

/// Selección ponderada para la ruleta (RU2, R2).
///
/// Puro: pick uniforme sobre la lista COMPLETA (los duplicados ponderan
/// naturalmente, ej: "Volvés a girar" 2/16) EXCLUYENDO las últimas 5 por
/// string exacto. Si el pool queda vacío (deck con ≤5 strings distintos)
/// hace fallback a la lista completa: nunca deadlock.
String seleccionarResultado(List<String> cartas, List<String> ultimas5, Random rng) {
  final excluidas = ultimas5.toSet();
  final candidatas = cartas.where((c) => !excluidas.contains(c)).toList();
  final pool = candidatas.isEmpty ? cartas : candidatas;
  return pool[rng.nextInt(pool.length)];
}

/// `true` si el resultado es pass-turn (RU3, R3).
///
/// Match EXACTO normalizado (trim + toLowerCase) sobre las dos grafías
/// {'volvé a girar', 'volvés a girar'}. NUNCA substring: "Fondo blanco o
/// volvé a girar" es OTRA carta → false.
bool esPasaTurno(String resultado) {
  final n = resultado.trim().toLowerCase();
  return n == 'volvé a girar' || n == 'volvés a girar';
}

/// Ruleta pura e inmutable (RU1, espejo de `Mazo` M1).
///
/// Sin imports de Flutter a propósito: la mecánica es dominio puro y
/// testeable con seed. `girar()` setea `resultado` Y empuja a `historial`
/// (cada giro produce 1 final, R1); `siguiente()` solo limpia `resultado`
/// y preserva la ventana `ultimas5` (el [Siguiente] no cuenta como giro).
class Ruleta {
  const Ruleta._({
    required List<String> cartas,
    required String? resultado,
    required List<String> historial,
  })  : _cartas = cartas,
        _resultado = resultado,
        _historial = historial;

  /// Nueva ruleta esperando el primer giro: `resultado` null, sin historial.
  factory Ruleta.iniciar(List<String> cartas) {
    return Ruleta._(
      cartas: List.unmodifiable(cartas),
      resultado: null,
      historial: const [],
    );
  }

  final List<String> _cartas;
  final String? _resultado;
  final List<String> _historial;

  /// Cartas de la rueda, inmutables (para el aterrizaje best-effort por
  /// índice en la UI).
  List<String> get cartas => _cartas;

  /// Último resultado elegido; `null` = esperando [Girar].
  String? get resultado => _resultado;

  /// TODOS los giros, en orden (incluye pass-turn, R1). Inmutable.
  List<String> get historial => List.unmodifiable(_historial);

  /// Últimos 5 resultados en orden (ventana deslizante, RU2).
  List<String> get ultimas5 {
    if (_historial.length <= 5) return List.unmodifiable(_historial);
    return List.unmodifiable(_historial.sublist(_historial.length - 5));
  }

  /// Gira: elige resultado (excluyendo las últimas 5 por string exacto) y
  /// lo registra en el historial. Devuelve UNA NUEVA ruleta; la original
  /// no muta. Cartas vacías → no-op (devuelve `this`).
  Ruleta girar({Random? random}) {
    if (_cartas.isEmpty) return this;
    final rng = random ?? Random();
    final elegida = seleccionarResultado(_cartas, ultimas5, rng);
    return Ruleta._(
      cartas: _cartas,
      resultado: elegida,
      historial: [..._historial, elegida],
    );
  }

  /// Limpia el resultado para el próximo giro; PRESERVA el historial y la
  /// ventana `ultimas5` (R1). Idempotente: sin resultado → `this`.
  Ruleta siguiente() {
    if (_resultado == null) return this;
    return Ruleta._(
      cartas: _cartas,
      resultado: null,
      historial: _historial,
    );
  }
}