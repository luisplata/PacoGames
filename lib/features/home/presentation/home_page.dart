import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/ajustes/ajustes_providers.dart';
import '../../../core/audio/sonido_provider.dart';

/// Claves estables del Home para tests y accesibilidad.
abstract final class HomeKeys {
  static const yoNunca = Key('home_yo_nunca');
  static const ruleta = Key('home_ruleta');
  static const pictionary = Key('home_pictionary');
  static const ajustes = Key('home_ajustes');
  static const sonido = Key('home_sonido');
  static const equipo = Key('home_equipo');
  static const googlePlay = Key('home_google_play');
  static const instagram = Key('home_instagram');
}

const _version = 'v0.1.0';
const _urlGooglePlay =
    'https://play.google.com/store/apps/details?id=com.bellseboss.v2.pacogame';
const _urlInstagram = 'https://www.instagram.com/bellseboss/';
const _urlEquipo = 'https://bellseboss-studio.github.io/#team';

/// Home rediseñado: wallpaper + capa negra translúcida + los 3 juegos.
///
/// Los botones grandes usan PNG (texto ya vectorizado) para no depender del
/// render de `<text>`/`<style>` de flutter_svg. Los íconos del footer sí son
/// SVG porque no tienen texto y se fuerzan a blanco con [ColorFilter].
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sonido = ref.watch(
      ajustesProvider.select((a) => a.value?.sonido ?? true),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/wallpaper_1.webp',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          // Capa negra al 60%: da contraste sin tapar la previa.
          const ColoredBox(color: Color(0x99000000)),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const padding = EdgeInsets.fromLTRB(24, 4, 24, 14);
                final altoMinimo = constraints.maxHeight > padding.vertical
                    ? constraints.maxHeight - padding.vertical
                    : 0.0;
                return SingleChildScrollView(
                  padding: padding,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 440,
                        minHeight: altoMinimo,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _Encabezado(
                            onAjustes: () => _abrirRuta(context, '/ajustes'),
                          ),
                          _Botones(onJuego: (ruta) => context.push(ruta)),
                          _Pie(
                            sonido: sonido,
                            onSonido: () => _alternarSonido(ref, sonido),
                            onGooglePlay: () =>
                                _abrirEnlace(context, _urlGooglePlay),
                            onInstagram: () =>
                                _abrirEnlace(context, _urlInstagram),
                            onEquipo: () => _mostrarEquipo(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _abrirRuta(BuildContext context, String ruta) {
    context.push(ruta);
  }

  Future<void> _alternarSonido(WidgetRef ref, bool sonidoActual) async {
    await ref.read(ajustesProvider.notifier).cambiarSonido(!sonidoActual);
    // Al reactivar, confirmamos con un click (al apagar no suena nada).
    if (!sonidoActual) {
      await ref.read(sonidoServicioProvider).reproducirClick();
    }
  }

  Future<void> _abrirEnlace(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      final abierto = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!abierto && context.mounted) {
        _avisarNoSePudoAbrir(context);
      }
    } catch (_) {
      if (context.mounted) _avisarNoSePudoAbrir(context);
    }
  }

  void _avisarNoSePudoAbrir(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('No se pudo abrir el enlace')));
  }

  void _mostrarEquipo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A2233),
        title: Row(
          children: [
            Image.asset('assets/images/bellseboss_studio.png', width: 48),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Bellseboss',
                style: TextStyle(
                  fontFamily: 'Grobold',
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Videogame Studio\n\n'
          'PACO — Previas Argentinas Co\n'
          '$_version',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _abrirEnlace(context, _urlEquipo);
            },
            child: const Text('Conocer el equipo'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.onAjustes});

  final VoidCallback onAjustes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            key: HomeKeys.ajustes,
            tooltip: 'Ajustes',
            onPressed: onAjustes,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.settings_outlined,
              color: Colors.white70,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const _Titulo(),
      ],
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo();

  static const _sombras = [
    Shadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4)),
  ];

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'PACO',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Grobold',
            fontSize: 62,
            height: 1,
            letterSpacing: 1.5,
            color: Colors.white,
            shadows: _sombras,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Previas Argentinas Co',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Grobold',
            fontSize: 19,
            height: 1.1,
            color: Colors.white,
            shadows: _sombras,
          ),
        ),
      ],
    );
  }
}

