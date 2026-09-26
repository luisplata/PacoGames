import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('ComoSeJuegaPage', () {
    testWidgets('muestra los 3 pasos del pack', (tester) async {
      await arrancarApp(tester, splashVisto: true);
      await navegarDesdeHome(tester, 'Cómo se juega');

      expect(find.textContaining('Elegí un juego'), findsOneWidget);
      expect(find.textContaining('Pasá el teléfono'), findsOneWidget);
      expect(find.textContaining('Que empiece la previa'), findsOneWidget);
    });
  });
}