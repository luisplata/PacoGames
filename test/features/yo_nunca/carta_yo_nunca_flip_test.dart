import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paco_game/features/yo_nunca/application/carta_yo_nunca.dart';
import 'package:paco_game/features/yo_nunca/presentation/widgets/carta_yo_nunca_flip.dart';

const _c1 = 'Juro solemnemente que mis intenciones no son buenas.';
const _c2 = 'Tocá para revelar';
const _c3 = 'Yo nunca nunca...';
const _cartaKey = Key('carta_yo_nunca');
const _dorsoKey = Key('dorso_yo_nunca');
const _frenteKey = Key('frente_yo_nunca');

/// Texto real del JSON (86 chars, espacio inicial incluido): el caso más largo
/// que tiene que entrar sin overflow en el frente.
const _textoLargo =
    ' usé preservativos luminosos. (Un mundo de experiencias que las lesbianas no conocen.)';

Widget _app({
  required CartaYoNunca carta,
  bool mostrarJuramento = false,
  bool reduceMotion = false,
  VoidCallback? onRevelada,
  VoidCallback? onRevelarIniciado,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(800, 600),
        disableAnimations: reduceMotion,
      ),
      child: Scaffold(
        body: CartaYoNuncaFlip(
          carta: carta,
          mostrarJuramento: mostrarJuramento,
          onRevelada: onRevelada ?? () {},
          onRevelarIniciado: onRevelarIniciado,
        ),
      ),
    ),
  );
}

const _normal = CartaYoNunca(
  texto: 'Me quedé dormido en el sillón',
  nivel: NivelYoNunca.normal,
);
const _picante = CartaYoNunca(
  texto: 'Le mandé un mensaje a mi ex',
  nivel: NivelYoNunca.picante,
);

void main() {
  group('CartaYoNuncaFlip — dorso por nivel', () {
    testWidgets('carta Normal → dorso_normal + C2, sin frente', (tester) async {
      await tester.pumpWidget(_app(carta: _normal));

      expect(find.byKey(_dorsoKey), findsOneWidget);
      expect(find.byKey(const Key('dorso_normal')), findsOneWidget);
      expect(find.byKey(const Key('dorso_picante')), findsNothing);
      expect(find.byKey(_frenteKey), findsNothing);
      expect(find.text(_c2), findsOneWidget);
    });

    testWidgets('carta Picante → dorso_picante', (tester) async {
      await tester.pumpWidget(_app(carta: _picante));

      expect(find.byKey(const Key('dorso_picante')), findsOneWidget);
      expect(find.byKey(const Key('dorso_normal')), findsNothing);
    });
  });

  group('CartaYoNuncaFlip — juramento', () {
    testWidgets('con mostrarJuramento → panel C1 exacto sobre el dorso', (
      tester,
    ) async {
      await tester.pumpWidget(_app(carta: _normal, mostrarJuramento: true));

      expect(find.byKey(const Key('juramento_yo_nunca')), findsOneWidget);
      expect(find.text(_c1), findsOneWidget);
    });

    testWidgets('sin mostrarJuramento → no hay C1', (tester) async {
      await tester.pumpWidget(_app(carta: _normal));

      expect(find.byKey(const Key('juramento_yo_nunca')), findsNothing);
      expect(find.text(_c1), findsNothing);
    });
  });

  group('CartaYoNuncaFlip — flip', () {
    testWidgets('tap → inicia el flip (C2/SFX) y a los 200 ms sigue en '
        'transición', (tester) async {
      var reveladas = 0;
      var iniciadas = 0;
      await tester.pumpWidget(
        _app(
          carta: _normal,
          onRevelada: () => reveladas++,
          onRevelarIniciado: () => iniciadas++,
        ),
      );

      await tester.tap(find.byKey(_cartaKey));
      await tester.pump();
      expect(iniciadas, 1, reason: 'SFX carta al arrancar el flip');

      await tester.pump(const Duration(milliseconds: 200));
      expect(reveladas, 0, reason: 'todavía no terminó el flip');
      expect(find.widgetWithText(FilledButton, 'Siguiente'), findsNothing);

      await tester.pumpAndSettle();
      expect(reveladas, 1);
      expect(find.byKey(_frenteKey), findsOneWidget);
      expect(find.byKey(_dorsoKey), findsNothing);
      expect(find.text(_c3), findsOneWidget);
      expect(find.text(_normal.texto), findsOneWidget);
      expect(find.text(_c2), findsNothing);
    });

    testWidgets('doble tap durante el flip → onRevelada una sola vez', (
      tester,
    ) async {
      var reveladas = 0;
      await tester.pumpWidget(
        _app(carta: _normal, onRevelada: () => reveladas++),
      );

      await tester.tap(find.byKey(_cartaKey));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(_cartaKey));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(_cartaKey));
      await tester.pumpAndSettle();

      expect(reveladas, 1);
      expect(find.byKey(_frenteKey), findsOneWidget);
    });

    testWidgets('reduce motion → revela instantáneo con un solo pump', (
      tester,
    ) async {
      var reveladas = 0;
      await tester.pumpWidget(
        _app(carta: _normal, reduceMotion: true, onRevelada: () => reveladas++),
      );

      await tester.tap(find.byKey(_cartaKey));
      await tester.pump();

      expect(reveladas, 1);
      expect(find.byKey(_frenteKey), findsOneWidget);
      expect(find.byKey(_dorsoKey), findsNothing);
      expect(find.text(_c3), findsOneWidget);
    });

    testWidgets('texto real de 86 chars → sin overflow', (tester) async {
      await tester.pumpWidget(
        _app(
          carta: const CartaYoNunca(
            texto: _textoLargo,
            nivel: NivelYoNunca.normal,
          ),
        ),
      );

      await tester.tap(find.byKey(_cartaKey));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(_textoLargo), findsOneWidget);
    });
  });

  group('CartaYoNuncaFlip — semántica', () {
    testWidgets('anuncia el tipo boca abajo y el estado revelado', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(_app(carta: _picante));

      expect(
        find.semantics.byLabel(
          'Carta boca abajo. Tipo: Picante. Tocá para revelar',
        ),
        findsOne,
      );

      await tester.tap(find.byKey(_cartaKey));
      await tester.pumpAndSettle();

      expect(find.semantics.byLabel(RegExp('Pregunta revelada')), findsOne);
      handle.dispose();
    });
  });
}
