import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ajustes/ajustes.dart';
import '../ajustes/ajustes_providers.dart';
import 'hapticos.dart';
import 'reproductor.dart';
import 'sonido_servicio.dart';

/// Reproductor real por defecto (overridable en tests — seam crítico AH3).
final reproductorProvider = Provider<Reproductor>(
  (ref) => ReproductorAudioplayers(),
);

/// Vibrador real por defecto (overridable en tests — AH5).
final vibradorProvider = Provider<Vibrador>(
  (ref) => const VibradorHapticFeedback(),
);

/// Servicio de sonido gated por `ajustes.sonido` (A4/A2).
///
/// `watch` + `select` sobre el toggle real: al flipar sonido, el provider
/// se reconstruye y el gating aplica a la siguiente interacción sin
/// reiniciar la app.
final sonidoServicioProvider = Provider<SonidoServicio>((ref) {
  final on = ref.watch(
    ajustesProvider.select((a) => a.value?.sonido ?? Ajustes.defaults.sonido),
  );
  return SonidoServicio(
    habilitado: on,
    reproductor: ref.watch(reproductorProvider),
  );
});

/// Servicio de hápticos gated por `ajustes.vibracion` (A2).
final hapticosServicioProvider = Provider<HapticosServicio>((ref) {
  final on = ref.watch(
    ajustesProvider.select(
      (a) => a.value?.vibracion ?? Ajustes.defaults.vibracion,
    ),
  );
  return HapticosServicio(
    habilitado: on,
    vibrador: ref.watch(vibradorProvider),
  );
});