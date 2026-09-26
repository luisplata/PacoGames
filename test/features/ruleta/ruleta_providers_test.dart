import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:paco_game/core/ajustes/ajustes_providers.dart';
import 'package:paco_game/core/ajustes/ajustes_repository.dart';
import 'package:paco_game/core/contenido/diagnostico.dart';
import 'package:paco_game/core/contenido/entidades.dart';
import 'package:paco_game/core/contenido/generos_visibles.dart';
import 'package:paco_game/features/ruleta/application/ruleta_providers.dart';

const _normal = Genero(
  nombre: 'Normal',
  cartas: ['Tomás un trago', 'Volvés a girar', 'Todos toman'],
);
const _picante = Genero(
  nombre: 'Picante',
  cartas: ['P1'],
);

const _diagnosticoFake = DiagnosticoContenido(
  contenidos: {
    'ruleta': ContenidoJuego(
      juegoId: 'ruleta',
      generos: [_normal, _picante],
    ),
  },
  errores: [],
);

ProviderContainer crearContainer(SharedPreferencesAsync prefs) {
  final container = ProviderContainer(
    overrides: [
      ajustesRepositoryProvider.overrideWithValue(AjustesRepository(prefs: prefs)),
      diagnosticoContenidoProvider.overrideWith((ref) async => _diagnosticoFake),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  group('ruletaGeneroProvider', () {
    test('estado inicial null → la UI hace auto-select/picker', () {
      final container = crearContainer(SharedPreferencesAsync());
      expect(container.read(ruletaGeneroProvider), isNull);
    });

    test('autoDispose: sin listeners el estado se descarta (fresco al re-leer)',
        () async {
      final container = crearContainer(SharedPreferencesAsync());
      final sub = container.listen(ruletaGeneroProvider, (_, _) {});
      container.read(ruletaGeneroProvider.notifier).state = 'Normal';
      expect(container.read(ruletaGeneroProvider), 'Normal');

      sub.close();
      await container.pump();
      expect(container.read(ruletaGeneroProvider), isNull);
    });
  });

  group('ruletaProvider', () {
    test('género null → Ruleta vacía sin crash (cartas vacías, girar no-op)',
        () async {
      final container = crearContainer(SharedPreferencesAsync());
      await container.read(diagnosticoContenidoProvider.future);
      final sub = container.listen(ruletaProvider, (_, _) {});

      final ruleta = container.read(ruletaProvider);
      expect(ruleta.cartas, isEmpty);
      expect(ruleta.resultado, isNull);
      expect(ruleta.girar(random: Random(1)).resultado, isNull); // no-op, sin crash
      sub.close();
    });

    test('seleccionarGenero("Normal") → ruleta solo con cartas de Normal',
        () async {
      final container = crearContainer(SharedPreferencesAsync());
      await container.read(diagnosticoContenidoProvider.future);
      final sub = container.listen(ruletaProvider, (_, _) {});

      container.read(ruletaProvider.notifier).seleccionarGenero('Normal');
      final ruleta = container.read(ruletaProvider);
      expect(ruleta.cartas, ['Tomás un trago', 'Volvés a girar', 'Todos toman']);
      sub.close();
    });

    test('girar(seed) → resultado ∈ cartas y entra al historial', () async {
      final container = crearContainer(SharedPreferencesAsync());
      await container.read(diagnosticoContenidoProvider.future);
      final sub = container.listen(ruletaProvider, (_, _) {});
      container.read(ruletaProvider.notifier).seleccionarGenero('Normal');

      container.read(ruletaProvider.notifier).girar(Random(7));
      final ruleta = container.read(ruletaProvider);
      expect(ruleta.resultado, isNotNull);
      expect(ruleta.cartas, contains(ruleta.resultado));
      expect(ruleta.historial, [ruleta.resultado]);
      expect(ruleta.ultimas5, [ruleta.resultado]);
      sub.close();
    });

    test('siguiente() → resultado null, historial preservado', () async {
      final container = crearContainer(SharedPreferencesAsync());
      await container.read(diagnosticoContenidoProvider.future);
      final sub = container.listen(ruletaProvider, (_, _) {});
      container.read(ruletaProvider.notifier).seleccionarGenero('Normal');
      container.read(ruletaProvider.notifier).girar(Random(7));
      expect(container.read(ruletaProvider).resultado, isNotNull);

      container.read(ruletaProvider.notifier).siguiente();
      final ruleta = container.read(ruletaProvider);
      expect(ruleta.resultado, isNull);
      expect(ruleta.historial, hasLength(1)); // la ventana sigue
      sub.close();
    });

    test('autoDispose: sin listeners el estado se descarta (re-entrada = fresco)',
        () async {
      final container = crearContainer(SharedPreferencesAsync());
      await container.read(diagnosticoContenidoProvider.future);
      final sub = container.listen(ruletaProvider, (_, _) {});
      container.read(ruletaProvider.notifier).seleccionarGenero('Normal');
      expect(container.read(ruletaProvider).cartas, isNotEmpty);

      sub.close();
      await container.pump();

      // Re-entrada: estado descartado → ruleta fresca vacía (género null).
      expect(container.read(ruletaProvider).cartas, isEmpty);
      expect(container.read(ruletaGeneroProvider), isNull);
    });
  });

  group('modoAlcohol filtra Picante (RU6 + generosVisibles core)', () {
    test('modoAlcohol=true → visibles sin Picante; false → ambos', () async {
      // true: prefs pre-sembradas → ajustes reales modoAlcohol=true.
      final prefs = SharedPreferencesAsync();
      await prefs.setInt('ajustes.schemaVersion', 1);
      await prefs.setBool('ajustes.modoAlcohol', true);

      final container = crearContainer(prefs);
      await container.read(diagnosticoContenidoProvider.future);
      await container.read(ajustesProvider.future);

      final generos = container
          .read(diagnosticoContenidoProvider)
          .value!.contenidos['ruleta']!.generos;
      final visibles = generosVisibles(
        generos,
        modoAlcohol: container.read(ajustesProvider).value!.modoAlcohol,
      );
      expect(visibles.map((g) => g.nombre), ['Normal']);

      // false → ambos géneros visibles.
      final container2 = crearContainer(SharedPreferencesAsync());
      await container2.read(diagnosticoContenidoProvider.future);
      await container2.read(ajustesProvider.future);
      final visibles2 = generosVisibles(
        container2
            .read(diagnosticoContenidoProvider)
            .value!.contenidos['ruleta']!.generos,
        modoAlcohol: false,
      );
      expect(visibles2.map((g) => g.nombre), ['Normal', 'Picante']);
    });
  });
}