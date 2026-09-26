import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:paco_game/features/yo_nunca/application/mazo.dart';

void main() {
  group('Mazo.barajar', () {
    test('produce una permutación exacta de las cartas (multiset igual, sin dups)',
        () {
      const cartas = ['a', 'b', 'c', 'd', 'e'];
      final mazo = Mazo.barajar(cartas, random: Random(42));

      final salidas = <String>[];
      var actual = mazo;
      while (!actual.agotado) {
        salidas.add(actual.cartaActual!);
        actual = actual.siguiente();
      }

      expect(salidas.length, cartas.length);
      expect(salidas.toSet().length, cartas.length, reason: 'sin repetir');
      expect(salidas.toSet(), cartas.toSet(), reason: 'mismas cartas');
    });

    test('no muta la lista original', () {
      final cartas = ['a', 'b', 'c', 'd', 'e', 'f', 'g'];
      final copia = List.of(cartas);
      Mazo.barajar(cartas, random: Random(7));
      expect(cartas, copia);
    });

    test('mismo seed → mismo orden; distinto seed → distinto orden (n>=20)',
        () {
      final cartas = List.generate(24, (i) => 'carta $i');
      final a = Mazo.barajar(cartas, random: Random(11));
      final b = Mazo.barajar(cartas, random: Random(11));
      final c = Mazo.barajar(cartas, random: Random(22));

      List<String> ordenCompleto(Mazo m) {
        final out = <String>[m.cartaActual!];
        var actual = m;
        while (!actual.agotado) {
          actual = actual.siguiente();
          if (!actual.agotado) out.add(actual.cartaActual!);
        }
        return out;
      }

      expect(ordenCompleto(a), ordenCompleto(b), reason: 'mismo seed');
      expect(ordenCompleto(a), isNot(ordenCompleto(c)), reason: 'distinto seed');
    });
  });

  group('Mazo — recorrido', () {
    test('cartaActual es la primera carta tras barajar (frase visible sin tap)',
        () {
      final mazo = Mazo.barajar(['a', 'b', 'c'], random: Random(1));
      expect(mazo.agotado, isFalse);
      expect(mazo.cartaActual, isNotNull);
      expect(mazo.cartaActual, isIn(['a', 'b', 'c']));
    });

    test('ciclo completo: cada carta sale exactamente 1 vez y agota al final',
        () {
      const cartas = ['a', 'b', 'c', 'd', 'e'];
      final mazo = Mazo.barajar(cartas, random: Random(99));

      final vistas = <String>{mazo.cartaActual!};
      var actual = mazo;
      var pasos = 0;
      while (!actual.agotado) {
        actual = actual.siguiente();
        pasos++;
        if (!actual.agotado) {
          expect(vistas, isNot(contains(actual.cartaActual)),
              reason: 'no se repite dentro del ciclo');
          vistas.add(actual.cartaActual!);
        }
      }

      expect(pasos, cartas.length);
      expect(vistas, cartas.toSet());
      expect(actual.agotado, isTrue);
      expect(actual.cartaActual, isNull);
    });

    test('agotado: mazo fresco no está agotado; vacío sí desde inicio', () {
      expect(Mazo.barajar(['a'], random: Random(1)).agotado, isFalse);
      expect(Mazo.barajar(const [], random: Random(1)).agotado, isTrue);
    });

    test('siguiente en agotado = no-op (idempotente) y NO auto-remezcla', () {
      final mazo = Mazo.barajar(['única'], random: Random(3));
      final agotado = mazo.siguiente();
      expect(agotado.agotado, isTrue);
      expect(agotado.cartaActual, isNull);

      // Seguir llamando siguiente() no re-baraja ni revive el mazo.
      final otraVez = agotado.siguiente().siguiente();
      expect(otraVez.agotado, isTrue);
      expect(otraVez.cartaActual, isNull);
    });

    test('historial crece en orden e incluye la carta actual', () {
      final mazo = Mazo.barajar(['x', 'y', 'z'], random: Random(5));
      expect(mazo.historial, [mazo.cartaActual]);

      final paso1 = mazo.siguiente();
      expect(paso1.historial.length, 2);
      expect(paso1.historial.first, mazo.cartaActual);
      expect(paso1.historial.last, paso1.cartaActual);

      final paso2 = paso1.siguiente();
      expect(paso2.historial.length, 3);
      expect(paso2.historial, [mazo.cartaActual, paso1.cartaActual, paso2.cartaActual]);
    });

    test('historial es inmutable (List.unmodifiable)', () {
      final mazo = Mazo.barajar(['a', 'b'], random: Random(1));
      expect(() => mazo.historial.add('trucho'), throwsUnsupportedError);
    });
  });

  group('Mazo.remezclar', () {
    test('resetea: índice 0, historial = [carta0], nuevo ciclo válido', () {
      final mazo = Mazo.barajar(['a', 'b', 'c', 'd'], random: Random(8));
      final avanzado = mazo.siguiente().siguiente();
      expect(avanzado.agotado, isFalse);

      final re = avanzado.remezclar(random: Random(8));
      expect(re.agotado, isFalse);
      expect(re.cartaActual, isNotNull);
      expect(re.historial, [re.cartaActual]);

      // Nuevo ciclo completo válido.
      final vistas = <String>{re.cartaActual!};
      var actual = re;
      while (!actual.agotado) {
        actual = actual.siguiente();
        if (!actual.agotado) {
          expect(vistas, isNot(contains(actual.cartaActual)));
          vistas.add(actual.cartaActual!);
        }
      }
      expect(vistas, {'a', 'b', 'c', 'd'});
    });

    test('mismo seed → misma permutación entre remezcladas; mismo set', () {
      final cartas = ['a', 'b', 'c', 'd', 'e'];
      final original = Mazo.barajar(cartas, random: Random(21));
      final r1 = original.remezclar(random: Random(21));
      final r2 = original.remezclar(random: Random(21));

      List<String> ordenCompleto(Mazo m) {
        final out = <String>[m.cartaActual!];
        var actual = m;
        while (!actual.agotado) {
          actual = actual.siguiente();
          if (!actual.agotado) out.add(actual.cartaActual!);
        }
        return out;
      }

      expect(ordenCompleto(r1), ordenCompleto(r2), reason: 'mismo seed');
      expect(ordenCompleto(r1).toSet(), cartas.toSet(),
          reason: 'mismas cartas del mazo');
    });

    test('mazo vacío: remezclar no crashea', () {
      final vacio = Mazo.barajar(const [], random: Random(1));
      final re = vacio.remezclar(random: Random(1));
      expect(re.agotado, isTrue);
      expect(re.cartaActual, isNull);
    });
  });
}