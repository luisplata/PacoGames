import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:paco_game/app/boot.dart';
import 'package:paco_game/core/ajustes/ajustes_providers.dart';
import 'package:paco_game/core/ajustes/ajustes_repository.dart';
import 'package:paco_game/core/contenido/diagnostico.dart';
import 'package:paco_game/core/contenido/entidades.dart';

void main() {
  group('BootBridge', () {
    test('estado inicial: splashVisto null (cargando) y sin errores', () {
      final bridge = BootBridge();

      expect(bridge.splashVisto, isNull);
      expect(bridge.errores, isEmpty);
    });

    test('actualizar fija ambos campos y notifica', () {
      final bridge = BootBridge();
      var notificaciones = 0;
      bridge.addListener(() => notificaciones++);

      bridge.actualizar(
        splashVisto: true,
        errores: const [
          ErrorContenido(archivo: 'ruleta.json', linea: 3, mensaje: 'error de sintaxis'),
        ],
      );

      expect(bridge.splashVisto, isTrue);
      expect(bridge.errores, hasLength(1));
      expect(bridge.errores[0].archivo, 'ruleta.json');
      expect(notificaciones, 1);
    });

    test('marcarSplashVisto(true) notifica para re-evaluar el redirect', () {
      final bridge = BootBridge();
      var notificaciones = 0;
      bridge.addListener(() => notificaciones++);

      bridge.marcarSplashVisto(true);

      expect(bridge.splashVisto, isTrue);
      expect(notificaciones, 1);
    });
  });

  group('bootBridgeProvider', () {
    test('provee un BootBridge con estado inicial null', () async {
      SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
      final container = ProviderContainer(
        overrides: [
          ajustesRepositoryProvider.overrideWithValue(
            AjustesRepository(prefs: SharedPreferencesAsync()),
          ),
          diagnosticoContenidoProvider.overrideWith(
            (ref) async => const DiagnosticoContenido(contenidos: {}, errores: []),
          ),
        ],
      );
      addTearDown(container.dispose);

      final bridge = container.read(bootBridgeProvider);

      expect(bridge, isA<BootBridge>());
      expect(bridge.splashVisto, isNull);
      // El fire-and-forget corre: esperamos que el boot complete y notifique.
      await Future<void>.delayed(Duration.zero);
      expect(bridge.splashVisto, isFalse);
    });
  });
}