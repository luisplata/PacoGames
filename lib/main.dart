import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/orientacion.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // OR2: portrait por SystemChrome (secundario; el manifest es el PRIMARIO
  // en Android 16/API 36, D9).
  lockPortrait();
  runApp(const ProviderScope(child: App()));
}