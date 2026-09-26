import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:paco_game/core/ajustes/ajustes.dart';
import 'package:paco_game/core/ajustes/ajustes_repository.dart';

void main() {
  late SharedPreferencesAsync prefs;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    prefs = SharedPreferencesAsync();
  });

  group('AjustesRepository', () {
    test('prefs vacías → defaults', () async {
      final repo = AjustesRepository(prefs: prefs);

      final ajustes = await repo.cargarAjustes();

      expect(ajustes.sonido, isTrue);
      expect(ajustes.vibracion, isTrue);
      expect(ajustes.modoAlcohol, isFalse);
      expect(ajustes.generoPreferido, isEmpty);
      expect(ajustes.splashVisto, isFalse);
    });

    test('round-trip guardar → cargar conserva todos los valores', () async {
      final repo = AjustesRepository(prefs: prefs);

      await repo.guardarAjustes(
        Ajustes(
          sonido: false,
          vibracion: false,
          modoAlcohol: true,
          generoPreferido: const {'yo_nunca': 'Picante', 'ruleta': 'Normal'},
          splashVisto: true,
        ),
      );
      final ajustes = await repo.cargarAjustes();

      expect(ajustes.sonido, isFalse);
      expect(ajustes.vibracion, isFalse);
      expect(ajustes.modoAlcohol, isTrue);
      expect(ajustes.generoPreferido, {'yo_nunca': 'Picante', 'ruleta': 'Normal'});
      expect(ajustes.splashVisto, isTrue);
    });

    test('schema version distinto → reset a defaults y schema reescrito', () async {
      await prefs.setInt('ajustes.schemaVersion', 99);
      await prefs.setBool('ajustes.sonido', false);
      await prefs.setBool('ajustes.splashVisto', true);
      final repo = AjustesRepository(prefs: prefs);

      final ajustes = await repo.cargarAjustes();

      expect(ajustes, equals(Ajustes.defaults));
      expect(ajustes.splashVisto, isFalse, reason: 'el schema cambió: el splash se vuelve a mostrar');
      expect(await prefs.getInt('ajustes.schemaVersion'), Ajustes.schemaVersion);
    });

    test('marcarSplashVisto persiste el flag', () async {
      final repo = AjustesRepository(prefs: prefs);

      await repo.marcarSplashVisto();
      final ajustes = await repo.cargarAjustes();

      expect(ajustes.splashVisto, isTrue);
      expect(ajustes.sonido, isTrue, reason: 'el resto de defaults no se pisa');
    });
  });
}