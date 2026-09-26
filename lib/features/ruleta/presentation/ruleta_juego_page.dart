import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ajustes/ajustes.dart';
import '../../../core/ajustes/ajustes_providers.dart';
import '../../../core/audio/sonido_provider.dart';
import '../../../core/contenido/diagnostico.dart';
import '../../../core/contenido/entidades.dart';
import '../../../core/contenido/generos_visibles.dart';
import '../../../core/widgets/aviso_modo_sin_alcohol.dart';
import '../application/ruleta.dart';
import '../application/ruleta_providers.dart';

/// Juego de la Ruleta (RU4-RU8): picker de género → rueda animada con
/// desaceleración (~3 s, AnimatedRotation onEnd reveal) → resultado en
/// grande + [Siguiente]; pass-turn con aviso; banner modo sin alcohol
/// "trago = punto/prenda"; salida mid-game con confirmación (estado
/// efímero autoDispose).
class RuletaJuegoPage extends ConsumerStatefulWidget {
  const RuletaJuegoPage({super.key});

  @override
  ConsumerState<RuletaJuegoPage> createState() => _RuletaJuegoPageState();
}

class _RuletaJuegoPageState extends ConsumerState<RuletaJuegoPage> {
  /// Auto-select post-frame (R5, patrón M1 dev-6): se dispara UNA vez y
  /// solo cuando diagnostico Y ajustes cargaron (con modoAlcohol en loading
  /// el set de visibles sería el equivocado).
  bool _autoSeleccionPendiente = true;

  /// Permite el pop real tras confirmar la salida (D6): con canPop false
  /// `context.pop()` quedaría bloqueado por el PopScope.
  bool _salirConfirmado = false;

  /// True mientras la rueda anima: bloquea [Girar] (R6, sin re-entradas).
  bool _girando = false;

  /// Vueltas acumuladas del AnimatedRotation: el espectáculo crece con cada
  /// giro (R4). El texto grande del resultado es la verdad.
  double _turnsAcumulados = 0;

  /// Selección visual del chip (default = generoPreferido si sigue visible).
  String? _seleccion;

  Future<void> _mostrarDialogoSalida() async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Salir de la partida?'),
        content: const Text('Perdés el historial de la ronda'),
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
    final genero = ref.read(ruletaGeneroProvider);
    if (genero == null || _salirConfirmado) {
      context.pop();
    } else {
      _mostrarDialogoSalida();
    }
  }

  void _elegirGenero(String nombre) {
    setState(() => _seleccion = nombre);
    ref.read(ruletaProvider.notifier).seleccionarGenero(nombre);
    // Persistencia explícita del preferido (diseño M1, A1 genérico).
    ref.read(ajustesProvider.notifier).setGeneroPreferido('ruleta', nombre);
  }

  /// Gira: el resultado se elige PRIMERO (Random interno del notifier) y la
  /// animación es espectáculo (R4). Aterrizaje best-effort: asume 16
  /// secciones × 22,5°; si el arte no coincide, el texto sigue siendo la
  /// verdad. Cartas vacías → no-op defensivo (0 géneros nunca llega acá).
  void _girar() {
    // AH6: giro al arrancar la animación (gated por ajustes.sonido).
    ref.read(sonidoServicioProvider).reproducirGiro();
    setState(() => _girando = true);
    ref.read(ruletaProvider.notifier).girar();
    final girada = ref.read(ruletaProvider);
    final resultado = girada.resultado;
    if (resultado == null) {
      setState(() => _girando = false); // ruleta vacía: nada que animar
      return;
    }
    final idx = girada.cartas.indexOf(resultado);
    setState(() {
      _turnsAcumulados += 4 + (idx + 0.5) / girada.cartas.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final genero = ref.watch(ruletaGeneroProvider);
    final diagnostico = ref.watch(diagnosticoContenidoProvider);
    final ajustes = ref.watch(ajustesProvider);
    final modoAlcohol = ajustes.value?.modoAlcohol ?? false;

    final visibles = generosVisibles(
      diagnostico.value?.contenidos['ruleta']?.generos ?? const <Genero>[],
      modoAlcohol: modoAlcohol,
    );

    // Auto-select (RU8): exactamente 1 género visible → arranca directo,
    // SIN persistir preferido. Decisión post-frame (dev-6 M1): el género se
    // escribe FUERA del build para que el PopScope (canPop: genero == null)
    // exija el diálogo de salida en el flujo real.
    if (_autoSeleccionPendiente &&
        genero == null &&
        diagnostico.value != null &&
        ajustes.value != null) {
      _autoSeleccionPendiente = false;
      if (visibles.length == 1) {
        final unico = visibles.first.nombre;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && ref.read(ruletaGeneroProvider) == null) {
            ref.read(ruletaProvider.notifier).seleccionarGenero(unico);
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
                        if (modoAlcohol)
                          const AvisoModoSinAlcohol(
                            texto: 'Modo sin alcohol: trago = punto/prenda',
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: switch (diagnostico) {
                      AsyncData(:final value) => genero == null
                          ? _picker(visibles, value, ajustes.value)
                          : _rueda(genero),
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
      // Edge defensivo RU8: solo-Picante + modo sin alcohol.
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

    // Default visual: generoPreferido solo si sigue siendo visible.
    final preferido = ajustes?.generoPreferido['ruleta'];
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

  Widget _rueda(String genero) {
    final ruleta = ref.watch(ruletaProvider);
    final resultado = ruleta.resultado;
    final mostrarResultado = resultado != null && !_girando;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // RepaintBoundary: la rueda es una imagen estática que solo
                // rota; no se repinta nada más durante el giro (gama baja).
                RepaintBoundary(
                  child: AnimatedRotation(
                    turns: _turnsAcumulados,
                    duration: const Duration(seconds: 3),
                    curve: Curves.easeOutQuart,
                    onEnd: () {
                      // AH6: la ruleta frenó → fanfarria + háptico medio.
                      ref.read(sonidoServicioProvider).reproducirFanfarria();
                      ref.read(hapticosServicioProvider).ruletaFrenar();
                      if (mounted) setState(() => _girando = false);
                    },
                    child: Image.asset(
                      'assets/images/ruleta_rueda.webp',
                      width: 240,
                      height: 240,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // Needle: triángulo fijo arriba, NO rota con la rueda (D10).
                Positioned(
                  top: 0,
                  child: CustomPaint(
                    size: const Size(24, 40),
                    painter: _NeedlePainter(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (mostrarResultado) ...[
            Text(
              resultado,
              key: const Key('resultado_ruleta'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    height: 1.3,
                  ),
            ),
            if (esPasaTurno(resultado)) ...[
              const SizedBox(height: 12),
              Text(
                'Turno salvado, pasás el turno y gira el siguiente',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: .9),
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                // AH6: click en [Siguiente].
                ref.read(sonidoServicioProvider).reproducirClick();
                ref.read(ruletaProvider.notifier).siguiente();
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
              ),
              child: const Text('Siguiente', style: TextStyle(fontSize: 18)),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _girando ? null : _girar,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            ),
            child: const Text('Girar', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}

/// Aguja de la ruleta: triángulo blanco simple (~20 líneas, D10). No usa
/// asset: el arte vendored ya viene SIN flecha (RuletaSinFlecha.png).
class _NeedlePainter extends CustomPainter {
  const _NeedlePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width / 2 - 10, size.height)
      ..lineTo(size.width / 2 + 10, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}