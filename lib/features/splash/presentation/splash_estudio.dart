import 'package:flutter/material.dart';

/// Splash de estudio estilo Unity: muestra el logo de Bellseboss durante
/// [duracion] y recién ahí monta [child] (la app real).
///
/// Vive FUERA del router a propósito: es un gate de arranque, no una ruta.
/// Así los widget tests que montan `App` directo no esperan 3 s ni dependen
/// del asset.
class SplashEstudio extends StatefulWidget {
  const SplashEstudio({super.key, required this.child});

  /// Duración total del splash: fade in + hold + fade out.
  static const duracion = Duration(seconds: 3);

  /// App que se monta cuando termina el splash.
  final Widget child;

  @override
  State<SplashEstudio> createState() => _SplashEstudioState();
}

class _SplashEstudioState extends State<SplashEstudio>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controlador;
  late final Animation<double> _opacidad;
  late final Animation<double> _escala;

  bool _terminado = false;

  @override
  void initState() {
    super.initState();
    _controlador = AnimationController(
      vsync: this,
      duration: SplashEstudio.duracion,
    );

    // 20% fade in, 65% hold, 15% fade out (≈ 600 ms / 1950 ms / 450 ms).
    _opacidad = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 65),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
    ]).animate(_controlador);

    // Zoom sutil de entrada, congelado al terminar el fade in.
    _escala = Tween(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controlador,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
      ),
    );

    _controlador.addStatusListener((estado) {
      if (estado == AnimationStatus.completed && mounted) {
        setState(() => _terminado = true);
      }
    });
    _controlador.forward();
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_terminado) return widget.child;

    // El splash es la raíz (antes del MaterialApp): necesita Directionality
    // propia para las Semantics del logo.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Colors.black,
        child: Center(
          child: FadeTransition(
            opacity: _opacidad,
            child: ScaleTransition(
              scale: _escala,
              child: Semantics(
                label: 'Bellseboss Studio',
                image: true,
                child: Image.asset(
                  'assets/images/bellseboss_studio.png',
                  width: 320,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
