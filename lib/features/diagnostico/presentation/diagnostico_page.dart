import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/contenido/diagnostico.dart';
import '../../../core/contenido/entidades.dart';

/// Diagnóstico de contenido: lista errores (archivo + línea) o un mensaje
/// sano con contador de cartas por juego. No molesta si todo está bien.
class DiagnosticoPage extends ConsumerWidget {
  const DiagnosticoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagnostico = ref.watch(diagnosticoContenidoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico'),
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: switch (diagnostico) {
        AsyncData(:final value) => value.hayErrores
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final e in value.errores)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const Icon(Icons.error_outline, color: Colors.red),
                        title: Text('${e.archivo}:${e.linea}'),
                        subtitle: Text(e.mensaje),
                      ),
                    ),
                ],
              )
            : _TodoEnOrden(diagnostico: value),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _TodoEnOrden extends StatelessWidget {
  const _TodoEnOrden({required this.diagnostico});

  final DiagnosticoContenido diagnostico;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ListTile(
          leading: Icon(Icons.check_circle_outline, color: Colors.green),
          title: Text('Todo en orden'),
        ),
        const Divider(),
        for (final juego in diagnostico.contenidos.values)
          ListTile(
            title: Text(juego.juegoId),
            trailing: Text(
              '${juego.generos.fold<int>(0, (acc, g) => acc + g.cartas.length)} cartas',
            ),
          ),
      ],
    );
  }
}