import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:paco_game/app/app.dart';
import 'package:paco_game/app/boot.dart';
import 'package:paco_game/core/ajustes/ajustes_providers.dart';
import 'package:paco_game/core/ajustes/ajustes_repository.dart';
import 'package:paco_game/core/contenido/diagnostico.dart';
import 'package:paco_game/core/contenido/entidades.dart';

void main() {
  testWidgets('app boots and shows the home screen (splashVisto=true)', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final bridge = BootBridge()..actualizar(splashVisto: true, errores: const []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bootBridgeProvider.overrideWithValue(bridge),
          ajustesRepositoryProvider.overrideWithValue(
            AjustesRepository(prefs: SharedPreferencesAsync()),
          ),
          diagnosticoContenidoProvider.overrideWith(
            (ref) async => const DiagnosticoContenido(contenidos: {}, errores: []),
          ),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PacoGame'), findsOneWidget);
    expect(find.text('Jugar'), findsOneWidget);
  });

  testWidgets('app boots to splash on first run (splashVisto=false)', (tester) async {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    final bridge = BootBridge()..actualizar(splashVisto: false, errores: const []);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bootBridgeProvider.overrideWithValue(bridge),
          ajustesRepositoryProvider.overrideWithValue(
            AjustesRepository(prefs: SharedPreferencesAsync()),
          ),
          diagnosticoContenidoProvider.overrideWith(
            (ref) async => const DiagnosticoContenido(contenidos: {}, errores: []),
          ),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PacoGame'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Entendido'), findsOneWidget);
  });
}