import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../application/carta_yo_nunca.dart';

/// Estados internos del flip (D6): el widget es dueño de `oculta/revelando/
/// revelada`; la página solo espeja si terminó (`onRevelada`).
enum _EstadoCarta { oculta, revelando, revelada }

/// Carta de Yo Nunca boca abajo con flip de 400 ms (YN6, design §5).
///
/// - Dorso azul (Normal) / rojo (Picante) según `carta.nivel`.
/// - Juramento opcional sobre el tercio inferior del dorso.
/// - Tap → flip con `Matrix4.rotateY` (sin paquetes), swap a 90°.
/// - Reduce-motion (`MediaQuery.disableAnimationsOf`) → reveal instantáneo.
/// - Doble tap durante la animación = no-op.
class CartaYoNuncaFlip extends StatefulWidget {
  const CartaYoNuncaFlip({
    super.key,
    required this.carta,
    required this.mostrarJuramento,
    required this.onRevelada,
    this.onRevelarIniciado,
  });

  final CartaYoNunca carta;

  /// Solo la primera carta de la partida muestra el juramento (YN6).
  final bool mostrarJuramento;

  /// Al TERMINAR el flip: habilita `[Siguiente]` en la página.
  final VoidCallback onRevelada;

  /// Al arrancar el flip: la página reproduce el SFX `carta` (AH6).
  final VoidCallback? onRevelarIniciado;

  @override
  State<CartaYoNuncaFlip> createState() => _CartaYoNuncaFlipState();
}

class _CartaYoNuncaFlipState extends State<CartaYoNuncaFlip>
    with SingleTickerProviderStateMixin {
  static const _duracion = Duration(milliseconds: 400);

  late final AnimationController _controller;
  _EstadoCarta _estado = _EstadoCarta.oculta;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duracion)
      ..addStatusListener(_alCambiarEstadoAnimacion);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduce-motion se resuelve ANTES del tap, sin reiniciar una animación
    // en curso (solo se cambia la duración del controller).
    _controller.duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _duracion;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _alCambiarEstadoAnimacion(AnimationStatus status) {
    if (status != AnimationStatus.completed ||
        _estado != _EstadoCarta.revelando) {
      return;
    }
    setState(() => _estado = _EstadoCarta.revelada);
    widget.onRevelada();
  }

  void _alTocar() {
    // Input bloqueado durante revelando/revelada: un segundo tap es no-op.
    if (_estado != _EstadoCarta.oculta) return;

    widget.onRevelarIniciado?.call();

    if (_controller.duration == Duration.zero) {
      // Reduce-motion: reveal instantáneo (un solo pump alcanza).
      setState(() => _estado = _EstadoCarta.revelada);
      _controller.value = 1;
      widget.onRevelada();
      return;
    }

    setState(() => _estado = _EstadoCarta.revelando);
    _controller.forward(from: 0);
  }

  NivelYoNunca get _nivel => widget.carta.nivel;

  String get _nombreNivel =>
      _nivel == NivelYoNunca.picante ? 'Picante' : 'Normal';

  Color get _colorNivel => _nivel == NivelYoNunca.picante
      ? const Color(0xFFB3261E)
      : const Color(0xFF1B5FA8);

  @override
  Widget build(BuildContext context) {
    final oculta = _estado == _EstadoCarta.oculta;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AspectRatio(
                aspectRatio: 949 / 1255,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Semantics(
                      button: oculta,
                      label: oculta
                          ? 'Carta boca abajo. Tipo: $_nombreNivel. '
                                'Tocá para revelar'
                          : 'Pregunta revelada',
                      child: GestureDetector(
                        key: const Key('carta_yo_nunca'),
                        behavior: HitTestBehavior.opaque,
                        onTap: _alTocar,
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) {
                            final v = Curves.easeInOut.transform(
                              _controller.value,
                            );
                            final mostrarFrente = v >= .5;
                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.0012)
                                ..rotateY(v * math.pi),
                              child: mostrarFrente
                                  ? Transform(
                                      alignment: Alignment.center,
                                      // Anti-espejo: el frente se lee normal
                                      // al completar la vuelta.
                                      transform: Matrix4.identity()
                                        ..rotateY(math.pi),
                                      child: _frente(),
                                    )
                                  : _dorso(),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 28,
          child: oculta
              ? const Center(
                  child: Text(
                    'Tocá para revelar',
                    key: Key('hint_revelar'),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
        ),
      ],
    );
  }

  Widget _dorso() {
    return Stack(
      key: const Key('dorso_yo_nunca'),
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/yo_nunca_dorso_${_nivel.name}.webp',
          key: Key('dorso_${_nivel.name}'),
          fit: BoxFit.fill,
        ),
        if (widget.mostrarJuramento)
          Positioned(
            left: 24,
            right: 24,
            bottom: 28,
            child: Container(
              key: const Key('juramento_yo_nunca'),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .62),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Juro solemnemente que mis intenciones no son buenas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.25,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _frente() {
    return Stack(
      key: const Key('frente_yo_nunca'),
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/carta_${_nivel.name}.webp',
          key: Key('frente_${_nivel.name}'),
          fit: BoxFit.fill,
        ),
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final tituloSize = (w * .085).clamp(16.0, 30.0);
              final fraseSize = (w * .072).clamp(14.0, 26.0);

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: w * .12,
                  vertical: h * .10,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Yo nunca nunca...',
                        key: const Key('titulo_yo_nunca'),
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'Grobold',
                          fontSize: tituloSize,
                          color: _colorNivel,
                        ),
                      ),
                    ),
                    SizedBox(height: h * .03),
                    Container(
                      height: 2,
                      width: w * .35,
                      color: _colorNivel.withValues(alpha: .35),
                    ),
                    SizedBox(height: h * .04),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: w * .76,
                          child: Text(
                            widget.carta.texto,
                            key: const Key('frase_yo_nunca'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w700,
                              fontSize: fraseSize,
                              height: 1.28,
                              color: const Color(0xFF2A2A2A),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
