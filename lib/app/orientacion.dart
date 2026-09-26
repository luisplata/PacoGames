import 'package:flutter/services.dart';

/// Fija la app en portrait (OR2).
///
/// Web: no-op seguro — el canal de plataforma no existe o el engine ignora
/// la orientación; el try/catch absorbe cualquier error (documentado, D9:
/// el portrait PRIMARIO es el manifest en Android 16/API 36).
Future<void> lockPortrait() async {
  try {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
  } catch (_) {
    // Web/entorno sin canal: no-op.
  }
}