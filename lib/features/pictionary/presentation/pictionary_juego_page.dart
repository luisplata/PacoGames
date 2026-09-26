import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ajustes/ajustes.dart';
import '../../../core/ajustes/ajustes_providers.dart';
import '../../../core/audio/sonido_provider.dart';
import '../../../core/contenido/diagnostico.dart';
import '../../../core/contenido/entidades.dart';
import '../../../core/contenido/generos_visibles.dart';
import '../application/pictionary_providers.dart';
import '../application/sesion_pictionary.dart';

/// Fases internas del juego (P4/D7): una sola página, SIN sub-rutas.
enum _Fase { pase, elegir, ronda, resultado }

/// Juego de Pictionary (P4-P7, P9): pase secreto → el dibujante elige una
/// de 3 palabras → ronda con timer de 60 s (pausa manual + automática por
/// lifecycle) → resultado (adivinado A/B o "Nadie suma"). Marcador A/B
/// visible toda la ronda; salida mid-game con confirmación (estado efímero
/// autoDispose). SIN banner de modo sin alcohol (D9: 04 no mapea trago).
class PictionaryJuegoPage extends ConsumerStatefulWidget {
  const PictionaryJuegoPage({super.key});

  @override
  ConsumerState<PictionaryJuegoPage> createState() => _PictionaryJuegoPageState();
}

