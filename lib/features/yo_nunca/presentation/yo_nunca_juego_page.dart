import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ajustes/ajustes.dart';
import '../../../core/ajustes/ajustes_providers.dart';
import '../../../core/contenido/diagnostico.dart';
import '../../../core/contenido/entidades.dart';
import '../../../core/contenido/generos_visibles.dart';
import '../../../core/widgets/aviso_modo_sin_alcohol.dart';
import '../application/yo_nunca_providers.dart';

/// Juego de Yo Nunca (YN4-YN6, YN8): picker de género → mazo → frase +
/// [Siguiente]; modo sin alcohol de doble efecto (banner + Picante oculto);
/// salida mid-game con confirmación (estado efímero autoDispose).
class YoNuncaJuegoPage extends ConsumerStatefulWidget {
  const YoNuncaJuegoPage({super.key});

  @override
  ConsumerState<YoNuncaJuegoPage> createState() => _YoNuncaJuegoPageState();
}

class _YoNuncaJuegoPageState extends ConsumerState<YoNuncaJuegoPage> {
  /// Auto-select post-frame: se dispara UNA vez (D4). Idempotente: el
  /// callback re-chequea que el género siga null antes de escribir.
  bool _autoSeleccionPendiente = true;

  /// Permite el pop real tras confirmar la salida (D6): con canPop false
  /// `context.pop()` quedaría bloqueado por el PopScope.
  bool _salirConfirmado = false;

  /// Selección visual del chip (default = generoPreferido si sigue visible).
  String? _seleccion;

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
    final genero = ref.read(yoNuncaGeneroProvider);
    if (genero == null || _salirConfirmado) {
      context.pop();
    } else {
      _mostrarDialogoSalida();
    }
  }

  void _elegirGenero(String nombre) {
    setState(() => _seleccion = nombre);
    ref.read(yoNuncaMazoProvider.notifier).seleccionarGenero(nombre);
    // Persistencia explícita del preferido (D5, proposal D5).
    ref.read(ajustesProvider.notifier).setGeneroPreferido('yo_nunca', nombre);
  }

  Genero? _generoInfo(DiagnosticoContenido? diagnostico, String nombre) {
    final juego = diagnostico?.contenidos['yo_nunca'];
    if (juego == null) return null;
    for (final g in juego.generos) {
      if (g.nombre == nombre) return g;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final genero = ref.watch(yoNuncaGeneroProvider);
    final diagnostico = ref.watch(diagnosticoContenidoProvider);
    final ajustes = ref.watch(ajustesProvider);
    final modoAlcohol = ajustes.value?.modoAlcohol ?? false;

    final visibles = generosVisibles(
      diagnostico.value?.contenidos['yo_nunca']?.generos ?? const <Genero>[],
      modoAlcohol: modoAlcohol,
    );

    // Auto-select: exactamente 1 género visible → arranca directo (YN4),
    // SIN persistir preferido (D4). Se decide UNA sola vez, y solo cuando
    // diagnostico Y ajustes ya cargaron: con modoAlcohol aún en loading el
    // set de visibles sería el equivocado (picante no oculto).
    if (_autoSeleccionPendiente &&
        genero == null &&
        diagnostico.value != null &&
        ajustes.value != null) {
      _autoSeleccionPendiente = false;
      if (visibles.length == 1) {
        final unico = visibles.first.nombre;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && ref.read(yoNuncaGeneroProvider) == null) {
            ref.read(yoNuncaMazoProvider.notifier).seleccionarGenero(unico);
          }
        });
      }
    }

    return Scaffold(
      body: PopScope(
        canPop: genero == null || _salirConfirmado,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && genero != null && !_salirConfirmado) {
            _mostrarDialogoSalida();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/fondo_madera2.png', fit: BoxFit.cover),
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
                        if (modoAlcohol) const AvisoModoSinAlcohol(),
                      ],
                    ),
                  ),
                  Expanded(
                    child: switch (diagnostico) {
                      AsyncData(:final value) => genero == null
                          ? _picker(visibles, value, ajustes.value)
                          : _carta(genero, value),
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

  Widget _picker(List<Genero> visibles, DiagnosticoContenido diagnostico,
      Ajustes? ajustes) {
    if (visibles.isEmpty) {
      // Edge defensivo YN4: solo-Picante + modo sin alcohol.
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Sin géneros disponibles en este modo',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
        ),
      );
    }

    // Default visual: generoPreferido solo si sigue siendo visible (D-risk).
    final preferido = ajustes?.generoPreferido['yo_nunca'];
    final preseleccion =
        (preferido != null && visibles.any((g) => g.nombre == preferido))
            ? preferido
            : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Elegí un género',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamily: 'Grobold',
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            children: [
              for (final genero in visibles)
                ChoiceChip(
                  label: Text(genero.nombre),
                  selected: (_seleccion ?? preseleccion) == genero.nombre,
                  onSelected: (_) => _elegirGenero(genero.nombre),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _carta(String genero, DiagnosticoContenido diagnostico) {
    final mazo = ref.watch(yoNuncaMazoProvider);
    final notifier = ref.read(yoNuncaMazoProvider.notifier);

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
                onPressed: notifier.remezclar,
                child: const Text('Mezclar de nuevo'),
              ),
            ],
          ),
        ),
      );
    }

    final generoInfo = _generoInfo(diagnostico, genero);
    final pocoContenido =
        generoInfo != null && generoInfo.cartas.length < 5;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Image.asset(
            genero == 'Picante'
                ? 'assets/images/carta_picante.png'
                : 'assets/images/carta_normal.png',
            height: 180,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          Text(
            mazo.cartaActual!,
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
              'Poco contenido en este género',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .85),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          const SizedBox(height: 32),
          FilledButton(
            onPressed: notifier.siguiente,
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