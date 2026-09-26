import 'package:flutter_test/flutter_test.dart';

import 'package:paco_game/core/contenido/entidades.dart';
import 'package:paco_game/core/contenido/generos_visibles.dart';

const _normal = Genero(
  nombre: 'Normal',
  cartas: ['n1', 'n2', 'n3'],
);
const _picante = Genero(
  nombre: 'Picante',
  cartas: ['p1', 'p2'],
);

void main() {
  group('generosVisibles (core, YN2/RU6)', () {
    test('modoAlcohol=false → devuelve todos, en orden', () {
      final generos = [_normal, _picante];
      expect(generosVisibles(generos, modoAlcohol: false), generos);
    });

    test('modoAlcohol=true → oculta el género picante (case-insensitive)', () {
      final generos = [_normal, _picante];
      expect(generosVisibles(generos, modoAlcohol: true), [_normal]);

      final mayusculas = [
        _normal,
        const Genero(nombre: 'PICANTE', cartas: ['x']),
        const Genero(nombre: 'Otro', cartas: ['y']),
      ];
      expect(generosVisibles(mayusculas, modoAlcohol: true), [_normal, mayusculas[2]]);
    });

    test('sin género picante → devuelve todo igual (no reordena)', () {
      final generos = [
        const Genero(nombre: 'Normal', cartas: ['a']),
        const Genero(nombre: 'Familiar', cartas: ['b']),
      ];
      expect(generosVisibles(generos, modoAlcohol: true), generos);
    });

    test('lista vacía → vacía (sin crash)', () {
      expect(generosVisibles(const [], modoAlcohol: true), isEmpty);
      expect(generosVisibles(const [], modoAlcohol: false), isEmpty);
    });
  });
}