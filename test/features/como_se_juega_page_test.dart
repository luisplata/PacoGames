import 'package:flutter_test/flutter_test.dart';

import 'package:paco_game/features/home/presentation/home_page.dart';

import 'helpers.dart';

void main() {
  group('ComoSeJuegaPage', () {
    testWidgets('muestra los 3 pasos del pack', (tester) async {
      await arrancarApp(tester, splashVisto: true);
      await navegarDesdeHome(tester, find.byKey(HomeKeys.ajustes));
      await tester.tap(find.text('Cómo se juega'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Elegí un juego'), findsOneWidget);
      expect(find.textContaining('Pasá el teléfono'), findsOneWidget);
      expect(find.textContaining('Que empiece la previa'), findsOneWidget);
    });
  });
}