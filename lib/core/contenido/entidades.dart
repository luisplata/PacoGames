/// Entidades del dominio de contenido: qué es un juego, un género
/// y cómo se reportan los problemas detectados al validar.
library;

/// Un género dentro de un juego (ej: Normal, Picante).
class Genero {
  const Genero({required this.nombre, required this.cartas});

  final String nombre;
  final List<String> cartas;
}

/// Contenido completo de un juego: sus géneros y cartas.
class ContenidoJuego {
  const ContenidoJuego({required this.juegoId, required this.generos});

  final String juegoId;
  final List<Genero> generos;

  /// El juego es jugable si al menos un género tiene cartas.
  bool get tieneCartas => generos.any((g) => g.cartas.isNotEmpty);
}

/// Error detectado al cargar/validar el contenido de un archivo.
///
/// [linea] es 1-based; `0` significa "error de archivo" (no se pudo leer).
class ErrorContenido {
  const ErrorContenido({
    required this.archivo,
    required this.linea,
    required this.mensaje,
  });

  final String archivo;
  final int linea;
  final String mensaje;
}

/// Resultado de cargar y validar todo el contenido vendored.
class DiagnosticoContenido {
  const DiagnosticoContenido({
    required this.contenidos,
    required this.errores,
  });

  /// Juegos con contenido válido, por `juegoId`.
  ///
  /// Los juegos sin cartas válidas NO aparecen acá (el selector los
  /// muestra como "sin contenido").
  final Map<String, ContenidoJuego> contenidos;

  /// Errores detectados (sintaxis, semántica o lectura), nunca nulos.
  final List<ErrorContenido> errores;

  bool get hayErrores => errores.isNotEmpty;
}