import 'package:flutter_test/flutter_test.dart';

import 'package:paco_game/core/audio/hapticos.dart';

import 'fakes.dart';

void main() {
  group('HapticosServicio', () {
    test('vibracion=true → mapea ruletaFrenar→mediumImpact, tickTimer→'
        'selectionClick, acierto→heavyImpact (AH5)', () async {
      final vibrador = VibradorFake();
      final servicio =
          HapticosServicio(habilitado: true, vibrador: vibrador);

      await servicio.ruletaFrenar();
      await servicio.tickTimer();
      await servicio.acierto();

      expect(vibrador.llamadas, ['ruletaFrenar', 'tickTimer', 'acierto']);
    });

    test('vibracion=false → 0 vibraciones (AH5)', () async {
      final vibrador = VibradorFake();
      final servicio =
          HapticosServicio(habilitado: false, vibrador: vibrador);

      await servicio.ruletaFrenar();
      await servicio.tickTimer();
      await servicio.acierto();

      expect(vibrador.llamadas, isEmpty);
    });
  });

  group('VibradorHapticFeedback', () {
    test('sin canal de haptics (web no-op): no lanza en ninguno de los 3',
        () async {
      final vibrador = VibradorHapticFeedback();

      await vibrador.ruletaFrenar();
      await vibrador.tickTimer();
      await vibrador.acierto();
    });
  });
}