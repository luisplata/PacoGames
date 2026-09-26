import 'dart:convert';

import 'entidades.dart';

/// Valida el contenido crudo de los JSON sin dependencias externas.
///
/// Sintaxis: `json.decode` + `FormatException.offset` → línea vía LineIndex.
/// Semántica: búsqueda por ocurrencia en el texto crudo para reportar la
/// línea de la primera ocurrencia del patrón ofensor (D5).
class ValidadorContenido {
  const ValidadorContenido();

  /// Valida todos los archivos `juegoId → texto crudo`.
  ///
  /// Los juegos sin cartas válidas NO entran en `contenidos` (D6):
  /// el selector los mostrará como "sin contenido".
  DiagnosticoContenido validar(Map<String, String> archivos) {
    final contenidos = <String, ContenidoJuego>{};
    final errores = <ErrorContenido>[];

    archivos.forEach((juegoId, texto) {
      final archivo = '$juegoId.json';
      final decoded = _decodificar(juegoId, texto, errores);
      if (decoded == null) return; // error de sintaxis ya reportado

      if (decoded is! Map<String, dynamic>) {
        errores.add(ErrorContenido(
          archivo: archivo,
          linea: 1,
          mensaje: 'formato inválido: se esperaba un objeto con "generos"',
        ));
        return;
      }

      final generosRaw = decoded['generos'];
      if (generosRaw == null) {
        errores.add(ErrorContenido(
          archivo: archivo,
          linea: _lineaDeOcurrencia(texto, '"generos"'),
          mensaje: 'falta "generos"',
        ));
        return;
      }
      if (generosRaw is! List || generosRaw.isEmpty) {
        errores.add(ErrorContenido(
          archivo: archivo,
          linea: _lineaDeOcurrencia(texto, '"generos"'),
          mensaje: '"generos" está vacío o no es una lista',
        ));
        return;
      }

      final generos = <Genero>[];
      final nombresVistos = <String>{};
      for (final g in generosRaw) {
        final genero = _validarGenero(g, texto, archivo, nombresVistos, errores);
        if (genero != null) generos.add(genero);
      }

      // D6: un género sin cartas válidas se descarta; si el juego
      // queda sin ninguno, no aparece en contenidos.
      final generosConCartas = generos.where((g) => g.cartas.isNotEmpty).toList();
      if (generosConCartas.isNotEmpty) {
        contenidos[juegoId] = ContenidoJuego(juegoId: juegoId, generos: generosConCartas);
      }
    });

    return DiagnosticoContenido(contenidos: contenidos, errores: errores);
  }

  Object? _decodificar(String juegoId, String texto, List<ErrorContenido> errores) {
    try {
      return json.decode(texto);
    } on FormatException catch (e) {
      errores.add(ErrorContenido(
        archivo: '$juegoId.json',
        linea: _lineaDeOffset(texto, e.offset),
        mensaje: 'error de sintaxis: ${e.message}',
      ));
      return null;
    }
  }

  Genero? _validarGenero(
    Object? g,
    String texto,
    String archivo,
    Set<String> nombresVistos,
    List<ErrorContenido> errores,
  ) {
    if (g is! Map<String, dynamic>) {
      errores.add(ErrorContenido(
        archivo: archivo,
        linea: _lineaDeOcurrencia(texto, '"generos"'),
        mensaje: 'género inválido: se esperaba un objeto',
      ));
      return null;
    }

    final nombreRaw = g['nombre'];
    final nombre = nombreRaw is String ? nombreRaw.trim() : '';
    if (nombre.isEmpty) {
      errores.add(ErrorContenido(
        archivo: archivo,
        linea: _lineaDeOcurrencia(texto, '"nombre"'),
        mensaje: 'nombre de género vacío',
      ));
      return null;
    }
    if (!nombresVistos.add(nombre)) {
      errores.add(ErrorContenido(
        archivo: archivo,
        linea: _lineaDeOcurrencia(texto, '"nombre": "$nombre"'),
        mensaje: 'nombre de género duplicado: $nombre',
      ));
      return null;
    }

    final listaRaw = g['listaTextoCarta'];
    if (listaRaw is! List || listaRaw.isEmpty) {
      errores.add(ErrorContenido(
        archivo: archivo,
        linea: _lineaDeOcurrencia(texto, '"listaTextoCarta"'),
        mensaje: '"listaTextoCarta" vacía o ausente en "$nombre"',
      ));
      return null;
    }

    final cartas = <String>[];
    for (final c in listaRaw) {
      final value = c is Map<String, dynamic> ? c['value'] : null;
      if (value is! String || value.trim().isEmpty) {
        final needle = value is String ? '"value": "$value"' : '"value"';
        errores.add(ErrorContenido(
          archivo: archivo,
          linea: _lineaDeOcurrencia(texto, needle),
          mensaje: 'carta vacía o inválida en "$nombre"',
        ));
        continue;
      }
      cartas.add(value);
    }

    return Genero(nombre: nombre, cartas: cartas);
  }

  /// Línea (1-based) de la primera ocurrencia de [needle] en [texto].
  int _lineaDeOcurrencia(String texto, String needle) {
    final idx = texto.indexOf(needle);
    if (idx == -1) return 1;
    return _lineaDeOffset(texto, idx);
  }

  /// Línea (1-based) en la que cae un offset, vía LineIndex.
  /// Si el offset es nulo (casos sin posición conocida), cae en la línea 1.
  int _lineaDeOffset(String texto, int? offset) {
    final clamped = offset == null ? 0 : (offset < 0 ? 0 : (offset > texto.length ? texto.length : offset));
    return texto.substring(0, clamped).split('\n').length;
  }
}