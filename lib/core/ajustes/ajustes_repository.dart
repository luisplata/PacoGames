import 'package:shared_preferences/shared_preferences.dart';

import 'ajustes.dart';

/// Persistencia de [Ajustes] con `SharedPreferencesAsync`.
///
/// Todas las operaciones son TOTALES (nunca lanzan): ante cualquier error
/// de lectura se devuelven [Ajustes.defaults] (contrato de boot, D4).
class AjustesRepository {
  AjustesRepository({SharedPreferencesAsync? prefs})
      : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  static const _schemaKey = 'ajustes.schemaVersion';
  static const _sonidoKey = 'ajustes.sonido';
  static const _vibracionKey = 'ajustes.vibracion';
  static const _modoAlcoholKey = 'ajustes.modoAlcohol';
  static const _splashVistoKey = 'ajustes.splashVisto';
  static const _generoPrefijo = 'ajustes.generoPreferido.';
  static const _juegoIds = ['yo_nunca', 'ruleta', 'pictionary'];

  /// Claves propias del repo: el reset con `allowList` borra SOLO estas
  /// (D7) y nunca toca claves de otros paquetes.
  static const keys = <String>{
    _schemaKey,
    _sonidoKey,
    _vibracionKey,
    _modoAlcoholKey,
    _splashVistoKey,
    '$_generoPrefijo' 'yo_nunca',
    '$_generoPrefijo' 'ruleta',
    '$_generoPrefijo' 'pictionary',
  };

  Future<Ajustes> cargarAjustes() async {
    try {
      final schema = await _prefs.getInt(_schemaKey);
      if (schema != Ajustes.schemaVersion) {
        // Schema desactualizado (o primera vez): reset a defaults (R7).
        await _prefs.clear(allowList: keys);
        await _escribir(Ajustes.defaults);
        return Ajustes.defaults;
      }

      final generoPreferido = <String, String>{};
      for (final id in _juegoIds) {
        final nombre = await _prefs.getString('$_generoPrefijo$id');
        if (nombre != null) generoPreferido[id] = nombre;
      }

      return Ajustes(
        sonido: await _prefs.getBool(_sonidoKey) ?? Ajustes.defaults.sonido,
        vibracion: await _prefs.getBool(_vibracionKey) ?? Ajustes.defaults.vibracion,
        modoAlcohol: await _prefs.getBool(_modoAlcoholKey) ?? Ajustes.defaults.modoAlcohol,
        generoPreferido: generoPreferido,
        splashVisto: await _prefs.getBool(_splashVistoKey) ?? Ajustes.defaults.splashVisto,
      );
    } catch (_) {
      return Ajustes.defaults;
    }
  }

  Future<void> guardarAjustes(Ajustes ajustes) async {
    try {
      await _escribir(ajustes);
    } catch (_) {
      // Total: falla silenciosa, no rompe el flujo.
    }
  }

  Future<void> marcarSplashVisto() async {
    final actual = await cargarAjustes();
    await guardarAjustes(actual.copyWith(splashVisto: true));
  }

  Future<void> _escribir(Ajustes a) async {
    await _prefs.setInt(_schemaKey, Ajustes.schemaVersion);
    await _prefs.setBool(_sonidoKey, a.sonido);
    await _prefs.setBool(_vibracionKey, a.vibracion);
    await _prefs.setBool(_modoAlcoholKey, a.modoAlcohol);
    await _prefs.setBool(_splashVistoKey, a.splashVisto);
    for (final id in _juegoIds) {
      final nombre = a.generoPreferido[id];
      if (nombre != null) {
        await _prefs.setString('$_generoPrefijo$id', nombre);
      }
    }
  }
}