import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paco_game/app/orientacion.dart';

void main() {
  group('lockPortrait', () {
    testWidgets('envía SystemChrome.setPreferredOrientations con [portraitUp] '
        'al canal de plataforma (OR2)', (tester) async {
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          calls.add(call);
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      await lockPortrait();

      expect(calls, hasLength(1));
      expect(calls.single.method, 'SystemChrome.setPreferredOrientations');
      expect(calls.single.arguments, ['DeviceOrientation.portraitUp']);
    });
  });

  group('manifest', () {
    test('MainActivity declara android:screenOrientation="portrait" (OR1)',
        () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

      expect(manifest, contains('android:screenOrientation="portrait"'));
    });
  });
}