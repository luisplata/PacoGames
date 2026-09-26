import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/contenido/diagnostico.dart';

/// Datos fijos de las 3 tarjetas del selector (M0).
class _JuegoInfo {
  const _JuegoInfo(this.id, this.nombre, this.icono, this.descripcion);

  final String id;
  final String nombre;
  final IconData icono;
  final String descripcion;
}

const _juegos = [
  _JuegoInfo('yo_nunca', 'Yo Nunca', Icons.help_outline, '¿Quién lo hizo?'),
  _JuegoInfo('ruleta', 'Ruleta', Icons.casino_outlined, 'Girás y te toca'),
  _JuegoInfo('pictionary', 'Pictionary', Icons.brush_outlined, 'Dibujá y adiviná'),
];

/// Selector de juegos: 3 tarjetas fijas. Sin cartas válidas → "sin contenido"
/// y no entra; con contenido → SnackBar 'Próximamente' en M0.
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
        leading: Icon(juego.icono, size: 32),
        title: Text(juego.nombre),
        subtitle: Text(tieneCartas ? juego.descripcion : 'sin contenido'),
        enabled: tieneCartas,
        onTap: tieneCartas
            ? () {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('Próximamente (M1-M3)')),
                  );
              }
            : null,
      ),
    );
  }
}