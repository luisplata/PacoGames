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
import 'package:paco_game/features/pictionary/application/pictionary_providers.dart';

const _normal = Genero(
  nombre: 'Normal',
  cartas: ['P1', 'P2', 'P3', 'P4', 'P5', 'P6'],
);
const _picante = Genero(
  nombre: 'Picante',
  cartas: ['Q1'],
);

const _diagnosticoFake = DiagnosticoContenido(
  contenidos: {
    'pictionary': ContenidoJuego(
      juegoId: 'pictionary',
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

  group('pictionaryGeneroProvider', () {
    test('estado inicial null → la UI hace auto-select/picker', () {
      final container = crearContainer(SharedPreferencesAsync());
      expect(container.read(pictionaryGeneroProvider), isNull);
    });

    test('autoDispose: sin listeners el estado se descarta (fresco al re-leer)',
        () async {
      final container = crearContainer(SharedPreferencesAsync());
      final sub = container.listen(pictionaryGeneroProvider, (_, _) {});
      container.read(pictionaryGeneroProvider.notifier).state = 'Normal';
      expect(container.read(pictionaryGeneroProvider), 'Normal');

      sub.close();
      await container.pump();
      expect(container.read(pictionaryGeneroProvider), isNull);
    });
  });

  group('sesionPictionaryProvider', () {
    test('género null → sesión iniciada (0-0, turno 1) sin crash', () async {
      final container = crearContainer(SharedPreferencesAsync());
      await container.read(diagnosticoContenidoProvider.future);
      final sub = container.listen(sesionPictionaryProvider, (_, _) {});

      final sesion = container.read(sesionPictionaryProvider);
      expect(sesion.marcadorA, 0);
      expect(sesion.marcadorB, 0);
      expect(sesion.turnoDibujante, 1);
      expect(sesion.palabrasActuales, isEmpty);
      // Sortear sin género (deck vacío) → no-op defensivo, sin crash.
      container.read(sesionPictionaryProvider.notifier).sortearPalabras(Random(1));
      expect(container.read(sesionPictionaryProvider).palabrasActuales, isEmpty);
      sub.close();
    });

    test('seleccionarGenero("Normal") → sortear(seed) sortea 3 del deck del '
        'género y las consume al instante', () async {
      final container = crearContainer(SharedPreferencesAsync());
      await container.read(diagnosticoContenidoProvider.future);
      final sub = container.listen(sesionPictionaryProvider, (_, _) {});
      container.read(sesionPictionaryProvider.notifier).seleccionarGenero('Normal');
      // Fuerza el rebuild post-write (patrón ruleta) antes de operar.
      container.read(sesionPictionaryProvider);

      container.read(sesionPictionaryProvider.notifier).sortearPalabras(Random(7));
      final sesion = container.read(sesionPictionaryProvider);
      expect(sesion.palabrasActuales, hasLength(3));
      expect(sesion.palabrasActuales.toSet(), hasLength(3)); // distintas
      for (final p in sesion.palabrasActuales) {
        expect(_normal.cartas, contains(p)); // ∈ deck del género
      }
      // Consumidas: las 3 mostradas ya están quemadas (P1).
      expect(sesion.palabrasUsadas, sesion.palabrasActuales);
      sub.close();
    });

    test('puntoA/puntoB/siguienteDibujante/nuevaRonda vía notifier', () async {
      final container = crearContainer(SharedPreferencesAsync());
      await container.read(diagnosticoContenidoProvider.future);
      final sub = container.listen(sesionPictionaryProvider, (_, _) {});
      container.read(sesionPictionaryProvider.notifier).seleccionarGenero('Normal');
      container.read(sesionPictionaryProvider); // fuerza rebuild (patrón ruleta)

      container.read(sesionPictionaryProvider.notifier).sortearPalabras(Random(7));
      expect(container.read(sesionPictionaryProvider).palabrasActuales, hasLength(3));

      container.read(sesionPictionaryProvider.notifier).puntoA();
      container.read(sesionPictionaryProvider.notifier).siguienteDibujante();
      var sesion = container.read(sesionPictionaryProvider);
      expect(sesion.marcadorA, 1);
      expect(sesion.marcadorB, 0);
      expect(sesion.turnoDibujante, 2);

      container.read(sesionPictionaryProvider.notifier).puntoB();
      sesion = container.read(sesionPictionaryProvider);
      expect(sesion.marcadorA, 1);
      expect(sesion.marcadorB, 1);

      container.read(sesionPictionaryProvider.notifier).nuevaRonda();
      sesion = container.read(sesionPictionaryProvider);
      expect(sesion.palabrasActuales, isEmpty);
      expect(sesion.marcadorA, 1); // conserva marcador
      expect(sesion.turnoDibujante, 2); // conserva turno
      sub.close();
    });

    test('autoDispose: sin listeners → re-entrar = fresco (0-0, turno 1)',
        () async {
      final container = crearContainer(SharedPreferencesAsync());
      await container.read(diagnosticoContenidoProvider.future);
      final sub = container.listen(sesionPictionaryProvider, (_, _) {});
      container.read(sesionPictionaryProvider.notifier).seleccionarGenero('Normal');
      container.read(sesionPictionaryProvider.notifier).sortearPalabras(Random(7));
      container.read(sesionPictionaryProvider.notifier).puntoA();
      container.read(sesionPictionaryProvider.notifier).siguienteDibujante();
      expect(container.read(sesionPictionaryProvider).marcadorA, 1);

      sub.close();
      await container.pump();

      // Re-entrada: estado descartado → sesión fresca y género null.
      final fresca = container.read(sesionPictionaryProvider);
      expect(fresca.marcadorA, 0);
      expect(fresca.marcadorB, 0);
      expect(fresca.turnoDibujante, 1);
      expect(container.read(pictionaryGeneroProvider), isNull);
    });
  });

  group('pictionaryCronometroProvider', () {
    test('iniciar → 60 corriendo; pausar congela; reanudar sigue (sin avanzar '
        'tiempo: decremento temporal = widget tests, P11)', () async {
      final container = crearContainer(SharedPreferencesAsync());
      final sub = container.listen(pictionaryCronometroProvider, (_, _) {});

      container.read(pictionaryCronometroProvider.notifier).iniciar();
      var crono = container.read(pictionaryCronometroProvider);
      expect(crono.segundosRestantes, 60);
      expect(crono.pausado, isFalse);
      expect(crono.terminado, isFalse);

      container.read(pictionaryCronometroProvider.notifier).pausar();
      crono = container.read(pictionaryCronometroProvider);
      expect(crono.pausado, isTrue);
      expect(crono.segundosRestantes, 60); // congelado

      container.read(pictionaryCronometroProvider.notifier).reanudar();
      crono = container.read(pictionaryCronometroProvider);
      expect(crono.pausado, isFalse);
      expect(crono.segundosRestantes, 60);
      sub.close();
      await container.pump();
    });
  });
}