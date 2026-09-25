import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paco_game/app/app.dart';

void main() {
  testWidgets('app boots and shows the home screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    expect(find.text('PacoGame'), findsOneWidget);
  });
}