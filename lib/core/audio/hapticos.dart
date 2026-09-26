import 'package:flutter/services.dart';

/// Vibrador inyectable (AH5): abstracción sobre HapticFeedback.
///
/// La UI NUNCA llama a HapticFeedback directamente: habla con esta interfaz
/// (inyectable en tests con un fake).
abstract class Vibrador {
  /// Ruleta que frena: mediumImpact.
  Future<void> ruletaFrenar();

  /// Tick del countdown (últimos 10 s): selectionClick.
  Future<void> tickTimer();

  /// Acierto en Pictionary: heavyImpact.
  Future<void> acierto();
}

/// Implementación real: wrappers de [HapticFeedback] con try/catch (AH5).
///
/// En web el engine no maneja el canal de haptics: el try/catch absorbe y
/// no crashea (web no-op documentado, D8).
class VibradorHapticFeedback implements Vibrador {
  const VibradorHapticFeedback();

  @override
  Future<void> ruletaFrenar() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {
      // Web/test sin canal: no-op.
    }
  }

  @override
  Future<void> tickTimer() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {
      // Web/test sin canal: no-op.
    }
  }

  @override
  Future<void> acierto() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {
      // Web/test sin canal: no-op.
    }
  }
}

/// Servicio de hápticos gated por el toggle real de Ajustes (AH5/A2).
///
/// Mapea cada acción al impacto correcto SOLO si `habilitado`; si
/// `vibracion == false`, 0 vibraciones (ninguna llamada al [Vibrador]).
class HapticosServicio {
  const HapticosServicio({required this.habilitado, required this.vibrador});

  final bool habilitado;
  final Vibrador vibrador;

  Future<void> ruletaFrenar() => _vibrar(vibrador.ruletaFrenar);

  Future<void> tickTimer() => _vibrar(vibrador.tickTimer);

  Future<void> acierto() => _vibrar(vibrador.acierto);

  Future<void> _vibrar(Future<void> Function() accion) async {
    if (!habilitado) return;
    await accion();
  }
}