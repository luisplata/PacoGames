import 'package:flutter_test/flutter_test.dart';

import 'package:paco_game/core/contenido/cargador_contenido.dart';
import 'package:paco_game/core/contenido/diagnostico.dart';
import 'package:paco_game/core/contenido/validador_contenido.dart';

void main() {
  const validador = ValidadorContenido();

  const sano = '''
{
  "generos": [
    {
      "nombre": "Normal",
      "listaTextoCarta": [{"value": "A"}, {"value": "B"}]
    }
  ]
}''';

  group('cargarYValidarContenido', () {
    test('1 archivo roto + 2 sanos → errores solo del roto, los otros cargan', () async {
      final cargador = CargadorContenido(
        leer: (path) async {
          if (path == 'assets/content/ruleta.json') return '{generos: [';
          return sano;
        },
      );

      final d = await cargarYValidarContenido(
        cargador,
        validador,
        ['yo_nunca', 'ruleta', 'pictionary'],
      );

      expect(d.hayErrores, isTrue);
      expect(d.errores, hasLength(1));
      expect(d.errores[0].archivo, 'ruleta.json');
      expect(d.contenidos.keys, containsAll(['yo_nunca', 'pictionary']));
      expect(d.contenidos.containsKey('ruleta'), isFalse);
    });

    test('archivo faltante → error con linea 0 "no se pudo leer"', () async {
      final cargador = CargadorContenido(
        leer: (path) async => throw Exception('asset no encontrado: $path'),
      );

      final d = await cargarYValidarContenido(cargador, validador, ['yo_nunca']);

      expect(d.hayErrores, isTrue);
      expect(d.errores, hasLength(1));
      expect(d.errores[0].archivo, 'yo_nunca.json');
      expect(d.errores[0].linea, 0);
      expect(d.errores[0].mensaje, contains('no se pudo leer'));
      expect(d.contenidos, isEmpty);
    });

    test('juego sin cartas válidas → ausente de contenidos (sin contenido)', () async {
      final cargador = CargadorContenido(
        leer: (path) async =>
            '{"generos": [{"nombre": "Normal", "listaTextoCarta": [{"value": "  "}]}]}',
      );

      final d = await cargarYValidarContenido(cargador, validador, ['yo_nunca']);

      expect(d.hayErrores, isTrue);
      expect(d.contenidos.containsKey('yo_nunca'), isFalse);
    });
  });

  group('juegoIds', () {
    test('los 3 juegos vendored', () {
      expect(juegoIds, ['yo_nunca', 'ruleta', 'pictionary']);
    });
  });
}