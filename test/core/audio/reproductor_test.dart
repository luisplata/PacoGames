import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paco_game/core/audio/reproductor.dart';

void main() {
  group('ReproductorSilencioso', () {
    test('no-op total: los 8 métodos completan sin efecto ni error', () async {
      final r = ReproductorSilencioso();

      await r.cargar();
      await r.reproducirClick();
      await r.reproducirTick();
      await r.reproducirFanfarria();
      await r.reproducirGiro();
      await r.reproducirCarta();
      await r.detener();
      await r.dispose();

      // Idempotente: repetir tras dispose tampoco lanza.
      await r.reproducirClick();
      await r.dispose();
    });
  });

  group('ReproductorAudioplayers', () {
    test('contextoAndroid configura usageType assistanceSonification y '
        'contentType sonification (AH1)', () {
      final ctx = ReproductorAudioplayers.contextoAndroid;

      expect(ctx.android.usageType, AndroidUsageType.assistanceSonification);
      expect(ctx.android.contentType, AndroidContentType.sonification);
    });

    testWidgets('tolera entorno sin plugin: reproducir/cargar/dispose no '
        'lanzan (try/catch doble AH3)', (tester) async {
      // Simula ausencia total de plugin: los canales de audioplayers fallan
      // como en un entorno sin implementación nativa (o web sin plugin).
      // Los mocks resuelven en el zone de test (sin round-trip al engine).
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      for (final canal in const [
        MethodChannel('xyz.luan/audioplayers'),
        MethodChannel('xyz.luan/audioplayers.global'),
      ]) {
        messenger.setMockMethodCallHandler(
          canal,
          (call) async => throw MissingPluginException(),
        );
      }
      messenger.setMockStreamHandler(
        const EventChannel('xyz.luan/audioplayers.global/events'),
        MockStreamHandler.inline(
          onListen: (arguments, events) {},
          onCancel: (arguments) {},
        ),
      );

      final r = ReproductorAudioplayers();
      await r.cargar();
      await r.reproducirClick();
      await r.reproducirTick();
      await r.reproducirFanfarria();
      await r.reproducirGiro();
      await r.reproducirCarta();
      await r.detener();
      await r.dispose();
    });
  });
}