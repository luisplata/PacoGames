import 'package:flutter/services.dart';

/// Lector de assets inyectable (permite tests sin bundle real).
typedef LeerAsset = Future<String> Function(String path);

Future<String> _leerDeBundle(String path) => rootBundle.loadString(path);

/// Carga el texto crudo de un JSON de contenido desde el bundle.
///
/// La ruta se deriva del id del juego: `assets/content/{juegoId}.json`.
class CargadorContenido {
  const CargadorContenido({LeerAsset leer = _leerDeBundle}) : _leer = leer;

  final LeerAsset _leer;

  Future<String> cargar(String juegoId) => _leer('assets/content/$juegoId.json');
}