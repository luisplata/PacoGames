import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:paco_game/core/ajustes/ajustes_providers.dart';
import 'package:paco_game/core/ajustes/ajustes_repository.dart';
import 'package:paco_game/core/contenido/diagnostico.dart';
import 'package:paco_game/core/contenido/entidades.dart';
import 'package:paco_game/core/contenido/validador_contenido.dart';
import 'package:paco_game/features/yo_nunca/application/carta_yo_nunca.dart';
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

/// Container con prefs sembradas: schema + marker de migración + nivel de
/// alcohol explícito. Sin el marker, la migración de WU4 pisaría el `false`
/// que estos tests necesitan para ejercitar Picante.
Future<ProviderContainer> crearContainer({
  bool modoAlcohol = false,
  DiagnosticoContenido? diagnostico,
}) async {
  SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  final prefs = SharedPreferencesAsync();
  await prefs.setInt('ajustes.schemaVersion', 1);
  await prefs.setBool('ajustes.migracionModoSinAlcohol', true);
  await prefs.setBool('ajustes.modoAlcohol', modoAlcohol);

  final container = ProviderContainer(
    overrides: [
      ajustesRepositoryProvider.overrideWithValue(AjustesRepository(prefs: prefs)),
      diagnosticoContenidoProvider.overrideWith(
        (ref) async => diagnostico ?? _diagnosticoFake,
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Devuelve todas las cartas de un mazo en orden de salida (exhaustivo).
List<CartaYoNunca> recorrer(Mazo<CartaYoNunca> mazo) {
  final out = <CartaYoNunca>[mazo.cartaActual!];
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

  group('yoNuncaNivelProvider', () {
    test('estado inicial Normal', () async {
      final container = await crearContainer();
      expect(container.read(yoNuncaNivelProvider), NivelYoNunca.normal);
    });

    test('autoDispose: sin listeners el nivel vuelve a Normal', () async {
      final container = await crearContainer();
      final sub = container.listen(yoNuncaNivelProvider, (_, _) {});
      container.read(yoNuncaNivelProvider.notifier).state = NivelYoNunca.picante;
      expect(container.read(yoNuncaNivelProvider), NivelYoNunca.picante);

      sub.close();
      await container.pump();
      expect(container.read(yoNuncaNivelProvider), NivelYoNunca.normal);
    });
  });

  group('yoNuncaMazoProvider', () {
    test('nivel Normal → mazo tipado solo con cartas Normal', () async {
      final container = await crearContainer();
      await container.read(diagnosticoContenidoProvider.future);
      await container.read(ajustesProvider.future);
      final sub = container.listen(yoNuncaMazoProvider, (_, _) {});

      final mazo = container.read(yoNuncaMazoProvider);
      expect(mazo, isA<Mazo<CartaYoNunca>>());
      expect(mazo.cartaActual, isA<CartaYoNunca>());
      expect(mazo.total, 3);
      expect(
        recorrer(mazo).map((c) => c.texto).toSet(),
        {'n1', 'n2', 'n3'},
      );
      expect(
        recorrer(mazo).every((c) => c.nivel == NivelYoNunca.normal),
        isTrue,
      );
      sub.close();
    });

    test('nivel Picante → aditivo 5 (3 Normal + 2 Picante), sin repetir',
        () async {
      final container = await crearContainer();
      await container.read(diagnosticoContenidoProvider.future);
      await container.read(ajustesProvider.future);
      final sub = container.listen(yoNuncaMazoProvider, (_, _) {});
      container.read(yoNuncaNivelProvider.notifier).state = NivelYoNunca.picante;

      final mazo = container.read(yoNuncaMazoProvider);
      final cartas = recorrer(mazo);
      expect(mazo.total, 5);
      expect(cartas.map((c) => c.texto).toSet(), {'n1', 'n2', 'n3', 'p1', 'p2'});
      expect(cartas.map((c) => c.texto).toSet().length, 5);
      expect(
        cartas.where((c) => c.nivel == NivelYoNunca.normal).length,
        3,
      );
      expect(
        cartas.where((c) => c.nivel == NivelYoNunca.picante).length,
        2,
      );
      sub.close();
    });

    test('modo sin alcohol fuerza Normal aunque el nivel sea Picante', () async {
      final container = await crearContainer(modoAlcohol: true);
      await container.read(diagnosticoContenidoProvider.future);
      await container.read(ajustesProvider.future);
      final sub = container.listen(yoNuncaMazoProvider, (_, _) {});
      container.read(yoNuncaNivelProvider.notifier).state = NivelYoNunca.picante;

      final mazo = container.read(yoNuncaMazoProvider);
      expect(mazo.total, 3);
      expect(
        recorrer(mazo).every((c) => c.nivel == NivelYoNunca.normal),
        isTrue,
      );
      sub.close();
    });

    test('cambiar el nivel reconstruye el mazo', () async {
      final container = await crearContainer();
      await container.read(diagnosticoContenidoProvider.future);
      await container.read(ajustesProvider.future);
      final sub = container.listen(yoNuncaMazoProvider, (_, _) {});

      expect(container.read(yoNuncaMazoProvider).total, 3);

      container.read(yoNuncaNivelProvider.notifier).state = NivelYoNunca.picante;
      expect(container.read(yoNuncaMazoProvider).total, 5);

      container.read(yoNuncaNivelProvider.notifier).state = NivelYoNunca.normal;
      expect(container.read(yoNuncaMazoProvider).total, 3);
      sub.close();
    });

    test('total estable al avanzar; sin repetir hasta agotar', () async {
      final container = await crearContainer();
      await container.read(diagnosticoContenidoProvider.future);
      await container.read(ajustesProvider.future);
      final sub = container.listen(yoNuncaMazoProvider, (_, _) {});
      container.read(yoNuncaNivelProvider.notifier).state = NivelYoNunca.picante;

      final mazo = container.read(yoNuncaMazoProvider);
      expect(mazo.total, 5);
      final textos = recorrer(mazo);
      expect(textos.length, 5);
      expect(textos.map((c) => c.texto).toSet().length, 5);

      // `total` es el tamaño del ciclo, no las restantes (YN1).
      container.read(yoNuncaMazoProvider.notifier).siguiente();
      expect(container.read(yoNuncaMazoProvider).total, 5);
      sub.close();
    });

    test('sin contenido para el juego → mazo vacío defensivo', () async {
      const sinYoNunca = DiagnosticoContenido(contenidos: {}, errores: []);
      final container = await crearContainer(diagnostico: sinYoNunca);
      await container.read(diagnosticoContenidoProvider.future);
      await container.read(ajustesProvider.future);
      final sub = container.listen(yoNuncaMazoProvider, (_, _) {});

      final mazo = container.read(yoNuncaMazoProvider);
      expect(mazo.total, 0);
      expect(mazo.agotado, isTrue);
      expect(mazo.cartaActual, isNull);
      sub.close();
    });

    test('contenido real: nivel Picante → 146 (80 Normal + 66 Picante)',
        () async {
      final texto = File('assets/content/yo_nunca.json').readAsStringSync();
      final real = const ValidadorContenido().validar({'yo_nunca': texto});
      final container = await crearContainer(diagnostico: real);
      await container.read(diagnosticoContenidoProvider.future);
      await container.read(ajustesProvider.future);
      final sub = container.listen(yoNuncaMazoProvider, (_, _) {});
      container.read(yoNuncaNivelProvider.notifier).state = NivelYoNunca.picante;

      final mazo = container.read(yoNuncaMazoProvider);
      expect(mazo.total, 146);
      expect(recorrer(mazo).map((c) => c.texto).toSet().length, 146);
      expect(
        recorrer(mazo).where((c) => c.nivel == NivelYoNunca.normal).length,
        80,
      );
      expect(
        recorrer(mazo).where((c) => c.nivel == NivelYoNunca.picante).length,
        66,
      );
      sub.close();
    });
  });

  group('AjustesNotifier.setGeneroPreferido (A1, otros juegos)', () {
    test('persiste en generoPreferido y sobrevive un reload (round-trip)',
        () async {
      final container = await crearContainer();

      await container.read(ajustesProvider.future);
      expect(container.read(ajustesProvider).value!.generoPreferido, isEmpty);

      await container.read(ajustesProvider.notifier).setGeneroPreferido('ruleta', 'Normal');
      expect(
        container.read(ajustesProvider).value!.generoPreferido['ruleta'],
        'Normal',
      );

      // Repo round-trip: la A1 sigue viva para Ruleta/Pictionary.
      final recargado =
          await AjustesRepository(prefs: SharedPreferencesAsync()).cargarAjustes();
      expect(recargado.generoPreferido, {'ruleta': 'Normal'});
    });

    test('no pisa otros ajustes (copyWith, no reemplaza)', () async {
      final container = await crearContainer();
      await container.read(ajustesProvider.future);
      await container.read(ajustesProvider.notifier).cambiarModoAlcohol(true);

      await container.read(ajustesProvider.notifier).setGeneroPreferido('ruleta', 'Normal');

      final ajustes = container.read(ajustesProvider).value!;
      expect(ajustes.modoAlcohol, isTrue);
      expect(ajustes.generoPreferido['ruleta'], 'Normal');
    });
  });
}