class _PictionaryJuegoPageState extends ConsumerState<PictionaryJuegoPage>
    with WidgetsBindingObserver {
  /// Auto-select post-frame (P9, patrón M1 dev-6): se dispara UNA vez y
  /// solo cuando diagnostico Y ajustes cargaron (con modoAlcohol en loading
  /// el set de visibles sería el equivocado).
  bool _autoSeleccionPendiente = true;

  /// Permite el pop real tras confirmar la salida (D6): con canPop false
  /// `context.pop()` quedaría bloqueado por el PopScope.
  bool _salirConfirmado = false;

  _Fase _fase = _Fase.pase;

  /// `true` en el resultado por [¡Adivinado!] ("¿Quién adivinó?"); `false`
  /// en el resultado por fin de tiempo ("Nadie suma").
  bool _adivinada = false;

  /// Palabra elegida por el dibujante en la ronda actual.
  String? _palabra;

  /// `true` cuando la pausa vino del botón manual: el lifecycle NO la
  /// deshace al volver (P5).
  bool _pausaManual = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Pausa automática por lifecycle (P5/D6): fuera de la app → el timer se
  /// pausa solo; al volver se reanuda (salvo pausa manual del usuario).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      if (_fase == _Fase.ronda) {
        ref.read(pictionaryCronometroProvider.notifier).pausar();
      }
    } else {
      if (_fase == _Fase.ronda && !_pausaManual) {
        ref.read(pictionaryCronometroProvider.notifier).reanudar();
      }
    }
  }

  Future<void> _mostrarDialogoSalida() async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Salir de la partida?'),
        content: const Text('Perdés el marcador de la partida'),
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
    final genero = ref.read(pictionaryGeneroProvider);
    if (genero == null || _salirConfirmado) {
      context.pop();
    } else {
      _mostrarDialogoSalida();
    }
  }

  void _elegirGenero(String nombre) {
    setState(() {});
    ref.read(sesionPictionaryProvider.notifier).seleccionarGenero(nombre);
    // Persistencia explícita del preferido (diseño M1, A1 genérico).
    ref.read(ajustesProvider.notifier).setGeneroPreferido('pictionary', nombre);
  }

  /// Pase → elegir: el sorteo ocurre AL ENTRAR a la fase elegir y las 3
  /// opciones se consumen al instante (el dibujante las vio, P1).
  void _continuar() {
    // AH6: click en [Continuar].
    ref.read(sonidoServicioProvider).reproducirClick();
    setState(() => _fase = _Fase.elegir);
    ref.read(sesionPictionaryProvider.notifier).sortearPalabras();
  }

  /// Elegir → ronda: palabra en grande + cronómetro en marcha (P4).
  void _elegirPalabra(String palabra) {
    setState(() {
      _fase = _Fase.ronda;
      _palabra = palabra;
    });
    ref.read(pictionaryCronometroProvider.notifier).iniciar();
  }

  /// [¡Adivinado!] → resultado "¿Quién adivinó?" (timer pausado).
  void _adivinar() {
    // AH6: acierto → fanfarria + háptico pesado.
    ref.read(sonidoServicioProvider).reproducirFanfarria();
    ref.read(hapticosServicioProvider).acierto();
    ref.read(pictionaryCronometroProvider.notifier).pausar();
    setState(() {
      _fase = _Fase.resultado;
      _adivinada = true;
    });
  }

  /// [Equipo A]/[Equipo B]: punto + siguiente dibujante + nueva ronda.
  void _asignarPunto(bool equipoA) {
    // AH6: click en [Equipo A]/[Equipo B].
    ref.read(sonidoServicioProvider).reproducirClick();
    final notifier = ref.read(sesionPictionaryProvider.notifier);
    if (equipoA) {
      notifier.puntoA();
    } else {
      notifier.puntoB();
    }
    notifier.siguienteDibujante();
    notifier.nuevaRonda();
    setState(() {
      _fase = _Fase.pase;
      _adivinada = false;
      _palabra = null;
      _pausaManual = false;
    });
  }

  /// [Siguiente dibujante] (fin de tiempo): turno pasa SIN punto (P5/P6).
  void _siguienteDibujante() {
    // AH6: click en [Siguiente dibujante].
    ref.read(sonidoServicioProvider).reproducirClick();
    final notifier = ref.read(sesionPictionaryProvider.notifier);
    notifier.siguienteDibujante();
    notifier.nuevaRonda();
    setState(() {
      _fase = _Fase.pase;
      _adivinada = false;
      _palabra = null;
      _pausaManual = false;
    });
  }

  /// [Pausa] ↔ [Reanudar] manual (P10): toggle `_pausaManual` para que el
  /// lifecycle no deshaga la pausa del usuario al volver (P5).
  void _togglePausa() {
    final notifier = ref.read(pictionaryCronometroProvider.notifier);
    if (_pausaManual) {
      _pausaManual = false;
      notifier.reanudar();
    } else {
      _pausaManual = true;
      notifier.pausar();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final genero = ref.watch(pictionaryGeneroProvider);
    final diagnostico = ref.watch(diagnosticoContenidoProvider);
    final ajustes = ref.watch(ajustesProvider);
    final modoAlcohol = ajustes.value?.modoAlcohol ?? false;

    final visibles = generosVisibles(
      diagnostico.value?.contenidos['pictionary']?.generos ?? const <Genero>[],
      modoAlcohol: modoAlcohol,
    );

    // Fin de tiempo (P5): al llegar a 0 el notifier auto-cancela el timer y
    // este listener mueve la UI al resultado "Nadie suma".
    ref.listen(pictionaryCronometroProvider, (prev, next) {
      // AH6: tick + háptico de timer en los últimos 10 s, solo en ronda y
      // solo cuando el segundo REALMENTE decrementó (pausa/reanudar no
      // cambian segundosRestantes → 0 falsos ticks; 0 no suena).
      if (next.segundosRestantes != prev?.segundosRestantes &&
          next.segundosRestantes <= 10 &&
          next.segundosRestantes > 0 &&
          _fase == _Fase.ronda) {
        ref.read(sonidoServicioProvider).reproducirTick();
        ref.read(hapticosServicioProvider).tickTimer();
      }
      if (next.terminado && _fase == _Fase.ronda) {
        setState(() {
          _fase = _Fase.resultado;
          _adivinada = false;
          _pausaManual = false;
        });
      }
    });

    // Auto-select (P9): exactamente 1 género visible → arranca directo, SIN
    // persistir preferido. Decisión post-frame (dev-6 M1).
    if (_autoSeleccionPendiente &&
        genero == null &&
        diagnostico.value != null &&
        ajustes.value != null) {
      _autoSeleccionPendiente = false;
      if (visibles.length == 1) {
        final unico = visibles.first.nombre;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && ref.read(pictionaryGeneroProvider) == null) {
            ref.read(sesionPictionaryProvider.notifier).seleccionarGenero(unico);
          }
        });
      }
    }

    final sesion = ref.watch(sesionPictionaryProvider);

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
                      ],
                    ),
                  ),
                  // Marcador A/B visible en TODAS las fases post-picker (P9).
                  if (genero != null)
                    Text(
                      'Equipo A: ${sesion.marcadorA} — Equipo B: ${sesion.marcadorB}',
                      key: const Key('marcador_pictionary'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontFamily: 'Grobold',
                            color: Colors.white,
                          ),
                    ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: switch (diagnostico) {
                      AsyncData() => genero == null
                          ? _picker(visibles, ajustes.value)
                          : _juego(sesion),
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

  Widget _picker(List<Genero> visibles, Ajustes? ajustes) {
    if (visibles.isEmpty) {
      // Edge defensivo P9: solo-Picante + modo sin alcohol.
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
    final preferido = ajustes?.generoPreferido['pictionary'];
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
                  selected: preseleccion == genero.nombre,
                  onSelected: (_) => _elegirGenero(genero.nombre),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _juego(SesionPictionary sesion) {
    return switch (_fase) {
      _Fase.pase => _pase(),
      _Fase.elegir => _elegir(sesion),
      _Fase.ronda => _ronda(),
      _Fase.resultado => _resultado(),
    };
  }

  Widget _pase() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Icon(
            Icons.phone_iphone,
            size: 64,
            color: Colors.white.withValues(alpha: .9),
          ),
          const SizedBox(height: 16),
          Text(
            'Pasá el teléfono al dibujante',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamily: 'Grobold',
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _continuar,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            ),
            child: const Text('Continuar', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Widget _elegir(SesionPictionary sesion) {
    final opciones = sesion.palabrasActuales;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Elegí una palabra',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamily: 'Grobold',
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < opciones.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _elegirPalabra(opciones[i]),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .45),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/pictionary_carta.webp',
                        height: 48,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          opciones[i],
                          key: Key('opcion_palabra_$i'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ronda() {
    final crono = ref.watch(pictionaryCronometroProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/pictionary_carta.webp',
                    fit: BoxFit.contain,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    _palabra ?? '',
                    key: const Key('palabra_pictionary'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          height: 1.3,
                          shadows: const [
                            Shadow(blurRadius: 8, color: Colors.black),
                          ],
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${crono.segundosRestantes}',
            key: const Key('timer_pictionary'),
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontFamily: 'Grobold',
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: _togglePausa,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
                child: Text(
                  crono.pausado ? 'Reanudar' : 'Pausa',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: _adivinar,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
                child: const Text('¡Adivinado!', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultado() {
    if (_adivinada) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              '¿Quién adivinó?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontFamily: 'Grobold',
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton(
                  onPressed: () => _asignarPunto(true),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                  child: const Text('Equipo A', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: () => _asignarPunto(false),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                  child: const Text('Equipo B', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(
            '¡Se acabó el tiempo! Nadie suma',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontFamily: 'Grobold',
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _siguienteDibujante,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
            ),
            child: const Text('Siguiente dibujante', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }
}