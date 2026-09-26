import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3 mantiene StateProvider detrás de legacy.dart (patrón M1 dev-3:
// el género seleccionado es StateProvider.autoDispose).
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/ajustes/ajustes_providers.dart';
import '../../../core/contenido/diagnostico.dart';
import '../../../core/contenido/entidades.dart';
import 'ruleta.dart';

/// Género seleccionado de la partida de ruleta (RU7, R9).
///
/// `null` = sin género → la UI hace auto-select (1 visible) o picker.
/// Efímero: autoDispose descarta el estado al salir de la ruta
/// (re-entrar = partida fresca).
final ruletaGeneroProvider = StateProvider.autoDispose<String?>((ref) => null);

/// Ruleta de la partida actual (RU7): se construye del género seleccionado
/// y las cartas reales de `ruleta.json`; se descarta al salir (autoDispose).
final ruletaProvider = NotifierProvider.autoDispose<RuletaNotifier, Ruleta>(
  RuletaNotifier.new,
);

class RuletaNotifier extends Notifier<Ruleta> {
  @override
  Ruleta build() {
    final genero = ref.watch(ruletaGeneroProvider);
    final diagnostico = ref.watch(diagnosticoContenidoProvider).value;
    // Ajustes: dependencia del diseño — si cambia modoAlcohol, la ruleta
    // se reconstruye (el picker ya impide elegir Picante en ese modo).
    ref.watch(ajustesProvider);
    return Ruleta.iniciar(_cartasDelGenero(diagnostico, genero));
  }

  /// Cartas del género seleccionado; desconocido/ausente → `[]` (ruleta
  /// vacía, sin crash — RU7 edge defensivo).
  List<String> _cartasDelGenero(DiagnosticoContenido? diagnostico, String? genero) {
    if (genero == null || diagnostico == null) return const [];
    final juego = diagnostico.contenidos['ruleta'];
    if (juego == null) return const [];
    for (final g in juego.generos) {
      if (g.nombre == genero) return g.cartas;
    }
    return const [];
  }

  /// Escribe el género seleccionado → la ruleta se reconstruye (R5).
  void seleccionarGenero(String genero) {
    ref.read(ruletaGeneroProvider.notifier).state = genero;
  }

  /// Gira con [random] inyectable para determinismo en tests (RU5).
  void girar([Random? random]) => state = state.girar(random: random);

  void siguiente() => state = state.siguiente();
}