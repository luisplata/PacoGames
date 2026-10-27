import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/orientacion.dart';
import 'features/splash/presentation/splash_estudio.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // OR2: portrait por SystemChrome (secundario; el manifest es el PRIMARIO
  // en Android 16/API 36, D9).
  lockPortrait();
  // Gate de arranque: logo del estudio ~3 s y luego la app real.
  runApp(const ProviderScope(child: SplashEstudio(child: App())));
}
