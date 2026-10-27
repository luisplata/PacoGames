import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:paco_game/core/ajustes/ajustes.dart';
import 'package:paco_game/core/ajustes/ajustes_repository.dart';

const _markerKey = 'ajustes.migracionModoSinAlcohol';

void main() {
  late SharedPreferencesAsync prefs;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    prefs = SharedPreferencesAsync();
  });

  group('AjustesRepository', () {
    test('keys incluye el marker de migración de modo sin alcohol', () {
      expect(AjustesRepository.keys, contains(_markerKey));
    });

    test('prefs vacías → defaults sobrios (modoAlcohol true + marker)',
        () async {
      final repo = AjustesRepository(prefs: prefs);

      final ajustes = await repo.cargarAjustes();

      expect(ajustes.sonido, isTrue);
      expect(ajustes.vibracion, isTrue);
      expect(ajustes.modoAlcohol, isTrue,
          reason: 'modo sin alcohol ON por defecto');
      expect(ajustes.modoSinAlcohol, isTrue);
      expect(ajustes.generoPreferido, isEmpty);
      expect(ajustes.splashVisto, isFalse);
      expect(await prefs.getBool(_markerKey), isTrue,
          reason: 'la migración queda marcada');
      expect(await prefs.getBool('ajustes.modoAlcohol'), isTrue);
    });

    test('false viejo sin marker → migra a true y preserva el resto',
        () async {
      await prefs.setInt('ajustes.schemaVersion', 1);
      await prefs.setBool('ajustes.modoAlcohol', false);
      await prefs.setBool('ajustes.sonido', false);
      await prefs.setBool('ajustes.splashVisto', true);
      final repo = AjustesRepository(prefs: prefs);

      final ajustes = await repo.cargarAjustes();

      expect(ajustes.modoAlcohol, isTrue);
      expect(ajustes.sonido, isFalse,
          reason: 'la migración no resetea el resto de ajustes');
      expect(ajustes.splashVisto, isTrue,
          reason: 'el schema no cambia: el splash no se vuelve a mostrar');
      expect(await prefs.getBool(_markerKey), isTrue);
      expect(await prefs.getInt('ajustes.schemaVersion'), 1,
          reason: 'sin bump de schemaVersion');
    });

    test('marker presente + false explícito → respeta la elección',
        () async {
      await prefs.setInt('ajustes.schemaVersion', 1);
      await prefs.setBool(_markerKey, true);
      await prefs.setBool('ajustes.modoAlcohol', false);
      final repo = AjustesRepository(prefs: prefs);

      final ajustes = await repo.cargarAjustes();

      expect(ajustes.modoAlcohol, isFalse);
      expect(ajustes.modoSinAlcohol, isFalse);
    });

    test('marker presente + true → queda en modo sin alcohol', () async {
      await prefs.setInt('ajustes.schemaVersion', 1);
      await prefs.setBool(_markerKey, true);
      await prefs.setBool('ajustes.modoAlcohol', true);
      final repo = AjustesRepository(prefs: prefs);

      final ajustes = await repo.cargarAjustes();

      expect(ajustes.modoAlcohol, isTrue);
      expect(ajustes.modoSinAlcohol, isTrue);
    });

    test('guardarAjustes escribe el marker y la próxima carga es autoritativa',
        () async {
      final repo = AjustesRepository(prefs: prefs);

      await repo.guardarAjustes(
        const Ajustes(
          sonido: true,
          vibracion: true,
          modoAlcohol: false,
          generoPreferido: {},
          splashVisto: true,
        ),
      );

      expect(await prefs.getBool(_markerKey), isTrue);
      expect(await prefs.getBool('ajustes.modoAlcohol'), isFalse);

      // Un repo nuevo sobre las mismas prefs respeta el false guardado.
      final recargado =
          await AjustesRepository(prefs: SharedPreferencesAsync()).cargarAjustes();
      expect(recargado.modoAlcohol, isFalse);
    });

    test('round-trip guardar → cargar conserva todos los valores', () async {
      final repo = AjustesRepository(prefs: prefs);

      await repo.guardarAjustes(
        const Ajustes(
          sonido: false,
          vibracion: false,
          modoAlcohol: true,
          generoPreferido: {'yo_nunca': 'Picante', 'ruleta': 'Normal'},
          splashVisto: true,
        ),
      );
      final ajustes = await repo.cargarAjustes();

      expect(ajustes.sonido, isFalse);
      expect(ajustes.vibracion, isFalse);
      expect(ajustes.modoAlcohol, isTrue);
      expect(ajustes.generoPreferido,
          {'yo_nunca': 'Picante', 'ruleta': 'Normal'});
      expect(ajustes.splashVisto, isTrue);
    });

    test('schema version distinto → reset a defaults sobrios y schema reescrito',
        () async {
      await prefs.setInt('ajustes.schemaVersion', 99);
      await prefs.setBool('ajustes.sonido', false);
      await prefs.setBool('ajustes.splashVisto', true);
      final repo = AjustesRepository(prefs: prefs);

      final ajustes = await repo.cargarAjustes();

      expect(ajustes, equals(Ajustes.defaults));
      expect(ajustes.modoAlcohol, isTrue);
      expect(ajustes.splashVisto, isFalse,
          reason: 'el schema cambió: el splash se vuelve a mostrar');
      expect(await prefs.getInt('ajustes.schemaVersion'), Ajustes.schemaVersion);
      expect(await prefs.getBool(_markerKey), isTrue);
    });

    test('marcarSplashVisto persiste el flag sin perder el modo sobrio',
        () async {
      final repo = AjustesRepository(prefs: prefs);

      await repo.marcarSplashVisto();
      final ajustes = await repo.cargarAjustes();

      expect(ajustes.splashVisto, isTrue);
      expect(ajustes.modoAlcohol, isTrue,
          reason: 'el resto de defaults no se pisa');
      expect(ajustes.sonido, isTrue);
    });
  });
}
