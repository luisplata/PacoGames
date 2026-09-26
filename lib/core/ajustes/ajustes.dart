/// Modelo de ajustes persistidos de PACO.
library;

class Ajustes {
  const Ajustes({
    required this.sonido,
    required this.vibracion,
    required this.modoAlcohol,
    required this.generoPreferido,
    required this.splashVisto,
  });

  /// Versión del esquema persistido. Si la versión guardada difiere,
  /// los ajustes se resetean a [defaults] (R7).
  static const schemaVersion = 1;

  /// Valores por defecto ante prefs vacías o schema desactualizado.
  static const defaults = Ajustes(
    sonido: true,
    vibracion: true,
    modoAlcohol: false,
    generoPreferido: {},
    splashVisto: false,
  );

  final bool sonido;
  final bool vibracion;
  final bool modoAlcohol;

  /// Género preferido por juego (`juegoId → nombre`). Sin UI en M0,
  /// pero persiste para que M1-M3 lo lean.
  final Map<String, String> generoPreferido;

  /// `true` cuando el usuario ya vio (y aceptó) el splash.
  final bool splashVisto;

  Ajustes copyWith({
    bool? sonido,
    bool? vibracion,
    bool? modoAlcohol,
    Map<String, String>? generoPreferido,
    bool? splashVisto,
  }) {
    return Ajustes(
      sonido: sonido ?? this.sonido,
      vibracion: vibracion ?? this.vibracion,
      modoAlcohol: modoAlcohol ?? this.modoAlcohol,
      generoPreferido: generoPreferido ?? this.generoPreferido,
      splashVisto: splashVisto ?? this.splashVisto,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Ajustes &&
        other.sonido == sonido &&
        other.vibracion == vibracion &&
        other.modoAlcohol == modoAlcohol &&
        _mapEquals(other.generoPreferido, generoPreferido) &&
        other.splashVisto == splashVisto;
  }

  @override
  int get hashCode =>
      Object.hash(sonido, vibracion, modoAlcohol, splashVisto, Map.unmodifiable(generoPreferido));

  static bool _mapEquals(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }
}