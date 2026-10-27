import '../../../core/contenido/entidades.dart';

/// Nivel de una partida de Yo Nunca (YN10).
enum NivelYoNunca { normal, picante }

/// Nivel efectivo de la partida: el modo sin alcohol siempre fuerza Normal
/// (D4). Una sola verdad para el mazo, el chip y las reglas.
NivelYoNunca nivelEfectivo({
  required NivelYoNunca elegido,
  required bool modoAlcohol, // true = modo sin alcohol
}) =>
    modoAlcohol ? NivelYoNunca.normal : elegido;

/// Carta de Yo Nunca con su nivel de origen: el nivel viaja con la carta
/// para pintar el dorso correcto (D1/D2).
class CartaYoNunca {
  const CartaYoNunca({required this.texto, required this.nivel});

  /// `value` CRUDO del JSON, sin prefijo ni reescritura.
  final String texto;
  final NivelYoNunca nivel;

  @override
  bool operator ==(Object other) =>
      other is CartaYoNunca && other.texto == texto && other.nivel == nivel;

  @override
  int get hashCode => Object.hash(texto, nivel);

  @override
  String toString() => 'CartaYoNunca(${nivel.name}: $texto)';
}

/// Compone el mazo de un nivel (YN10):
///
/// 1. Modo sin alcohol (`modoAlcohol == true`) fuerza Normal.
/// 2. Géneros por nombre `trim` + `lower`: `normal` / `picante`; el resto
///    se ignora.
/// 3. Normal → solo cartas Normal (sin género Normal → `[]`).
/// 4. Picante → Normal + Picante concatenados, deduplicados por texto EXACTO
///    conservando la primera ocurrencia (gana Normal). Picante ausente →
///    degrada a Normal.
/// 5. Sin géneros/contenido → `[]` (defensivo, sin crash).
List<CartaYoNunca> cartasDelNivel(
  List<Genero> generos, {
  required NivelYoNunca nivel,
  required bool modoAlcohol,
}) {
  final efectivo = nivelEfectivo(elegido: nivel, modoAlcohol: modoAlcohol);

  final normales = _cartasDelGenero(generos, 'normal');
  final picantes = _cartasDelGenero(generos, 'picante');

  final cartas = <CartaYoNunca>[
    for (final texto in normales)
      CartaYoNunca(texto: texto, nivel: NivelYoNunca.normal),
  ];

  if (efectivo == NivelYoNunca.picante) {
    final vistos = normales.toSet();
    for (final texto in picantes) {
      if (vistos.add(texto)) {
        cartas.add(CartaYoNunca(texto: texto, nivel: NivelYoNunca.picante));
      }
    }
  }

  return cartas;
}

/// Cartas del género por nombre normalizado; ausente → `[]`.
List<String> _cartasDelGenero(List<Genero> generos, String nombre) {
  for (final genero in generos) {
    if (genero.nombre.trim().toLowerCase() == nombre) return genero.cartas;
  }
  return const [];
}
