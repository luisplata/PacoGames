# PacoGame

Base Flutter project for PacoGame, scaffolded with a feature-first structure,
Riverpod 3 for state/DI and go_router for navigation. No game features yet —
this is the runnable foundation.

**Quick start:**

| Command (full SDK path — Flutter is NOT on PATH) | What it does |
|---|---|
| `C:\Users\luis_\flutter\bin\flutter pub get` | Install dependencies |
| `C:\Users\luis_\flutter\bin\flutter run` | Run the app (pick android or web device) |
| `C:\Users\luis_\flutter\bin\flutter test` | Run the test suite |
| `C:\Users\luis_\flutter\bin\flutter analyze` | Static analysis (must be 0 issues) |

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

# 3. Run the app
C:/Users/luis_/flutter/bin/flutter run
#   - press "1" to open on an Android device/emulator
#   - press "2" to open on Chrome (web)
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