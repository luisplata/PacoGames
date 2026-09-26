# PacoGames

Evolución de **PACO** (proyecto original en Unity) ahora reescrito en Flutter.
Base Flutter con estructura feature-first, Riverpod 3 para estado/DI y go_router
para navegación. Aún no hay features de juego — esta es la base ejecutable.

**Quick start:**

| Command (full SDK path — Flutter is NOT on PATH) | What it does |
|---|---|
| `C:\Users\luis_\flutter\bin\flutter pub get` | Install dependencies |
| `C:\Users\luis_\flutter\bin\flutter run -d chrome` | Run on web (Chrome) |
| `C:\Users\luis_\flutter\bin\flutter test` | Run the test suite |
| `C:\Users\luis_\flutter\bin\flutter analyze` | Static analysis (must be 0 issues) |

## Run on Web (para probar)

Flutter no está en el PATH, así que usá la ruta completa del SDK.
Desde la raíz del proyecto:

```bash
# Opción A: Chrome (recomendada — hot reload automático al guardar)
C:/Users/luis_/flutter/bin/flutter run -d chrome

# Opción B: servidor web + abrís el navegador que quieras
C:/Users/luis_/flutter/bin/flutter run -d web-server --web-port=8080
#   → después abrí http://localhost:8080 en cualquier navegador
```

> **Hot reload**: con Chrome, al guardar un archivo la app se actualiza sola
> (apretá `r` en la terminal para recargar, `R` para hot restart completo).

Si solo querés un build estático (sin servidor de desarrollo):

```bash
C:/Users/luis_/flutter/bin/flutter build web
#   → el resultado queda en build/web/, servilo con cualquier web server estático
```

## Prerequisites

- **Flutter SDK** at `C:\Users\luis_\flutter` (stable 3.41.x, Dart 3.11.x).
  Flutter is **not** on PATH — always use the full path `C:\Users\luis_\flutter\bin\flutter`
  (in Git Bash: `C:/Users/luis_/flutter/bin/flutter`; in cmd: `C:\Users\luis_\flutter\bin\flutter.bat`).
- **Android SDK** at `C:\Users\luis_\AppData\Local\Android\Sdk` (Android Studio or
  command-line tools; `flutter doctor` should be green for Android toolchain).
- Supported platforms: **android** and **web** only (no ios/macos/linux/windows folders).

## Setup

```bash
# 1. Install dependencies
C:/Users/luis_/flutter/bin/flutter pub get

# 2. Verify the environment (Android toolchain green)
C:/Users/luis_/flutter/bin/flutter doctor -v

# 3. Run the app on web
C:/Users/luis_/flutter/bin/flutter run -d chrome
#   → se abre Chrome con la app; hot reload al guardar
#   → para Android (emulador/dispositivo conectado):
#     C:/Users/luis_/flutter/bin/flutter run -d <device-id>
```

## Tests

| Command | Scope |
|---|---|
| `flutter test` | Full suite (widget/unit) |
| `flutter test test/app_smoke_test.dart` | Smoke baseline only |
| `flutter test --coverage` | Coverage report at `coverage/lcov.info` |

Tests mirror the source tree: `test/features/<feature>/` ↔ `lib/features/<feature>/`.
The smoke test (`test/app_smoke_test.dart`) pumps the real app inside a
`ProviderScope` and asserts the home screen renders.

## Structure

```
lib/
├── main.dart                     # Entry point: runApp(ProviderScope(child: App()))
├── app/
│   ├── app.dart                  # App: ConsumerWidget → MaterialApp.router
│   └── router.dart               # routerProvider (go_router) → '/' → HomePage
├── core/
│   └── theme/
│       └── app_theme.dart        # Material 3 ThemeData (seed color)
└── features/
    └── home/
        ├── application/
        │   └── home_providers.dart   # homeMessageProvider (Riverpod wiring demo)
        └── presentation/
            └── home_page.dart        # HomePage: shows the home message
```

## Conventions

- **State + DI**: flutter_riverpod 3 (providers are the DI container — no get_it).
- **Routing**: go_router, declared in `lib/app/router.dart`. Navigation goes
  through the router, never raw `Navigator.push` in widgets.
- **Lints**: flutter_lints (see `analysis_options.yaml`).
- **Git**: conventional commits on `main`; one deliverable work unit per commit.