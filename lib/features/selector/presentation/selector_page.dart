import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/contenido/diagnostico.dart';

/// Datos fijos de las 3 tarjetas del selector.
///
/// [ruta] no nula = juego jugable (navega con push); `null` = aún no
/// implementado (SnackBar 'Próximamente').
/// [imagen] no nulo = leading con arte propio (reemplaza al ícono).
class _JuegoInfo {
  const _JuegoInfo(
    this.id,
    this.nombre,
    this.icono,
    this.descripcion,
    this.ruta, {
    this.imagen,
  });

  final String id;
  final String nombre;
  final IconData icono;
  final String descripcion;
  final String? ruta;
  final String? imagen;
}

const _juegos = [
  _JuegoInfo(
    'yo_nunca',
    'Yo Nunca',
    Icons.help_outline,
    '¿Quién lo hizo?',
    '/yo-nunca',
    imagen: 'assets/images/yo_nunca_selector.png',
  ),
  _JuegoInfo(
    'ruleta',
    'Ruleta',
    Icons.casino_outlined,
    'Girás y te toca',
    '/ruleta',
  ),
  _JuegoInfo(
    'pictionary',
    'Pictionary',
    Icons.brush_outlined,
    'Dibujá y adiviná',
    '/pictionary',
    imagen: 'assets/images/pictionary_selector.png',
  ),
];

/// Selector de juegos: 3 tarjetas fijas. Sin cartas válidas → "sin contenido"
/// y no entra; con contenido → navega (Yo Nunca / Ruleta / Pictionary).
class SelectorPage extends ConsumerWidget {
  const SelectorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnostico = ref.watch(diagnosticoContenidoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Elegí un juego'),
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: switch (diagnostico) {
        AsyncData(:final value) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final juego in _juegos)
                _TarjetaJuego(
                  juego: juego,
                  tieneCartas: value.contenidos[juego.id]?.tieneCartas == true,
                ),
            ],
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _TarjetaJuego extends StatelessWidget {
  const _TarjetaJuego({required this.juego, required this.tieneCartas});

  final _JuegoInfo juego;
  final bool tieneCartas;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: juego.imagen != null
            ? Image.asset(juego.imagen!, width: 32, height: 32)
            : Icon(juego.icono, size: 32),
        title: Text(juego.nombre),
        subtitle: Text(tieneCartas ? juego.descripcion : 'sin contenido'),
        enabled: tieneCartas,
        onTap: tieneCartas
            ? () {
                final ruta = juego.ruta;
                if (ruta != null) {
                  // Yo Nunca y Ruleta son jugables: push preserva el
                  // back-stack (la salida mid-game necesita confirmación).
                  context.push(ruta);
                } else {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(content: Text('Próximamente (M3)')),
                    );
                }
              }
            : null,
      ),
    );
  }
}