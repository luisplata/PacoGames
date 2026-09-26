import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/boot.dart';
import '../../../core/ajustes/ajustes_providers.dart';

/// Splash de primera vez: aviso +18/responsable y botón [Entendido].
///
/// Solo se muestra cuando `splashVisto != true` (el redirect ya lo garantiza).
class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bridge = ref.watch(bootBridgeProvider);

    // Escuchamos el bridge como Listenable: cuando el boot async completa
    // (bridge.actualizar → notifyListeners), este widget se reconstruye.
    // Sin esto, ref.watch de un Provider que devuelve un ChangeNotifier NO
    // re-renderiza (bug: spinner eterno tras boot real).
    return ListenableBuilder(
      listenable: bridge,
      builder: (context, _) {
        // R2: mientras las prefs cargan (splashVisto == null) no mostramos
        // contenido decidido: spinner.
        if (bridge.splashVisto == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

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
                  const SizedBox(height: 32),
                  Text(
                    'Solo para mayores de 18 años. Jugá con responsabilidad: '
                    'el alcohol no es obligatorio, no manejes si tomaste y '
                    'respetá a quienes no quieran jugar.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () async {
                      // Persistimos el flag y avisamos al bridge: el redirect
                      // re-evalúa y navega a /home (o /diagnostico si hay errores).
                      await ref
                          .read(ajustesRepositoryProvider)
                          .marcarSplashVisto();
                      bridge.marcarSplashVisto(true);
                    },
                    child: const Text('Entendido'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}