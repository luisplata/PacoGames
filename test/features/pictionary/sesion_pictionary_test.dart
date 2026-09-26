import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:paco_game/features/pictionary/application/sesion_pictionary.dart';

/// Deck espejo del JSON real: 201 strings distintos + 'Pintar' duplicado
/// (la dedupe por string exacto NUNCA debe ofrecer 'Pintar' 2 veces).
List<String> deckReal() => [
      for (var i = 0; i < 200; i++) 'Palabra $i',
      'Pintar',
      'Pintar',
    ];

void main() {
  group('SesionPictionary.iniciar', () {
    test('devuelve marcador 0-0, turno 1, sin palabras', () {
      final sesion = SesionPictionary.iniciar();
      expect(sesion.marcadorA, 0);
      expect(sesion.marcadorB, 0);
      expect(sesion.turnoDibujante, 1);
      expect(sesion.palabrasUsadas, isEmpty);
      expect(sesion.palabrasActuales, isEmpty);
    });
  });

  group('sortearPalabras', () {
    test('sortea 3 palabras DISTINTAS del deck con seed (set length 3)', () {
      final sesion = SesionPictionary.iniciar();
      final resultado = sesion.sortearPalabras(deckReal(), random: Random(7));

      expect(resultado.palabrasActuales, hasLength(3));
      expect(resultado.palabrasActuales.toSet(), hasLength(3)); // sin duplicados
      for (final p in resultado.palabrasActuales) {
        expect(deckReal(), contains(p)); // ∈ deck
      }
    });

    test("dedupe por string: 'Pintar' x2 del JSON real nunca 2 opciones", () {
      final sesion = SesionPictionary.iniciar();

      // Barre varias seeds: en NINGUNA 'Pintar' aparece más de una vez.
      for (var seed = 0; seed < 20; seed++) {
        final resultado = sesion.sortearPalabras(deckReal(), random: Random(seed));
        expect(
          resultado.palabrasActuales.where((p) => p == 'Pintar'),
          hasLength(lessThanOrEqualTo(1)),
        );
      }
    });

    test('las 3 mostradas se consumen → la siguiente ronda no las repite '
        '(deck 6, sin remezcla)', () {
      const deck = ['A', 'B', 'C', 'D', 'E', 'F'];
      final sesion = SesionPictionary.iniciar();

      final primera = sesion.sortearPalabras(deck, random: Random(3));
      final conConsumo = primera.consumirPalabras(primera.palabrasActuales);

      final segunda = conConsumo.sortearPalabras(deck, random: Random(3));
      expect(segunda.palabrasActuales, hasLength(3));
      for (final p in segunda.palabrasActuales) {
        expect(primera.palabrasActuales, isNot(contains(p))); // nunca repetir en sesión
      }
    });

    test('pool < 3 → remezcla automática (reset usadas, sortea del set '
        'completo sin deadlock)', () {
      const deck = ['A', 'B', 'C', 'D'];
      final sesion = SesionPictionary.iniciar();

      // 1ª ronda: 3 consumidas → usadas = 3 → disponible = 1 → remezcla.
      final primera = sesion.sortearPalabras(deck, random: Random(1));
      final trasRonda1 =
          primera.consumirPalabras(primera.palabrasActuales);
      expect(trasRonda1.palabrasUsadas, hasLength(3));

      // 2ª ronda: pool < 3 → usadas se resetea y sortea 3 del set completo.
      final segunda = trasRonda1.sortearPalabras(deck, random: Random(1));
      expect(segunda.palabrasActuales, hasLength(3));
      expect(segunda.palabrasUsadas, isEmpty); // usadas reset
      for (final p in segunda.palabrasActuales) {
        expect(deck, contains(p));
      }
    });

    test('defensivo deck 2 → sortea 2 (lo que haya, sin deadlock)', () {
      const deck = ['X', 'Y'];
      final resultado = SesionPictionary.iniciar()
          .sortearPalabras(deck, random: Random(5));

      expect(resultado.palabrasActuales, hasLength(2));
      expect(resultado.palabrasActuales.toSet(), {'X', 'Y'});
    });

    test('defensivo deck 1 → sortea 1 (lo que haya, sin deadlock)', () {
      const deck = ['Sola'];
      final resultado = SesionPictionary.iniciar()
          .sortearPalabras(deck, random: Random(5));

      expect(resultado.palabrasActuales, ['Sola']);
    });

    test('defensivo deck 0 → no-op (devuelve this, sin crash, sin palabras)',
        () {
      final sesion = SesionPictionary.iniciar();
      final resultado = sesion.sortearPalabras(const [], random: Random(5));

      expect(identical(resultado, sesion), isTrue); // no-op
      expect(resultado.palabrasActuales, isEmpty);
    });
  });

  group('consumirPalabras', () {
    test('agrega a palabrasUsadas (las 3 que el dibujante vio)', () {
      final sesion = SesionPictionary.iniciar();
      final consumida = sesion.consumirPalabras(['Pintar', 'Rosa', 'Timbal']);

      expect(consumida.palabrasUsadas, ['Pintar', 'Rosa', 'Timbal']);
    });
  });

  group('marcador y turno', () {
    test('marcarPuntoA → +1 solo a A', () {
      final sesion = SesionPictionary.iniciar();
      final conPunto = sesion.marcarPuntoA();

      expect(conPunto.marcadorA, 1);
      expect(conPunto.marcadorB, 0);
    });

    test('marcarPuntoB → +1 solo a B', () {
      final sesion = SesionPictionary.iniciar();
      final conPunto = sesion.marcarPuntoB();

      expect(conPunto.marcadorA, 0);
      expect(conPunto.marcadorB, 1);
    });

    test('siguienteDibujante → turno+1 sin tocar el marcador', () {
      final sesion = SesionPictionary.iniciar().marcarPuntoA();
      final siguiente = sesion.siguienteDibujante();

      expect(siguiente.turnoDibujante, 2);
      expect(siguiente.marcadorA, 1);
      expect(siguiente.marcadorB, 0);
    });

    test('nuevaRonda → limpia palabrasActuales, conserva marcador+turno+usadas',
        () {
      final sesion = SesionPictionary.iniciar()
          .sortearPalabras(['A', 'B', 'C'], random: Random(1))
          .consumirPalabras(['A', 'B', 'C'])
          .marcarPuntoB()
          .siguienteDibujante();

      final nueva = sesion.nuevaRonda();
      expect(nueva.palabrasActuales, isEmpty);
      expect(nueva.marcadorA, 0);
      expect(nueva.marcadorB, 1);
      expect(nueva.turnoDibujante, 2);
      expect(nueva.palabrasUsadas, ['A', 'B', 'C']);
    });
  });

  group('inmutabilidad', () {
    test('las operaciones devuelven NUEVA sesión; la original no muta', () {
      final original = SesionPictionary.iniciar();
      final mutada = original
          .sortearPalabras(['A', 'B', 'C'], random: Random(1))
          .consumirPalabras(['A', 'B', 'C'])
          .marcarPuntoA()
          .siguienteDibujante();

      expect(mutada.marcadorA, 1);
      expect(mutada.turnoDibujante, 2);
      expect(mutada.palabrasUsadas, ['A', 'B', 'C']);

      // La original quedó intacta.
      expect(original.marcadorA, 0);
      expect(original.marcadorB, 0);
      expect(original.turnoDibujante, 1);
      expect(original.palabrasUsadas, isEmpty);
      expect(original.palabrasActuales, isEmpty);
    });

    test('getters inmutables: mutar las listas lanza', () {
      final sesion = SesionPictionary.iniciar()
          .sortearPalabras(['A', 'B', 'C'], random: Random(1));

      expect(() => sesion.palabrasActuales.add('X'), throwsUnsupportedError);
      expect(() => sesion.palabrasUsadas.add('X'), throwsUnsupportedError);
    });
  });
}