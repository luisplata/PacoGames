import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:paco_game/core/ajustes/ajustes_providers.dart';
import 'package:paco_game/core/ajustes/ajustes_repository.dart';
import 'package:paco_game/core/contenido/diagnostico.dart';
import 'package:paco_game/core/contenido/entidades.dart';
import 'package:paco_game/features/yo_nunca/application/mazo.dart';
import 'package:paco_game/features/yo_nunca/application/yo_nunca_providers.dart';

const _normal = Genero(
  nombre: 'Normal',
  cartas: ['n1', 'n2', 'n3'],
);
const _picante = Genero(
  nombre: 'Picante',
  cartas: ['p1', 'p2'],
);

const _diagnosticoFake = DiagnosticoContenido(
  contenidos: {
    'yo_nunca': ContenidoJuego(
      juegoId: 'yo_nunca',
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

/// Devuelve todas las cartas de un mazo en orden de salida (exhaustivo).
List<String> recorrer(Mazo mazo) {
  final out = <String>[mazo.cartaActual!];
  var actual = mazo;
  while (!actual.agotado) {
    actual = actual.siguiente();
    if (!actual.agotado) out.add(actual.cartaActual!);
  }
  return out;
}

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  group('generosVisibles (puro)', () {
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

  group('yoNuncaGeneroProvider', () {
    test('estado inicial null → la UI muestra el picker', () {
      final container = crearContainer(SharedPreferencesAsync());
      expect(container.read(yoNuncaGeneroProvider), isNull);
    });

    test('autoDispose: sin listeners el estado se descarta (fresco al re-leer)',
        () async {
      final container = crearContainer(SharedPreferencesAsync());
      final sub = container.listen(yoNuncaGeneroProvider, (_, _) {});
      container.read(yoNuncaGeneroProvider.notifier).state = 'Normal';
      expect(container.read(yoNuncaGeneroProvider), 'Normal');

      sub.close();
      await container.pump();
      expect(container.read(yoNuncaGeneroProvider), isNull);
    });
  });

  group('yoNuncaMazoProvider', () {
    test('género null → mazo vacío agotado (sin cartas, sin crash)', () async {
      final container = crearContainer(SharedPreferencesAsync());
      await container.read(diagnosticoContenidoProvider.future);
      final sub = container.listen(yoNuncaMazoProvider, (_, _) {});

      expect(container.read(yoNuncaMazoProvider).agotado, isTrue);
      expect(container.read(yoNuncaMazoProvider).cartaActual, isNull);
      sub.close();
    });

    test('seleccionarGenero("Normal") → mazo solo con cartas Normal', () async {
      final container = crearContainer(SharedPreferencesAsync());
      await container.read(diagnosticoContenidoProvider.future);
      final sub = container.listen(yoNuncaMazoProvider, (_, _) {});

      container.read(yoNuncaMazoProvider.notifier).seleccionarGenero('Normal');
      final mazo = container.read(yoNuncaMazoProvider);

      expect(mazo.agotado, isFalse);
      expect(recorrer(mazo).toSet(), {'n1', 'n2', 'n3'});
      expect(recorrer(mazo).toSet(), isNot(contains('p1')));
      sub.close();
    });

    test('seleccionarGenero("Picante") → mazo solo con cartas Picante', () async {
      final container = crearContainer(SharedPreferencesAsync());
      await container.read(diagnosticoContenidoProvider.future);
      final sub = container.listen(yoNuncaMazoProvider, (_, _) {});

      container.read(yoNuncaMazoProvider.notifier).seleccionarGenero('Picante');
      expect(recorrer(container.read(yoNuncaMazoProvider)).toSet(), {'p1', 'p2'});
      sub.close();
    });

    test('siguiente() y remezclar() actualizan el estado del mazo', () async {
      final container = crearContainer(SharedPreferencesAsync());
      await container.read(diagnosticoContenidoProvider.future);
      final sub = container.listen(yoNuncaMazoProvider, (_, _) {});
      container.read(yoNuncaMazoProvider.notifier).seleccionarGenero('Normal');

      final mazo0 = container.read(yoNuncaMazoProvider);
      expect(mazo0.historial.length, 1);

      container.read(yoNuncaMazoProvider.notifier).siguiente();
      final mazo1 = container.read(yoNuncaMazoProvider);
      expect(mazo1.historial.length, 2);

      container.read(yoNuncaMazoProvider.notifier).remezclar();
      final mazo2 = container.read(yoNuncaMazoProvider);
      expect(mazo2.historial.length, 1);
      expect(mazo2.agotado, isFalse);
      sub.close();
    });

    test('autoDispose: sin listeners el mazo se descarta (re-entrada = fresco)',
        () async {
      final container = crearContainer(SharedPreferencesAsync());
      await container.read(diagnosticoContenidoProvider.future);
      final sub = container.listen(yoNuncaMazoProvider, (_, _) {});
      container.read(yoNuncaMazoProvider.notifier).seleccionarGenero('Normal');
      expect(container.read(yoNuncaMazoProvider).agotado, isFalse);

      sub.close();
      await container.pump();

      // Re-entrada: estado descartado → mazo fresco vacío (género null).
      expect(container.read(yoNuncaMazoProvider).agotado, isTrue);
      expect(container.read(yoNuncaGeneroProvider), isNull);
    });
  });

  group('AjustesNotifier.setGeneroPreferido (A1)', () {
    test('persiste en generoPreferido y sobrevive un reload (round-trip)',
        () async {
      final prefs = SharedPreferencesAsync();
      final container = crearContainer(prefs);

      await container.read(ajustesProvider.future);
      expect(container.read(ajustesProvider).value!.generoPreferido, isEmpty);

      await container.read(ajustesProvider.notifier).setGeneroPreferido('yo_nunca', 'Normal');
      expect(
        container.read(ajustesProvider).value!.generoPreferido['yo_nunca'],
        'Normal',
      );

      // Repo round-trip: otro repo con las MISMAS prefs lo recarga.
      final recargado = await AjustesRepository(prefs: prefs).cargarAjustes();
      expect(recargado.generoPreferido['yo_nunca'], 'Normal');
    });

    test('no pisa otros ajustes (copyWith, no reemplaza)', () async {
      final container = crearContainer(SharedPreferencesAsync());
      await container.read(ajustesProvider.future);
      await container.read(ajustesProvider.notifier).cambiarModoAlcohol(true);

      await container.read(ajustesProvider.notifier).setGeneroPreferido('yo_nunca', 'Normal');

      final ajustes = container.read(ajustesProvider).value!;
      expect(ajustes.modoAlcohol, isTrue);
      expect(ajustes.generoPreferido['yo_nunca'], 'Normal');
    });
  });
}