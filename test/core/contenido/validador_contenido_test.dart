import 'package:flutter_test/flutter_test.dart';

import 'package:paco_game/core/contenido/validador_contenido.dart';

void main() {
  const validador = ValidadorContenido();

  group('ValidadorContenido.validar', () {
    test('JSON sano → 0 errores, géneros y cartas parseados', () {
      const texto = '''
{
  "generos": [
    {
      "nombre": "Normal",
      "listaTextoCarta": [
        {"value": "Tomás un trago"},
        {"value": "Un beso"}
      ]
    },
    {
      "nombre": "Picante",
      "listaTextoCarta": [
        {"value": "Hacé un trío"}
      ]
    }
  ]
}''';

      final d = validador.validar({'yo_nunca': texto});

      expect(d.hayErrores, isFalse);
      expect(d.errores, isEmpty);
      final juego = d.contenidos['yo_nunca'];
      expect(juego, isNotNull);
      expect(juego!.generos, hasLength(2));
      expect(juego.generos[0].nombre, 'Normal');
      expect(juego.generos[0].cartas, ['Tomás un trago', 'Un beso']);
      expect(juego.generos[1].nombre, 'Picante');
      expect(juego.generos[1].cartas, ['Hacé un trío']);
      expect(juego.tieneCartas, isTrue);
    });

    test('sintaxis rota → error con línea exacta vía LineIndex', () {
      const texto = '{\n  "generos": [\n    {\n      nombre: "Normal"\n    }\n  ]\n}';

      final d = validador.validar({'ruleta': texto});

      expect(d.hayErrores, isTrue);
      expect(d.errores, hasLength(1));
      expect(d.errores[0].archivo, 'ruleta.json');
      expect(d.errores[0].linea, 4);
      expect(d.errores[0].mensaje, contains('sintaxis'));
      expect(d.contenidos.containsKey('ruleta'), isFalse);
    });

    test('JSON válido pero no es un objeto → error de formato', () {
      final d = validador.validar({'ruleta': '[1, 2, 3]'});

      expect(d.hayErrores, isTrue);
      expect(d.errores, hasLength(1));
      expect(d.errores[0].archivo, 'ruleta.json');
      expect(d.errores[0].mensaje, contains('formato'));
      expect(d.contenidos.containsKey('ruleta'), isFalse);
    });

    test('generos ausente → error y juego sin contenido', () {
      final d = validador.validar({'yo_nunca': '{"otra": 1}'});

      expect(d.hayErrores, isTrue);
      expect(d.errores, hasLength(1));
      expect(d.errores[0].archivo, 'yo_nunca.json');
      expect(d.errores[0].mensaje, contains('generos'));
      expect(d.contenidos, isEmpty);
    });

    test('generos no es una lista → error en la línea de la clave', () {
      const texto = '{\n  "generos": "Normal"\n}';

      final d = validador.validar({'yo_nunca': texto});

      expect(d.hayErrores, isTrue);
      expect(d.errores, hasLength(1));
      expect(d.errores[0].linea, 2);
      expect(d.errores[0].mensaje, contains('generos'));
      expect(d.contenidos, isEmpty);
    });

    test('generos vacío → error y juego sin contenido', () {
      const texto = '{\n  "generos": []\n}';

      final d = validador.validar({'yo_nunca': texto});

      expect(d.hayErrores, isTrue);
      expect(d.errores, hasLength(1));
      expect(d.errores[0].linea, 2);
      expect(d.errores[0].mensaje, contains('vac'));
      expect(d.contenidos, isEmpty);
    });

    test('nombre de género vacío → error y género descartado', () {
      const texto = '''
{
  "generos": [
    {
      "nombre": "",
      "listaTextoCarta": [
        {"value": "A"}
      ]
    }
  ]
}''';

      final d = validador.validar({'yo_nunca': texto});

      expect(d.hayErrores, isTrue);
      expect(d.errores, hasLength(1));
      expect(d.errores[0].linea, 4);
      expect(d.errores[0].mensaje, contains('nombre'));
      expect(d.contenidos, isEmpty);
    });

    test('nombre de género duplicado → error en 1ª ocurrencia, duplicado descartado', () {
      const texto = '''
{
  "generos": [
    {
      "nombre": "Normal",
      "listaTextoCarta": [{"value": "A"}]
    },
    {
      "nombre": "Normal",
      "listaTextoCarta": [{"value": "B"}]
    }
  ]
}''';

      final d = validador.validar({'yo_nunca': texto});

      expect(d.hayErrores, isTrue);
      expect(d.errores, hasLength(1));
      expect(d.errores[0].linea, 4);
      expect(d.errores[0].mensaje, contains('duplicado'));
      final juego = d.contenidos['yo_nunca'];
      expect(juego, isNotNull);
      expect(juego!.generos, hasLength(1));
      expect(juego.generos[0].nombre, 'Normal');
      expect(juego.generos[0].cartas, ['A']);
    });

    test('listaTextoCarta vacía → error y género descartado', () {
      const texto = '''
{
  "generos": [
    {
      "nombre": "Normal",
      "listaTextoCarta": []
    }
  ]
}''';

      final d = validador.validar({'yo_nunca': texto});

      expect(d.hayErrores, isTrue);
      expect(d.errores, hasLength(1));
      expect(d.errores[0].linea, 5);
      expect(d.errores[0].mensaje, contains('listaTextoCarta'));
      expect(d.contenidos, isEmpty);
    });

    test('value vacío tras trim → error en la línea exacta y carta descartada', () {
      const texto = '''
{
  "generos": [
    {
      "nombre": "Normal",
      "listaTextoCarta": [
        {"value": "ok"},
        {"value": "   "},
        {"value": "mal"}
      ]
    }
  ]
}''';

      final d = validador.validar({'yo_nunca': texto});

      expect(d.hayErrores, isTrue);
      expect(d.errores, hasLength(1));
      expect(d.errores[0].linea, 7);
      expect(d.errores[0].mensaje, contains('carta'));
      final juego = d.contenidos['yo_nunca'];
      expect(juego, isNotNull);
      expect(juego!.generos[0].cartas, ['ok', 'mal']);
    });

    test('género sin cartas válidas → descartado; las dos cartas vacías se reportan', () {
      const texto = '''
{
  "generos": [
    {
      "nombre": "Vacio",
      "listaTextoCarta": [
        {"value": "   "},
        {"value": ""}
      ]
    },
    {
      "nombre": "Normal",
      "listaTextoCarta": [{"value": "A"}]
    }
  ]
}''';

      final d = validador.validar({'yo_nunca': texto});

      expect(d.hayErrores, isTrue);
      expect(d.errores, hasLength(2));
      expect(d.errores[0].linea, 6);
      expect(d.errores[1].linea, 7);
      final juego = d.contenidos['yo_nunca'];
      expect(juego, isNotNull);
      expect(juego!.generos, hasLength(1));
      expect(juego.generos[0].nombre, 'Normal');
      expect(juego.generos[0].cartas, ['A']);
    });

    test('value no string (número) → error y carta descartada', () {
      const texto = '''
{
  "generos": [
    {
      "nombre": "Normal",
      "listaTextoCarta": [
        {"value": 42},
        {"value": "ok"}
      ]
    }
  ]
}''';

      final d = validador.validar({'yo_nunca': texto});

      expect(d.hayErrores, isTrue);
      expect(d.errores, hasLength(1));
      expect(d.errores[0].mensaje, contains('carta'));
      final juego = d.contenidos['yo_nunca'];
      expect(juego, isNotNull);
      expect(juego!.generos[0].cartas, ['ok']);
    });

    test('cartas duplicadas ponderan: se conservan sin dedup', () {
      const texto = '''
{
  "generos": [
    {
      "nombre": "Normal",
      "listaTextoCarta": [
        {"value": "Volvés a girar"},
        {"value": "Volvés a girar"}
      ]
    }
  ]
}''';

      final d = validador.validar({'ruleta': texto});

      expect(d.hayErrores, isFalse);
      final juego = d.contenidos['ruleta'];
      expect(juego, isNotNull);
      expect(juego!.generos[0].cartas, ['Volvés a girar', 'Volvés a girar']);
    });

    test('múltiples archivos: sano y roto se procesan independientemente', () {
      const sano = '{"generos": [{"nombre": "Normal", "listaTextoCarta": [{"value": "A"}]}]}';
      const roto = '{generos: [';

      final d = validador.validar({'yo_nunca': sano, 'ruleta': roto});

      expect(d.hayErrores, isTrue);
      expect(d.errores, hasLength(1));
      expect(d.errores[0].archivo, 'ruleta.json');
      expect(d.contenidos.keys, ['yo_nunca']);
      expect(d.contenidos['yo_nunca']!.generos[0].cartas, ['A']);
    });
  });
}