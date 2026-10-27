import 'package:flutter_riverpod/flutter_riverpod.dart';
// Riverpod 3 mantiene StateProvider detrás de legacy.dart (diseño D3:
// nivel efímero con StateProvider.autoDispose).
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/ajustes/ajustes.dart';
import '../../../core/ajustes/ajustes_providers.dart';
import '../../../core/contenido/diagnostico.dart';
import '../../../core/contenido/entidades.dart';
import 'carta_yo_nunca.dart';
import 'mazo.dart';

/// Nivel elegido en `/yo-nunca` para la partida actual (YN3).
///
/// Default Normal y NO persistido: efímero. autoDispose lo descarta al salir
/// de la ruta; la página de reglas lo watchea, por eso sobrevive el push al
/// juego (la regla queda montada debajo).
final yoNuncaNivelProvider = StateProvider.autoDispose<NivelYoNunca>(
  (ref) => NivelYoNunca.normal,
);

/// Mazo de la partida actual (YN3): se compone con `cartasDelNivel` a partir
/// del nivel elegido, el diagnóstico y los ajustes; se descarta al salir.
final yoNuncaMazoProvider =
    NotifierProvider.autoDispose<MazoNotifier, Mazo<CartaYoNunca>>(
  MazoNotifier.new,
);

class MazoNotifier extends Notifier<Mazo<CartaYoNunca>> {
  @override
  Mazo<CartaYoNunca> build() {
    final nivel = ref.watch(yoNuncaNivelProvider);
    final diagnostico = ref.watch(diagnosticoContenidoProvider).value;
    final ajustes = ref.watch(ajustesProvider).value;
    // D8/A3: `true` = modo sin alcohol; el fallback de carga es el default
    // sobrio (no un `false` optimista).
    final sobrio = ajustes?.modoSinAlcohol ?? Ajustes.defaults.modoSinAlcohol;
    final generos =
        diagnostico?.contenidos['yo_nunca']?.generos ?? const <Genero>[];

    // `cartasDelNivel` ya fuerza Normal en modo sin alcohol (D4/YN10): el
    // nivel pedido NO se valida acá para no duplicar la única verdad.
    return Mazo.barajar(
      cartasDelNivel(generos, nivel: nivel, modoAlcohol: sobrio),
    );
  }

  void siguiente() => state = state.siguiente();

  void remezclar() => state = state.remezclar();
}
