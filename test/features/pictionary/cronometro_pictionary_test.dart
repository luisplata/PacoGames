import 'package:flutter_test/flutter_test.dart';

import 'package:paco_game/features/pictionary/application/cronometro_pictionary.dart';

void main() {
  group('CronometroPictionary.iniciar', () {
    test('duracionRonda = 60 s y arranca corriendo (60, !pausado, !terminado)',
        () {
      expect(CronometroPictionary.duracionRonda, const Duration(seconds: 60));

      final crono = CronometroPictionary.iniciar();
      expect(crono.segundosRestantes, 60);
      expect(crono.pausado, isFalse);
      expect(crono.terminado, isFalse);
    });
  });

  group('tick', () {
    test('tick × 60 → segundosRestantes 0 y terminado (nunca negativo)', () {
      var crono = CronometroPictionary.iniciar();
      for (var i = 0; i < 60; i++) {
        crono = crono.tick();
      }

      expect(crono.segundosRestantes, 0);
      expect(crono.terminado, isTrue);
    });

    test('tick en 0 → no-op, nunca negativo', () {
      var crono = CronometroPictionary.iniciar();
      for (var i = 0; i < 65; i++) {
        crono = crono.tick();
      }

      expect(crono.segundosRestantes, 0);
      expect(crono.terminado, isTrue);
    });
  });

  group('pausa / reanudar', () {
    test('pausar congela: tick no-op mientras pausado', () {
      var crono = CronometroPictionary.iniciar();
      for (var i = 0; i < 20; i++) {
        crono = crono.tick();
      }
      expect(crono.segundosRestantes, 40);

      crono = crono.pausar();
      expect(crono.pausado, isTrue);
      for (var i = 0; i < 5; i++) {
        crono = crono.tick();
      }
      expect(crono.segundosRestantes, 40); // congelado
      expect(crono.terminado, isFalse);
    });

    test('reanudar continúa: tick vuelve a decrementar', () {
      var crono = CronometroPictionary.iniciar();
      for (var i = 0; i < 20; i++) {
        crono = crono.tick();
      }
      crono = crono.pausar();
      crono = crono.reanudar();
      expect(crono.pausado, isFalse);

      crono = crono.tick();
      expect(crono.segundosRestantes, 39);
    });

    test('pausar/reanudar en terminado → no-op (no reviven el timer)', () {
      var crono = CronometroPictionary.iniciar();
      for (var i = 0; i < 60; i++) {
        crono = crono.tick();
      }
      expect(crono.terminado, isTrue);

      final pausado = crono.pausar();
      expect(pausado.pausado, isFalse); // no-op
      expect(pausado.terminado, isTrue);

      final reanudado = crono.reanudar();
      expect(reanudado.pausado, isFalse); // no-op
      expect(reanudado.terminado, isTrue);
      expect(reanudado.segundosRestantes, 0);
    });
  });

  group('inmutabilidad', () {
    test('cada método devuelve NUEVA instancia; la original no muta', () {
      final original = CronometroPictionary.iniciar();
      final mutada = original
          .tick()
          .tick()
          .pausar()
          .reanudar();

      expect(mutada.segundosRestantes, 58);
      expect(original.segundosRestantes, 60);
      expect(original.pausado, isFalse);
      expect(original.terminado, isFalse);
    });
  });
}