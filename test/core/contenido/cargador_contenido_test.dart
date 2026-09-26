import 'package:flutter_test/flutter_test.dart';

import 'package:paco_game/core/contenido/cargador_contenido.dart';

void main() {
  group('CargadorContenido', () {
    test('carga assets/content/{juegoId}.json vía lector inyectado', () async {
      final rutas = <String>[];
      final cargador = CargadorContenido(
        leer: (path) async {
          rutas.add(path);
          return '{"generos": []}';
        },
      );

      final texto = await cargador.cargar('yo_nunca');

      expect(texto, '{"generos": []}');
      expect(rutas, ['assets/content/yo_nunca.json']);
    });

    test('propaga el error del lector si el archivo falta', () async {
      final cargador = CargadorContenido(
        leer: (path) async => throw Exception('asset no encontrado: $path'),
      );

      expect(
        () => cargador.cargar('no_existe'),
        throwsA(isA<Exception>()),
      );
    });
  });
}