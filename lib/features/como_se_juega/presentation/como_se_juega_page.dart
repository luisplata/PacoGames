import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Cómo se juega: los 3 pasos del pack.
class ComoSeJuegaPage extends StatelessWidget {
  const ComoSeJuegaPage({super.key});

  static const _pasos = [
    ('1. Elegí un juego', 'Yo Nunca, Ruleta o Pictionary: el que el grupo quiera.'),
    ('2. Pasá el teléfono', 'Cada jugador toma el teléfono y le toca a él.'),
    ('3. Que empiece la previa', 'Leé la carta en voz alta y que arranque.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cómo se juega'),
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (titulo, detalle) in _pasos)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(titulo, style: Theme.of(context).textTheme.titleMedium),
                subtitle: Text(detalle),
              ),
            ),
        ],
      ),
    );
  }
}