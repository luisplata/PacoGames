import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features/helpers.dart';

void main() {
  testWidgets('app boots and shows the home screen (splashVisto=true)',
      (tester) async {
    await arrancarApp(tester, splashVisto: true);

    expect(find.text('PacoGames'), findsOneWidget);
    expect(find.text('Jugar'), findsOneWidget);
  });

  testWidgets('app boots to splash on first run (splashVisto=false)',
      (tester) async {
    await arrancarApp(tester, splashVisto: false);

    expect(find.text('PacoGames'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Entendido'), findsOneWidget);
  });
}