import 'dart:math';

/// Mazo de cartas puro e inmutable para Yo Nunca (D1).
///
/// Sin imports de Flutter a propósito: la mecánica es dominio puro y
/// testeable con seed. Fisher-Yates sobre una COPIA de la lista original
/// (nunca la muta). "Sin repetir hasta agotar" es la semántica natural
/// del recorrido indexado + remezcla explícita (D2).
class Mazo {
  const Mazo._({
    required List<String> cartas,
    required int indice,
    required List<String> historial,
  })  : _cartas = cartas,
        _indice = indice,
        _historial = historial;

  /// Baraja [cartas] (copia, Fisher-Yates) y deja la primera carta lista
  /// para verse sin tap extra (D3). [random] inyectable para determinismo.
  factory Mazo.barajar(List<String> cartas, {Random? random}) {
    final rng = random ?? Random();
    final barajadas = List.of(cartas);
    for (var i = barajadas.length - 1; i > 0; i--) {
      final j = rng.nextInt(i + 1);
      final tmp = barajadas[i];
      barajadas[i] = barajadas[j];
      barajadas[j] = tmp;
    }
    return Mazo._(
      cartas: barajadas,
      indice: 0,
      historial: barajadas.isEmpty ? const [] : [barajadas.first],
    );
  }

  /// Lista barajada interna: NUNCA se muta tras la construcción, por eso
  /// los estados derivados pueden compartirla sin riesgo (D1).
  final List<String> _cartas;
  final int _indice;
  final List<String> _historial;

  /// Carta actual: la primera del mazo tras barajar, `null` si agotado.
  String? get cartaActual => agotado ? null : _cartas[_indice];

  /// `true` cuando el recorrido terminó (o el mazo nació vacío).
  bool get agotado => _indice >= _cartas.length;

  /// Cartas ya mostradas, en orden, INCLUYENDO la actual (D3).
  List<String> get historial => List.unmodifiable(_historial);

  /// Avanza una carta. Idempotente en agotado y NO auto-remezcla (D2):
  /// agotado es un estado terminal estable hasta `remezclar()` explícita.
  Mazo siguiente() {
    if (agotado) return this;
    final nuevoIndice = _indice + 1;
    if (nuevoIndice >= _cartas.length) {
      return Mazo._(cartas: _cartas, indice: nuevoIndice, historial: _historial);
    }
    return Mazo._(
      cartas: _cartas,
      indice: nuevoIndice,
      historial: [..._historial, _cartas[nuevoIndice]],
    );
  }

  /// Re-baraja las MISMAS cartas del mazo: índice 0, historial = [carta0].
  /// Acción explícita del usuario ([Mezclar de nuevo]), nunca automática.
  Mazo remezclar({Random? random}) => Mazo.barajar(_cartas, random: random);
}