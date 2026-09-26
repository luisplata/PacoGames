import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Home: 3 botones (Jugar, Cómo se juega, Ajustes) + versión.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'PacoGame',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'la previa en un teléfono',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: () => context.go('/selector'),
                child: const Text('Jugar'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go('/como-se-juega'),
                child: const Text('Cómo se juega'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go('/ajustes'),
                child: const Text('Ajustes'),
              ),
              const Spacer(),
              Text(
                'v0.1.0',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}