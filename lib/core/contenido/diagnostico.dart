import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cargador_contenido.dart';
import 'entidades.dart';
import 'validador_contenido.dart';

/// Los 3 juegos vendored en `assets/content/`.
const juegoIds = ['yo_nunca', 'ruleta', 'pictionary'];

final cargadorContenidoProvider = Provider<CargadorContenido>(
  (ref) => const CargadorContenido(),
);

final validadorContenidoProvider = Provider<ValidadorContenido>(
  (ref) => const ValidadorContenido(),
);

/// Carga y valida todo el contenido una sola vez.
final diagnosticoContenidoProvider = FutureProvider<DiagnosticoContenido>(
  (ref) => cargarYValidarContenido(
    ref.watch(cargadorContenidoProvider),
    ref.watch(validadorContenidoProvider),
    juegoIds,
  ),
);

/// Carga y valida los juegos pedidos. NUNCA lanza: un archivo que no se
/// puede leer se reporta como `ErrorContenido(linea: 0)` y los demás
/// siguen cargando (R5).
Future<DiagnosticoContenido> cargarYValidarContenido(
  CargadorContenido cargador,
  ValidadorContenido validador,
  List<String> ids,
) async {
  final errores = <ErrorContenido>[];
  final archivos = <String, String>{};

  for (final id in ids) {
    try {
      archivos[id] = await cargador.cargar(id);
    } catch (e) {
      errores.add(ErrorContenido(
        archivo: '$id.json',
        linea: 0,
        mensaje: 'no se pudo leer: $e',
      ));
    }
  }

  final diagnostico = validador.validar(archivos);
  return DiagnosticoContenido(
    contenidos: diagnostico.contenidos,
    errores: [...errores, ...diagnostico.errores],
  );
}