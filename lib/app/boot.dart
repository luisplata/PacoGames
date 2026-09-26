import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/ajustes/ajustes_providers.dart';
import '../core/contenido/diagnostico.dart';
import '../core/contenido/entidades.dart';

/// Puente de boot entre la carga async de prefs/contenido y el router.
///
/// Es el `refreshListenable` del GoRouter: cada `notifyListeners()` hace
/// que el redirect top-level se re-evalúe (D2). Un solo notify cubre el
/// splash Y la auto-navegación a diagnóstico sin carreras.
class BootBridge extends ChangeNotifier {
  /// `null` = prefs todavía cargando (R2: el redirect asume !splashVisto).
  bool? splashVisto;

  /// Errores de contenido detectados en el boot (vacío = todo sano).
  List<ErrorContenido> errores = const [];

  void actualizar({
    required bool? splashVisto,
    required List<ErrorContenido> errores,
  }) {
    this.splashVisto = splashVisto;
    this.errores = errores;
    notifyListeners();
  }

  void marcarSplashVisto(bool v) {
    splashVisto = v;
    notifyListeners();
  }
}

/// Boot fire-and-forget (D4): carga ajustes y contenido UNA vez y vuelca
/// el resultado al bridge. Las fuentes son TOTALES (nunca lanzan), así el
/// notify siempre llega y el redirect nunca queda clavado en /splash.
final bootBridgeProvider = Provider<BootBridge>((ref) {
  final bridge = BootBridge();
  Future(() async {
    final ajustes = await ref.read(ajustesRepositoryProvider).cargarAjustes();
    final diagnostico = await ref.read(diagnosticoContenidoProvider.future);
    bridge.actualizar(
      splashVisto: ajustes.splashVisto,
      errores: diagnostico.errores,
    );
  });
  return bridge;
});