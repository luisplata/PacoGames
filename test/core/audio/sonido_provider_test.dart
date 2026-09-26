import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:paco_game/core/ajustes/ajustes_providers.dart';
import 'package:paco_game/core/ajustes/ajustes_repository.dart';
import 'package:paco_game/core/audio/sonido_provider.dart';

import 'fakes.dart';

/// Container real (provider wiring real, solo repo y fakes overrideados).
/// Presembra prefs in-memory con los flags pedidos y espera la carga.
Future<ProviderContainer> _contenedor({
  required bool sonido,
  required bool vibracion,
  ReproductorFake? reproductor,
  VibradorFake? vibrador,
}) async {
  SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  final prefs = SharedPreferencesAsync();
  await prefs.setInt('ajustes.schemaVersion', 1);
  await prefs.setBool('ajustes.splashVisto', true);
  await prefs.setBool('ajustes.modoAlcohol', false);
  await prefs.setBool('ajustes.sonido', sonido);
  await prefs.setBool('ajustes.vibracion', vibracion);

  final container = ProviderContainer(
    overrides: [
      ajustesRepositoryProvider.overrideWithValue(
        AjustesRepository(prefs: prefs),
      ),
      if (reproductor != null)
        reproductorProvider.overrideWithValue(reproductor),
      if (vibrador != null) vibradorProvider.overrideWithValue(vibrador),
    ],
  );
  addTearDown(container.dispose);
  await container.read(ajustesProvider.future);
  return container;
}

void main() {
  group('sonidoServicioProvider', () {
    test('deriva habilitado de ajustes.sonido y reusa reproductorProvider '
        '(A2: flip en vivo sin reiniciar)', () async {
      final reproductor = ReproductorFake();
      final container =
          await _contenedor(sonido: true, vibracion: true, reproductor: reproductor);

      final servicio = container.read(sonidoServicioProvider);
      expect(servicio.habilitado, isTrue);
      await servicio.reproducirClick();
      expect(reproductor.llamadas, ['click']);

      // Flip en vivo (A2): apagar sonido → el provider reconstruye el
      // servicio deshabilitado; la siguiente interacción no suena.
      await container.read(ajustesProvider.notifier).cambiarSonido(false);
      final servicioApagado = container.read(sonidoServicioProvider);
      expect(servicioApagado.habilitado, isFalse);
      await servicioApagado.reproducirTick();
      await servicioApagado.reproducirFanfarria();
      expect(reproductor.llamadas, ['click']); // sin nuevas llamadas
    });

    test('sonido=false → servicio deshabilitado (0 llamadas)', () async {
      final reproductor = ReproductorFake();
      final container =
          await _contenedor(sonido: false, vibracion: true, reproductor: reproductor);

      final servicio = container.read(sonidoServicioProvider);
      expect(servicio.habilitado, isFalse);
      await servicio.reproducirClick();
      await servicio.reproducirFanfarria();
      await servicio.reproducirGiro();
      expect(reproductor.llamadas, isEmpty);
    });
  });

  group('hapticosServicioProvider', () {
    test('deriva habilitado de ajustes.vibracion y reusa vibradorProvider '
        '(A2: flip en vivo)', () async {
      final vibrador = VibradorFake();
      final container =
          await _contenedor(sonido: true, vibracion: true, vibrador: vibrador);

      final servicio = container.read(hapticosServicioProvider);
      expect(servicio.habilitado, isTrue);
      await servicio.acierto();
      expect(vibrador.llamadas, ['acierto']);

      await container.read(ajustesProvider.notifier).cambiarVibracion(false);
      final servicioApagado = container.read(hapticosServicioProvider);
      expect(servicioApagado.habilitado, isFalse);
      await servicioApagado.ruletaFrenar();
      await servicioApagado.tickTimer();
      expect(vibrador.llamadas, ['acierto']); // sin nuevas vibraciones
    });

    test('vibracion=false → servicio deshabilitado (0 vibraciones)', () async {
      final vibrador = VibradorFake();
      final container =
          await _contenedor(sonido: true, vibracion: false, vibrador: vibrador);

      final servicio = container.read(hapticosServicioProvider);
      expect(servicio.habilitado, isFalse);
      await servicio.ruletaFrenar();
      await servicio.tickTimer();
      await servicio.acierto();
      expect(vibrador.llamadas, isEmpty);
    });
  });
}