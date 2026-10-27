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

/// Juego de Yo Nunca (YN4-YN6, YN8) — paso intermedio de WU2: sin picker,
/// arranca directo con el nivel elegido en reglas y muestra el frente con la
/// imagen arriba + frase abajo. El flip/juramento llega en WU3.
class YoNuncaJuegoPage extends ConsumerStatefulWidget {
  const YoNuncaJuegoPage({super.key});

  @override
  ConsumerState<YoNuncaJuegoPage> createState() => _YoNuncaJuegoPageState();
}

class _YoNuncaJuegoPageState extends ConsumerState<YoNuncaJuegoPage> {
  /// Permite el pop real tras confirmar la salida (D6): con canPop false
  /// `context.pop()` quedaría bloqueado por el PopScope.
  bool _salirConfirmado = false;

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

  String _nombreNivel(NivelYoNunca nivel) =>
      nivel == NivelYoNunca.picante ? 'Picante' : 'Normal';

  @override
  Widget build(BuildContext context) {
    final diagnostico = ref.watch(diagnosticoContenidoProvider);
    final ajustes = ref.watch(ajustesProvider);
    final nivel = ref.watch(yoNuncaNivelProvider);
    // WU2 usa el campo + `Ajustes.defaults`; WU4 cambia default y getter.
    final modoAlcohol = ajustes.value?.modoAlcohol ?? Ajustes.defaults.modoAlcohol;
    final efectivo = nivelEfectivo(elegido: nivel, modoAlcohol: modoAlcohol);

    // AH6 (interino): SFX `carta` al cambiar la carta visible (Siguiente,
    // mezclar, cambio de mazo). El tap-reveal de WU3 mueve este SFX al tap.
    ref.listen(yoNuncaMazoProvider, (prev, next) {
      final anterior = prev?.cartaActual?.texto;
      final actual = next.cartaActual;
      // `prev.total == 0` es la carga inicial (diagnóstico/ajustes aún
      // resolviendo), no un avance real: no suena.
      if (prev != null &&
          prev.total > 0 &&
          actual != null &&
          actual.texto != anterior) {
        ref.read(sonidoServicioProvider).reproducirCarta();
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
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  // AH6: click en [Mezclar de nuevo].
                  ref.read(sonidoServicioProvider).reproducirClick();
                  ref.read(yoNuncaMazoProvider.notifier).remezclar();
                },
                child: const Text('Mezclar de nuevo'),
              ),
            ],
          ),
        ),
      );
    }

    final carta = mazo.cartaActual!;
    final pocoContenido = mazo.total < 5;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Layout interino de WU2 (el flip llega en WU3).
          Image.asset(
            'assets/images/carta_${carta.nivel.name}.webp',
            height: 180,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          Text(
            carta.texto,
            key: const Key('frase_yo_nunca'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  height: 1.3,
                ),
          ),
          if (pocoContenido) ...[
            const SizedBox(height: 12),
            Text(
              'Poco contenido en este nivel',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .85),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () {
              // AH6: click en [Siguiente].
              ref.read(sonidoServicioProvider).reproducirClick();
              ref.read(yoNuncaMazoProvider.notifier).siguiente();
            },
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            ),
            child: const Text('Siguiente', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}
