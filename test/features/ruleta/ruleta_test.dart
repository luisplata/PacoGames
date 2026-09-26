import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:paco_game/features/ruleta/application/ruleta.dart';

/// Deck real de ruleta.json: 16 entradas, "Volvés a girar" duplicado
/// (2/16 ≈ 12,5% — pondera doble por selección directa sobre la lista).
const _deckReal = [
  'Tomás un trago',
  'Un beso a la persona que tenés en frente',
  'Repartis dos tragos',
  'Volvés a girar',
  'Volvés a girar',
  'Tomás tres tragos',
  "Tenés que decir un 'Yo Nunca'",
  'Repartís 6 tragos',
  "Te desafian a 'Verdad o Reto'",
  'Fondo blanco o volvé a girar',
  'Todos toman',
  'Toman las mujeres',
  'Toman los hombres',
  'Toma el de tu derecha',
  'Toma el de tu izquierda',
  'Regalas un fondo blanco',
];

void main() {
  group('Ruleta.iniciar', () {
    test('estado inicial: resultado null (esperando [Girar]), historial vacío', () {
      final ruleta = Ruleta.iniciar(_deckReal);
      expect(ruleta.resultado, isNull);
      expect(ruleta.historial, isEmpty);
      expect(ruleta.ultimas5, isEmpty);
      expect(ruleta.cartas, hasLength(16));
    });
  });

  group('Ruleta — inmutabilidad', () {
    test('girar() y siguiente() devuelven NUEVA instancia, original intacto', () {
      final original = Ruleta.iniciar(_deckReal);
      final girada = original.girar(random: Random(1));

      expect(girada, isNot(same(original)));
      expect(original.resultado, isNull);
      expect(original.historial, isEmpty);

      expect(girada.resultado, isNotNull);
      expect(girada.historial, hasLength(1));

      final siguiente = girada.siguiente();
      expect(siguiente, isNot(same(girada)));
      expect(siguiente.resultado, isNull);
      expect(siguiente.historial, hasLength(1)); // preserva historial
      expect(girada.resultado, isNotNull); // la original sigue con resultado
    });

    test('cartas/historial/ultimas5 son inmutables (List.unmodifiable)', () {
      final ruleta = Ruleta.iniciar(['a', 'b']).girar(random: Random(1));
      expect(() => ruleta.cartas.add('x'), throwsUnsupportedError);
      expect(() => ruleta.historial.add('x'), throwsUnsupportedError);
      expect(() => ruleta.ultimas5.add('x'), throwsUnsupportedError);
    });

    test('cartas vacías → girar() no-op sin crash (devuelve this)', () {
      final vacia = Ruleta.iniciar(const []);
      final girada = vacia.girar(random: Random(1));
      expect(girada, same(vacia));
      expect(girada.resultado, isNull);
      expect(girada.historial, isEmpty);
    });
  });

  group('Ruleta — historial y ventana', () {
    test('historial acumula cada giro (N giros → N entradas, resultado = última)', () {
      var ruleta = Ruleta.iniciar(_deckReal);
      for (var i = 0; i < 5; i++) {
        ruleta = ruleta.girar(random: Random(i * 3 + 1));
      }
      expect(ruleta.historial, hasLength(5));
      expect(ruleta.historial.last, ruleta.resultado);
    });

    test('siguiente() limpia resultado y PRESERVA la ventana ultimas5 en orden', () {
      var ruleta = Ruleta.iniciar(_deckReal);
      for (var i = 0; i < 3; i++) {
        ruleta = ruleta.girar(random: Random(i));
      }
      final antes = ruleta.ultimas5;
      expect(antes, hasLength(3));

      final limpia = ruleta.siguiente();
      expect(limpia.resultado, isNull);
      expect(limpia.ultimas5, antes); // ventana intacta, mismo orden
      expect(limpia.historial, ruleta.historial);
    });

    test('historial incluye giros pass-turn (se registran como finales)', () {
      final ruleta = Ruleta.iniciar(const ['volvé a girar']).girar(random: Random(1));
      expect(esPasaTurno(ruleta.resultado!), isTrue);
      expect(ruleta.historial, ['volvé a girar']); // el pass-turn cuenta como final
    });

    test('siguiente() es idempotente: con resultado null devuelve this', () {
      final ruleta = Ruleta.iniciar(_deckReal);
      expect(ruleta.siguiente(), same(ruleta));
    });
  });

  group('Ruleta — no-repeat ventana de 5', () {
    test('50 giros sin repetir en ventana de 5 (invarianza sliding window)', () {
      var ruleta = Ruleta.iniciar(_deckReal);
      for (var i = 0; i < 50; i++) {
        ruleta = ruleta.girar(random: Random(i));
        expect(ruleta.resultado, isNotNull);
        final ventana = ruleta.ultimas5;
        expect(ventana.toSet().length, ventana.length,
            reason: 'giro $i: la ventana de 5 no contiene duplicados');
        expect(_deckReal, contains(ruleta.resultado));
      }
      // La ventana se desliza: 50 giros sobre 15 strings distintos SIN
      // restricción más allá de 5 → hay repeticiones globales (historial
      // con duplicados), aunque nunca dentro de la ventana.
      expect(ruleta.historial.toSet().length, lessThan(ruleta.historial.length));
    });

    test('girar() con historial existente excluye las últimas 5 por string exacto',
        () {
      // Deck de 6 strings: tras 5 giros la ventana tiene 5 resultados
      // distintos → el 6to giro SOLO puede elegir la carta que falta.
      const deck = ['a', 'b', 'c', 'd', 'e', 'f'];
      var ruleta = Ruleta.iniciar(deck);
      for (var i = 0; i < 5; i++) {
        ruleta = ruleta.girar(random: Random(i));
      }
      final previos5 = ruleta.ultimas5;
      expect(previos5.toSet().length, 5);

      final sexto = ruleta.girar(random: Random(77));
      expect(previos5, isNot(contains(sexto.resultado)));
      expect(deck, contains(sexto.resultado));
    });
  });

  group('Ruleta — ponderación', () {
    test('"Volvés a girar" ≈ 2/16 (±2%) en 10k picks frescos (duplicado pondera)',
        () {
      var hits = 0;
      for (var i = 0; i < 10000; i++) {
        final pick = seleccionarResultado(_deckReal, const [], Random(i));
        if (esPasaTurno(pick)) hits++;
      }
      expect(hits / 10000, closeTo(2 / 16, 0.02));
    });
  });

  group('Ruleta — fallback deck pequeño', () {
    test('deck con ≤5 strings distintos: gira sin deadlock y puede repetir', () {
      const deckChico = ['a', 'b', 'c', 'd', 'e'];
      var ruleta = Ruleta.iniciar(deckChico);
      for (var i = 0; i < 5; i++) {
        ruleta = ruleta.girar(random: Random(i));
      }
      // Ventana llena con los 5 strings → pool vacío → fallback a la lista
      // completa: sigue girando, puede repetir, nunca lanza.
      final sexto = ruleta.girar(random: Random(99));
      expect(sexto.resultado, isNotNull);
      expect(sexto.historial, hasLength(6));
      expect(deckChico, contains(sexto.resultado));
    });
  });

  group('esPasaTurno', () {
    test('variantes exactas matchean tras normalizar (case/whitespace)', () {
      expect(esPasaTurno('volvé a girar'), isTrue);
      expect(esPasaTurno('volvés a girar'), isTrue);
      expect(esPasaTurno('  VolvÉ A Girar  '), isTrue);
      expect(esPasaTurno('VOLVÉS A GIRAR'), isTrue);
      expect(esPasaTurno('Volvés a girar'), isTrue); // grafía real del deck
    });

    test('substring NO matchea (nunca contains)', () {
      expect(esPasaTurno('Fondo blanco o volvé a girar'), isFalse);
      expect(esPasaTurno('Tomás un trago'), isFalse);
      expect(esPasaTurno(''), isFalse);
    });
  });
}