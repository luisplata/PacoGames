import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/ajustes/presentation/ajustes_page.dart';
import '../features/como_se_juega/presentation/como_se_juega_page.dart';
import '../features/diagnostico/presentation/diagnostico_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/ruleta/presentation/ruleta_instrucciones_page.dart';
import '../features/ruleta/presentation/ruleta_juego_page.dart';
import '../features/selector/presentation/selector_page.dart';
import '../features/splash/presentation/splash_page.dart';
import '../features/yo_nunca/presentation/yo_nunca_instrucciones_page.dart';
import '../features/yo_nunca/presentation/yo_nunca_juego_page.dart';
import 'boot.dart';

/// Router M0 + M1 + M2: 10 rutas flat + redirect top-level async-safe (R1-R2).
///
/// El redirect lee el [BootBridge] (refreshListenable): cada notify
/// re-evalúa la ruta actual. Mientras las prefs cargan (`splashVisto == null`)
/// se asume `!splashVisto` → /splash, nunca /home prematuro.
/// Las rutas de los juegos (`/yo-nunca*`, `/ruleta*`) quedan protegidas por
/// el redirect (sin splash visto → /splash).
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: ref.watch(bootBridgeProvider),
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final bridge = ref.read(bootBridgeProvider);

      // Diagnóstico siempre es accesible (R12).
      if (loc == '/diagnostico') return null;

      if (loc == '/' || loc == '/splash') {
        if (bridge.splashVisto != true) return '/splash';
        return bridge.errores.isNotEmpty ? '/diagnostico' : '/home';
      }

      // Cualquier otra ruta: sin splash visto (cargando o primera vez) → splash.
      if (bridge.splashVisto != true) return '/splash';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(path: '/selector', builder: (context, state) => const SelectorPage()),
      GoRoute(path: '/ajustes', builder: (context, state) => const AjustesPage()),
      GoRoute(
        path: '/como-se-juega',
        builder: (context, state) => const ComoSeJuegaPage(),
      ),
      GoRoute(path: '/diagnostico', builder: (context, state) => const DiagnosticoPage()),
      GoRoute(
        path: '/yo-nunca',
        builder: (context, state) => const YoNuncaInstruccionesPage(),
      ),
      GoRoute(
        path: '/yo-nunca/juego',
        builder: (context, state) => const YoNuncaJuegoPage(),
      ),
      GoRoute(
        path: '/ruleta',
        builder: (context, state) => const RuletaInstruccionesPage(),
      ),
      GoRoute(
        path: '/ruleta/juego',
        builder: (context, state) => const RuletaJuegoPage(),
      ),
    ],
  );
});