import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paco_game/core/ajustes/ajustes_repository.dart';
import 'package:paco_game/features/home/presentation/home_page.dart';

import 'helpers.dart';

const _c10 = 'Modo sin alcohol';
const _c11 =
    'Oculta el contenido picante y cambia los tragos por prendas.';
const _switchKey = Key('switch_modo_sin_alcohol');

void main() {
  group('AjustesPage', () {
    testWidgets('muestra copy exacta del modo sin alcohol, versión y links',
        (tester) async {
      await arrancarApp(tester, splashVisto: true);
      await navegarDesdeHome(tester, find.byKey(HomeKeys.ajustes));

      expect(find.text('Sonido'), findsOneWidget);
      expect(find.text('Vibración'), findsOneWidget);
      expect(find.text(_c10), findsOneWidget);
      expect(find.text(_c11), findsOneWidget);
      expect(find.text('Modo alcohol'), findsNothing);
      expect(find.textContaining('v0.1.0'), findsOneWidget);
      expect(find.text('Diagnóstico'), findsOneWidget);
      expect(find.text('Cómo se juega'), findsOneWidget);
    });

    testWidgets('sin presembrar → el switch de modo sin alcohol arranca ON',
        (tester) async {
      // arrancarApp no siembra `ajustes.modoAlcohol`: manda el default (A3).
      await arrancarApp(tester, splashVisto: true);
      await navegarDesdeHome(tester, find.byKey(HomeKeys.ajustes));

      final switchFinder = find.byKey(_switchKey);
      expect(switchFinder, findsOneWidget);
      expect(
        tester.widget<SwitchListTile>(switchFinder).value,
        isTrue,
        reason: 'modo sin alcohol ON por defecto',
      );
    });

    testWidgets('toggle del modo sin alcohol persiste en el repo',
        (tester) async {
      await arrancarApp(tester, splashVisto: true);
      await navegarDesdeHome(tester, find.byKey(HomeKeys.ajustes));

      final switchFinder = find.byKey(_switchKey);
      expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);

      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(tester.widget<SwitchListTile>(switchFinder).value, isFalse);

      // El repo persistió el false; el marker sigue escrito (elección
      // autoritativa, la migración no la vuelve a pisar).
      final repo = AjustesRepository(prefs: SharedPreferencesAsync());
      final ajustes = await repo.cargarAjustes();
      expect(ajustes.modoAlcohol, isFalse);
      expect(
        await SharedPreferencesAsync()
            .getBool('ajustes.migracionModoSinAlcohol'),
        isTrue,
      );
    });

    testWidgets('cambiar sonido persiste y no toca el modo sin alcohol',
        (tester) async {
      await arrancarApp(tester, splashVisto: true);
      await navegarDesdeHome(tester, find.byKey(HomeKeys.ajustes));

      final sonidoSwitch = find.byType(Switch).first;
      expect(tester.widget<Switch>(sonidoSwitch).value, isTrue,
          reason: 'default sonido=true');

      await tester.tap(sonidoSwitch);
      await tester.pumpAndSettle();

      expect(tester.widget<Switch>(sonidoSwitch).value, isFalse,
          reason: 'el switch cambió de estado');

      // El repo persistió: un nuevo repo sobre las mismas prefs lo lee.
      final repo = AjustesRepository(prefs: SharedPreferencesAsync());
      final ajustes = await repo.cargarAjustes();
      expect(ajustes.sonido, isFalse);
      expect(ajustes.vibracion, isTrue);
      expect(ajustes.modoAlcohol, isTrue,
          reason: 'el default sobrio sigue vigente');
    });

    testWidgets('link a Diagnóstico navega', (tester) async {
      await arrancarApp(tester, splashVisto: true);
      await navegarDesdeHome(tester, find.byKey(HomeKeys.ajustes));

      await tester.tap(find.text('Diagnóstico'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Todo en orden'), findsOneWidget);
    });
  });
}