class _Botones extends StatelessWidget {
  const _Botones({required this.onJuego});

  final void Function(String ruta) onJuego;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BotonJuego(
          key: HomeKeys.yoNunca,
          etiqueta: 'Jugar Yo Nunca',
          imagen: 'assets/images/home_yo_nunca.png',
          imagenPresionada: 'assets/images/home_yo_nunca_press.png',
          onTap: () => onJuego('/yo-nunca'),
        ),
        const SizedBox(height: 4),
        _BotonJuego(
          key: HomeKeys.ruleta,
          etiqueta: 'Jugar Ruleta',
          imagen: 'assets/images/home_ruleta.png',
          imagenPresionada: 'assets/images/home_ruleta_press.png',
          onTap: () => onJuego('/ruleta'),
        ),
        const SizedBox(height: 4),
        _BotonJuego(
          key: HomeKeys.pictionary,
          etiqueta: 'Jugar Pictionary',
          imagen: 'assets/images/home_pictionary.png',
          imagenPresionada: 'assets/images/home_pictionary_press.png',
          onTap: () => onJuego('/pictionary'),
        ),
      ],
    );
  }
}

/// Botón-imagen con estado presionado (variante azul provista por el arte).
class _BotonJuego extends StatefulWidget {
  const _BotonJuego({
    super.key,
    required this.etiqueta,
    required this.imagen,
    required this.imagenPresionada,
    required this.onTap,
  });

  final String etiqueta;
  final String imagen;
  final String imagenPresionada;
  final VoidCallback onTap;

  @override
  State<_BotonJuego> createState() => _BotonJuegoState();
}

class _BotonJuegoState extends State<_BotonJuego> {
  bool _presionado = false;

  void _setPresionado(bool valor) {
    if (_presionado == valor) return;
    setState(() => _presionado = valor);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.etiqueta,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPresionado(true),
        onTapUp: (_) => _setPresionado(false),
        onTapCancel: () => _setPresionado(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _presionado ? 0.98 : 1,
          duration: const Duration(milliseconds: 90),
          child: AspectRatio(
            aspectRatio: 3.49,
            child: Image.asset(
              _presionado ? widget.imagenPresionada : widget.imagen,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _Pie extends StatelessWidget {
  const _Pie({
    required this.sonido,
    required this.onSonido,
    required this.onGooglePlay,
    required this.onInstagram,
    required this.onEquipo,
  });

  final bool sonido;
  final VoidCallback onSonido;
  final VoidCallback onGooglePlay;
  final VoidCallback onInstagram;
  final VoidCallback onEquipo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _IconoPie(
              key: HomeKeys.googlePlay,
              tooltip: 'Google Play',
              asset: 'assets/images/home_icon_google_play.svg',
              onTap: onGooglePlay,
            ),
            _IconoPie(
              key: HomeKeys.instagram,
              tooltip: 'Instagram',
              asset: 'assets/images/home_icon_instagram.svg',
              onTap: onInstagram,
            ),
            _IconoPie(
              key: HomeKeys.sonido,
              tooltip: sonido ? 'Silenciar' : 'Activar sonido',
              asset: sonido
                  ? 'assets/images/home_icon_sonido_on.svg'
                  : 'assets/images/home_icon_sonido_off.svg',
              onTap: onSonido,
            ),
            _IconoPie(
              key: HomeKeys.equipo,
              tooltip: 'Equipo',
              asset: 'assets/images/home_icon_equipo.svg',
              onTap: onEquipo,
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Bellseboss Videogame Studio · $_version',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Grobold',
            fontSize: 11,
            color: Colors.white70,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _IconoPie extends StatelessWidget {
  const _IconoPie({
    super.key,
    required this.tooltip,
    required this.asset,
    required this.onTap,
  });

  final String tooltip;
  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onTap,
      icon: SvgPicture.asset(
        asset,
        height: 22,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
      ),
    );
  }
}
