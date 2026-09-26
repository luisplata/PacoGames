import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ajustes/ajustes_providers.dart';

/// Ajustes: switches sonido/vibración/modoAlcohol, versión y links
/// discretos a Diagnóstico y Cómo se juega.
class AjustesPage extends ConsumerWidget {
  const AjustesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ajustes = ref.watch(ajustesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
        ),
      ),
      body: switch (ajustes) {
        AsyncData(:final value) => ListView(
            children: [
              SwitchListTile(
                title: const Text('Sonido'),
                value: value.sonido,
                onChanged: (v) => ref.read(ajustesProvider.notifier).cambiarSonido(v),
              ),
              SwitchListTile(
                title: const Text('Vibración'),
                value: value.vibracion,
                onChanged: (v) => ref.read(ajustesProvider.notifier).cambiarVibracion(v),
              ),
              SwitchListTile(
                title: const Text('Modo alcohol'),
                subtitle: const Text('Oculta contenido picante'),
                value: value.modoAlcohol,
                onChanged: (v) => ref.read(ajustesProvider.notifier).cambiarModoAlcohol(v),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.build_outlined),
                title: const Text('Diagnóstico'),
                onTap: () => context.go('/diagnostico'),
              ),
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('Cómo se juega'),
                onTap: () => context.go('/como-se-juega'),
              ),
              const Divider(),
              ListTile(
                title: Text(
                  'v0.1.0',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}