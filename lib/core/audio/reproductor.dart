import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Seam de audio (AH3): abstracción del reproductor real.
///
/// La UI NUNCA habla con audioplayers directamente: habla con esta interfaz.
/// En tests se inyecta un fake (ReproductorFake) y en producción
/// [ReproductorAudioplayers] (o [ReproductorSilencioso] para no-op total).
abstract class Reproductor {
  /// Precalienta los pools (idempotente).
  Future<void> cargar();

  Future<void> reproducirClick();

  Future<void> reproducirTick();

  Future<void> reproducirFanfarria();

  Future<void> reproducirGiro();

  Future<void> reproducirCarta();

  /// No-op documentado v1 (A11): SFX cortos, el pool auto-libera al
  /// completar; no hace falta un stop global.
  Future<void> detener();

  Future<void> dispose();
}

/// Implementación real con audioplayers 6.5.1 (AH1/AH3).
///
/// - Un [AudioPool] por SFX (lazy): los ticks de 1/s se solapan en gama
///   baja; el pool reutiliza players (A1).
/// - AudioContextAndroid con usageType assistanceSonification: respeta el
///   silencio/vibrate del sistema (D7).
/// - try/catch doble en TODO: sin plugin (tests/web) nunca crashea (AH3).
class ReproductorAudioplayers implements Reproductor {
  final Map<String, AudioPool> _pools = {};

  static const _archivos = ['click', 'tick', 'fanfarria', 'giro', 'carta'];

  /// Contexto Android sonification (D7): verificable en test unit (AH1).
  @visibleForTesting
  static AudioContext get contextoAndroid => AudioContext(
        android: AudioContextAndroid(
          usageType: AndroidUsageType.assistanceSonification,
          contentType: AndroidContentType.sonification,
        ),
      );

  Future<AudioPool> _pool(String archivo) async {
    final existente = _pools[archivo];
    if (existente != null) return existente;
    // BytesSource en vez de AssetSource: carga el asset con rootBundle y
    // reproduce los bytes. Elimina el bug del doble-prefix 'assets/' de
    // audioplayers en web (audio_cache._sanitizeURLForWeb agrega 'assets/'
    // además del prefix → 404) y la dependencia del temp-file en Android.
    final bytes = await rootBundle.load('assets/audio/$archivo.ogg');
    final pool = await AudioPool.create(
      source: BytesSource(bytes.buffer.asUint8List()),
      maxPlayers: 4,
      audioContext: contextoAndroid,
    );
    _pools[archivo] = pool;
    return pool;
  }

  Future<void> _reproducir(String archivo) async {
    try {
      final pool = await _pool(archivo);
      await pool.start();
    } catch (_) {
      // Entorno sin plugin (test/web): nunca crashear.
    }
  }

  @override
  Future<void> cargar() async {
    for (final archivo in _archivos) {
      try {
        await _pool(archivo);
      } catch (_) {
        // Sin plugin: no-op.
      }
    }
  }

  @override
  Future<void> reproducirClick() => _reproducir('click');

  @override
  Future<void> reproducirTick() => _reproducir('tick');

  @override
  Future<void> reproducirFanfarria() => _reproducir('fanfarria');

  @override
  Future<void> reproducirGiro() => _reproducir('giro');

  @override
  Future<void> reproducirCarta() => _reproducir('carta');

  @override
  Future<void> detener() async {
    // A11: SFX cortos; el pool auto-libera al completar.
  }

  @override
  Future<void> dispose() async {
    for (final pool in _pools.values) {
      try {
        await pool.dispose();
      } catch (_) {
        // Sin plugin: no-op.
      }
    }
    _pools.clear();
  }
}

/// Reproductor no-op total (A5): seam determinista para tests y modo
/// silencioso. Ninguna operación produce efecto ni error.
class ReproductorSilencioso implements Reproductor {
  const ReproductorSilencioso();

  @override
  Future<void> cargar() async {}

  @override
  Future<void> reproducirClick() async {}

  @override
  Future<void> reproducirTick() async {}

  @override
  Future<void> reproducirFanfarria() async {}

  @override
  Future<void> reproducirGiro() async {}

  @override
  Future<void> reproducirCarta() async {}

  @override
  Future<void> detener() async {}

  @override
  Future<void> dispose() async {}
}