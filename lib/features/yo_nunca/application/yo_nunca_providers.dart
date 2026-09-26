import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3 mantiene StateProvider detrás de legacy.dart (diseño M1 lo
// especifica para el género seleccionado: StateProvider.autoDispose).
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/ajustes/ajustes_providers.dart';
import '../../../core/contenido/diagnostico.dart';
import '../../../core/contenido/entidades.dart';
import 'mazo.dart';

/// Géneros visibles según el modo sin alcohol (YN2).
///
/// Filtra SOLO el género cuyo nombre (case-insensitive) es `'picante'`
/// cuando [modoAlcohol] es `true`. Nunca reordena ni reescribe contenido.
List<Genero> generosVisibles(List<Genero> generos, {required bool modoAlcohol}) {
  if (!modoAlcohol) return generos;
  return generos.where((g) => g.nombre.toLowerCase() != 'picante').toList();
}

/// Género seleccionado de la partida actual (YN3).
///
/// `null` = sin género → la UI muestra el picker. Efímero: autoDispose
/// descarta el estado al salir de la ruta (re-entrar = picker fresco).
final yoNuncaGeneroProvider = StateProvider.autoDispose<String?>((ref) => null);

/// Mazo de la partida actual (YN3): se construye del género seleccionado
/// y se descarta al salir (autoDispose, sin listeners).
final yoNuncaMazoProvider = NotifierProvider.autoDispose<MazoNotifier, Mazo>(
  MazoNotifier.new,
);

class MazoNotifier extends Notifier<Mazo> {
  @override
  Mazo build() {
    final genero = ref.watch(yoNuncaGeneroProvider);
    final diagnostico = ref.watch(diagnosticoContenidoProvider).value;
    // Ajustes: dependencia del diseño — si cambia modoAlcohol, el mazo
    // se reconstruye (el picker ya impide elegir Picante en ese modo).
    ref.watch(ajustesProvider);
    return Mazo.barajar(_cartasDelGenero(diagnostico, genero));
  }

  /// Cartas del género seleccionado; desconocido/ausente → `[]` (mazo vacío,
  /// sin crash — YN4 edge defensivo).
  List<String> _cartasDelGenero(DiagnosticoContenido? diagnostico, String? genero) {
    if (genero == null || diagnostico == null) return const [];
    final juego = diagnostico.contenidos['yo_nunca'];
    if (juego == null) return const [];
    for (final g in juego.generos) {
      if (g.nombre == genero) return g.cartas;
    }
    return const [];
  }

  /// Escribe el género seleccionado → el mazo se reconstruye (D5).
  void seleccionarGenero(String genero) {
    ref.read(yoNuncaGeneroProvider.notifier).state = genero;
  }

  void siguiente() => state = state.siguiente();

  void remezclar() => state = state.remezclar();
}