import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:paco_game/core/contenido/entidades.dart';
import 'package:paco_game/core/contenido/validador_contenido.dart';
import 'package:paco_game/features/yo_nunca/application/carta_yo_nunca.dart';

const _normal = Genero(nombre: 'Normal', cartas: ['n1', 'n2', 'n3']);
const _picante = Genero(nombre: 'Picante', cartas: ['p1', 'p2']);

List<String> _textos(List<CartaYoNunca> cartas) => [
      for (final carta in cartas) carta.texto,
    ];

void main() {
  group('cartasDelNivel — nivel Normal', () {
    test('devuelve solo las cartas Normal, sin Picante', () {
      final cartas = cartasDelNivel(
        [_normal, _picante],
        nivel: NivelYoNunca.normal,
        modoAlcohol: false,
      );

      expect(_textos(cartas), ['n1', 'n2', 'n3']);
      expect(cartas.every((c) => c.nivel == NivelYoNunca.normal), isTrue);
    });

    test('sin género Picante degrada a Normal (no rompe)', () {
      final cartas = cartasDelNivel(
        [_normal],
        nivel: NivelYoNunca.normal,
        modoAlcohol: false,
      );

      expect(_textos(cartas), ['n1', 'n2', 'n3']);
    });

    test('sin géneros → lista vacía (edge defensivo)', () {
      final cartas = cartasDelNivel(
        const [],
        nivel: NivelYoNunca.normal,
        modoAlcohol: false,
      );

      expect(cartas, isEmpty);
    });

    test('normaliza el nombre del género (trim + case)', () {
      const normalRaro = Genero(nombre: '  nOrMaL ', cartas: ['n1']);
      final cartas = cartasDelNivel(
        [normalRaro],
        nivel: NivelYoNunca.normal,
        modoAlcohol: false,
      );

      expect(_textos(cartas), ['n1']);
    });

    test('ignora géneros desconocidos', () {
      const otro = Genero(nombre: 'Otro', cartas: ['x1', 'x2']);
      final cartas = cartasDelNivel(
        [otro, _normal],
        nivel: NivelYoNunca.normal,
        modoAlcohol: false,
      );

      expect(_textos(cartas), ['n1', 'n2', 'n3']);
    });
  });

  group('cartasDelNivel — nivel Picante', () {
    test('es aditivo: Normal + Picante, cada carta conserva su nivel', () {
      // Invertir el orden de los géneros prueba que busca por nombre.
      final cartas = cartasDelNivel(
        [_picante, _normal],
        nivel: NivelYoNunca.picante,
        modoAlcohol: false,
      );

      expect(cartas.length, 5);
      expect(_textos(cartas).toSet(), {'n1', 'n2', 'n3', 'p1', 'p2'});
      expect(
        cartas.where((c) => c.nivel == NivelYoNunca.normal).map((c) => c.texto),
        unorderedEquals(['n1', 'n2', 'n3']),
      );
      expect(
        cartas
            .where((c) => c.nivel == NivelYoNunca.picante)
            .map((c) => c.texto),
        unorderedEquals(['p1', 'p2']),
      );
    });

    test('dedupe por texto exacto: gana la primera ocurrencia (Normal)', () {
      const normal = Genero(nombre: 'Normal', cartas: ['x', 'n2']);
      const picante = Genero(nombre: 'Picante', cartas: ['x', 'p2']);

      final cartas = cartasDelNivel(
        [normal, picante],
        nivel: NivelYoNunca.picante,
        modoAlcohol: false,
      );

      expect(cartas.length, 3);
      final equis = cartas.where((c) => c.texto == 'x').toList();
      expect(equis.length, 1);
      expect(equis.single.nivel, NivelYoNunca.normal);
    });

    test('Picante ausente degrada a Normal (nunca mazo vacío por nivel)', () {
      final cartas = cartasDelNivel(
        [_normal],
        nivel: NivelYoNunca.picante,
        modoAlcohol: false,
      );

      expect(_textos(cartas), ['n1', 'n2', 'n3']);
      expect(cartas.every((c) => c.nivel == NivelYoNunca.normal), isTrue);
    });
  });

  group('cartasDelNivel — modo sin alcohol', () {
    test('modoAlcohol fuerza Normal aunque se pida Picante', () {
      final cartas = cartasDelNivel(
        [_normal, _picante],
        nivel: NivelYoNunca.picante,
        modoAlcohol: true,
      );

      expect(_textos(cartas), ['n1', 'n2', 'n3']);
      expect(cartas.every((c) => c.nivel == NivelYoNunca.normal), isTrue);
    });
  });

  group('cartasDelNivel — contenido real vendored', () {
    test('Picante = 80 Normal + 66 Picante = 146 sin repetir', () {
      final texto = File('assets/content/yo_nunca.json').readAsStringSync();
      final diagnostico =
          const ValidadorContenido().validar({'yo_nunca': texto});
      final generos = diagnostico.contenidos['yo_nunca']!.generos;

      final cartas = cartasDelNivel(
        generos,
        nivel: NivelYoNunca.picante,
        modoAlcohol: false,
      );

      expect(cartas.length, 146);
      expect(
        cartas.where((c) => c.nivel == NivelYoNunca.normal).length,
        80,
      );
      expect(
        cartas.where((c) => c.nivel == NivelYoNunca.picante).length,
        66,
      );
      expect(cartas.map((c) => c.texto).toSet().length, 146,
          reason: 'ningún texto se repite');
    });
  });

  group('CartaYoNunca', () {
    test('igualdad por texto + nivel', () {
      const a = CartaYoNunca(texto: 'x', nivel: NivelYoNunca.normal);
      const b = CartaYoNunca(texto: 'x', nivel: NivelYoNunca.normal);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('mismo texto con distinto nivel NO es igual', () {
      const a = CartaYoNunca(texto: 'x', nivel: NivelYoNunca.normal);
      const b = CartaYoNunca(texto: 'x', nivel: NivelYoNunca.picante);

      expect(a, isNot(b));
    });
  });

  group('nivelEfectivo', () {
    test('modo sin alcohol fuerza Normal', () {
      expect(
        nivelEfectivo(elegido: NivelYoNunca.picante, modoAlcohol: true),
        NivelYoNunca.normal,
      );
    });

    test('sin modo sin alcohol respeta el nivel elegido', () {
      expect(
        nivelEfectivo(elegido: NivelYoNunca.picante, modoAlcohol: false),
        NivelYoNunca.picante,
      );
      expect(
        nivelEfectivo(elegido: NivelYoNunca.normal, modoAlcohol: false),
        NivelYoNunca.normal,
      );
    });
  });
}
