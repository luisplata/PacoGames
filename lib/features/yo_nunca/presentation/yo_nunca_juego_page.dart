import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ajustes/ajustes.dart';
import '../../../core/ajustes/ajustes_providers.dart';
import '../../../core/audio/sonido_provider.dart';
import '../../../core/contenido/diagnostico.dart';
import '../../../core/widgets/aviso_modo_sin_alcohol.dart';
import '../application/carta_yo_nunca.dart';
import '../application/mazo.dart';
import '../application/yo_nunca_providers.dart';
import 'widgets/carta_yo_nunca_flip.dart';

/// Juego de Yo Nunca (YN4-YN6, YN8): sin picker, arranca directo con el
/// nivel elegido en reglas y la primera carta BOCA ABAJO (dorso por tipo).
/// El widget [CartaYoNuncaFlip] es dueño del reveal; esta página espeja si
/// terminó (`_revelada`) para habilitar `[Siguiente]`.
class YoNuncaJuegoPage extends ConsumerStatefulWidget {
  const YoNuncaJuegoPage({super.key});

  @override
  ConsumerState<YoNuncaJuegoPage> createState() => _YoNuncaJuegoPageState();
}

class _YoNuncaJuegoPageState extends ConsumerState<YoNuncaJuegoPage> {
  /// Permite el pop real tras confirmar la salida (D6): con canPop false
  /// `context.pop()` quedaría bloqueado por el PopScope.
  bool _salirConfirmado = false;

  /// Espejo del flip: habilita `[Siguiente]` solo al terminar la animación.
  bool _revelada = false;

  /// El juramento se muestra solo en la primera carta de la partida (D7);
  /// no se resetea al remezclar, sí al re-entrar (autoDispose de la página).
  bool _juramentoCumplido = false;

  /// Fuerza un estado limpio del flip aunque la primera carta coincida tras
  /// una reconstrucción externa del mazo o una remezcla.
  int _generacion = 0;

  Future<void> _mostrarDialogoSalida() async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Salir de la partida?'),
        content: const Text('Perdés el mazo actual'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Seguir jugando'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );
    if (salir == true && mounted) {
      setState(() => _salirConfirmado = true);
      context.pop(); // canPop ahora true → descarta estado (autoDispose).
    }
  }

  void _onBackPressed() {
    // "Partida en curso" = el mazo tiene cartas (antes: género elegido).
    final total = ref.read(yoNuncaMazoProvider).total;
    if (total == 0 || _salirConfirmado) {
      context.pop();
    } else {
      _mostrarDialogoSalida();
    }
  }

  void _onRevelada() {
    if (!mounted) return;
    setState(() {
      _revelada = true;
      _juramentoCumplido = true;
    });
  }

  void _siguiente() {
    // AH6: click en [Siguiente].
    ref.read(sonidoServicioProvider).reproducirClick();
    ref.read(yoNuncaMazoProvider.notifier).siguiente();
    setState(() {
      _revelada = false;
      _generacion++;
    });
  }

  void _remezclar() {
    // AH6: click en [Mezclar de nuevo].
    ref.read(sonidoServicioProvider).reproducirClick();
    ref.read(yoNuncaMazoProvider.notifier).remezclar();
    setState(() {
      _revelada = false;
      _generacion++;
    });
  }

  String _nombreNivel(NivelYoNunca nivel) =>
      nivel == NivelYoNunca.picante ? 'Picante' : 'Normal';

  @override
  Widget build(BuildContext context) {
    final diagnostico = ref.watch(diagnosticoContenidoProvider);
    final ajustes = ref.watch(ajustesProvider);
    final nivel = ref.watch(yoNuncaNivelProvider);
    // WU2 usa el campo + `Ajustes.defaults`; WU4 cambia default y getter.
    final modoAlcohol =
        ajustes.value?.modoAlcohol ?? Ajustes.defaults.modoAlcohol;
    final efectivo = nivelEfectivo(elegido: nivel, modoAlcohol: modoAlcohol);

    // Reconstrucción externa del mazo (nivel/ajustes): la carta nace limpia
    // y boca abajo. El SFX `carta` ahora vive en el tap del flip, no acá.
    ref.listen(yoNuncaMazoProvider, (prev, next) {
      if (prev != null && next.total != prev.total) {
        setState(() {
          _revelada = false;
          _generacion++;
        });
      }
    });

    final mazo = ref.watch(yoNuncaMazoProvider);

    return Scaffold(
      body: PopScope(
        canPop: mazo.total == 0 || _salirConfirmado,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && mazo.total > 0 && !_salirConfirmado) {
            _mostrarDialogoSalida();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/fondo_madera2.webp', fit: BoxFit.cover),
            ColoredBox(color: Colors.black.withValues(alpha: .35)),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        BackButton(
                          color: Colors.white,
                          onPressed: _onBackPressed,
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Wrap(
                              alignment: WrapAlignment.end,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (modoAlcohol) const AvisoModoSinAlcohol(),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    'Nivel: ${_nombreNivel(efectivo)}',
                                    key: const Key('nivel_partida'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (mazo.total > 0 && mazo.total < 5)
                                  _pocoContenido(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: switch (diagnostico) {
                      AsyncData() => _contenido(mazo),
                      _ => const Center(child: CircularProgressIndicator()),
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pocoContenido() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Poco contenido en este nivel',
        style: TextStyle(
          color: Colors.white.withValues(alpha: .9),
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _contenido(Mazo<CartaYoNunca> mazo) {
    if (mazo.total == 0) {
      // Edge defensivo YN4: sin cartas para el nivel → C16, sin crash.
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Sin cartas disponibles en este nivel.',
            key: const Key('sin_cartas_nivel'),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
        ),
      );
    }

    if (mazo.agotado) {
      // Fin de mazo (YN6): remezcla explícita del usuario (D2).
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.style_outlined, size: 64, color: Colors.white70),
              const SizedBox(height: 16),
              Text(
                'Se acabaron las cartas: se mezclan de nuevo',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _remezclar,
                child: const Text('Mezclar de nuevo'),
              ),
            ],
          ),
        ),
      );
    }

    final carta = mazo.cartaActual!;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: CartaYoNuncaFlip(
              key: ValueKey('${carta.texto}|${carta.nivel.name}|$_generacion'),
              carta: carta,
              mostrarJuramento: !_juramentoCumplido,
              onRevelada: _onRevelada,
              onRevelarIniciado: () =>
                  ref.read(sonidoServicioProvider).reproducirCarta(),
            ),
          ),
        ),
        // Alto fijo: [Siguiente] no empuja la carta al aparecer (design §5).
        SizedBox(
          height: 72,
          child: Center(
            child: _revelada
                ? FilledButton(
                    onPressed: _siguiente,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 14,
                      ),
                    ),
                    child: const Text(
                      'Siguiente',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}
