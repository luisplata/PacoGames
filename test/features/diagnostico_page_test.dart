import 'package:flutter_test/flutter_test.dart';

import 'package:paco_game/core/contenido/entidades.dart';

import 'helpers.dart';

void main() {
  group('DiagnosticoPage', () {
    testWidgets('auto-navega a /diagnostico cuando hay errores', (tester) async {
      final errores = [
        const ErrorContenido(archivo: 'ruleta.json', linea: 3, mensaje: 'error de sintaxis: X'),
        const ErrorContenido(archivo: 'pictionary.json', linea: 7, mensaje: 'carta vacía'),
      ];
      await arrancarApp(tester, splashVisto: true, errores: errores);

      expect(find.text('Diagnóstico'), findsOneWidget);
      expect(find.textContaining('ruleta.json:3'), findsOneWidget);
      expect(find.textContaining('pictionary.json:7'), findsOneWidget);
    });

    testWidgets('todo sano → "Todo en orden" + contador de cartas', (tester) async {
      await arrancarApp(tester, splashVisto: true);
      await navegarDesdeHome(tester, 'Ajustes');
      await tester.tap(find.text('Diagnóstico'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Todo en orden'), findsOneWidget);
    });
  });
}