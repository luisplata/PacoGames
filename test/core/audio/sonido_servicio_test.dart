import 'package:flutter_test/flutter_test.dart';

import 'package:paco_game/core/audio/sonido_servicio.dart';

import 'fakes.dart';

void main() {
  group('SonidoServicio', () {
    test('habilitado=true → delega los 5 SFX al reproductor (mapeo exacto)',
        () async {
      final reproductor = ReproductorFake();
      final servicio =
          SonidoServicio(habilitado: true, reproductor: reproductor);

      await servicio.reproducirClick();
      await servicio.reproducirTick();
      await servicio.reproducirFanfarria();
      await servicio.reproducirGiro();
      await servicio.reproducirCarta();

      expect(
        reproductor.llamadas,
        ['click', 'tick', 'fanfarria', 'giro', 'carta'],
      );
    });

    test('habilitado=false → 0 llamadas a TODOS los métodos (AH4)', () async {
      final reproductor = ReproductorFake();
      final servicio =
          SonidoServicio(habilitado: false, reproductor: reproductor);

      await servicio.reproducirClick();
      await servicio.reproducirTick();
      await servicio.reproducirFanfarria();
      await servicio.reproducirGiro();
      await servicio.reproducirCarta();

      expect(reproductor.llamadas, isEmpty);
    });
  });
}