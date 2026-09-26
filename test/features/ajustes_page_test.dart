import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:paco_game/core/ajustes/ajustes_repository.dart';

import 'helpers.dart';

void main() {
  group('AjustesPage', () {
    testWidgets('muestra switches, versión y links', (tester) async {
      await arrancarApp(tester, splashVisto: true);
      await navegarDesdeHome(tester, 'Ajustes');

      expect(find.text('Sonido'), findsOneWidget);
      expect(find.text('Vibración'), findsOneWidget);
      expect(find.text('Modo alcohol'), findsOneWidget);
      expect(find.textContaining('v0.1.0'), findsOneWidget);
      expect(find.text('Diagnóstico'), findsOneWidget);
      expect(find.text('Cómo se juega'), findsOneWidget);
    });

    testWidgets('cambiar un switch persiste en el repo', (tester) async {
      await arrancarApp(tester, splashVisto: true);
      await navegarDesdeHome(tester, 'Ajustes');

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
      expect(ajustes.modoAlcohol, isFalse);
    });

    testWidgets('link a Diagnóstico navega', (tester) async {
      await arrancarApp(tester, splashVisto: true);
      await navegarDesdeHome(tester, 'Ajustes');

      await tester.tap(find.text('Diagnóstico'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Todo en orden'), findsOneWidget);
    });
  });
}