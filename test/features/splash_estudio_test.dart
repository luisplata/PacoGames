import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paco_game/features/splash/presentation/splash_estudio.dart';

void main() {
  const appFake = Directionality(
    textDirection: TextDirection.ltr,
    child: Text('app'),
  );

  group('SplashEstudio', () {
    testWidgets('muestra el logo y recién después monta la app', (
      tester,
    ) async {
      await tester.pumpWidget(const SplashEstudio(child: appFake));

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('app'), findsNothing);

      await tester.pumpAndSettle();

      expect(find.text('app'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('la app no se monta antes de que termine la duración', (
      tester,
    ) async {
      await tester.pumpWidget(const SplashEstudio(child: appFake));

      // Primer tick del ticker: establece el tiempo de arranque.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 2800));

      expect(find.text('app'), findsNothing);

      await tester.pumpAndSettle();

      expect(find.text('app'), findsOneWidget);
    });
  });
}
