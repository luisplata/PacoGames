# PacoGames — Resumen de estado (2026-09-27)

> Corte en `main` @ `49940ad` — `chore: mover arte de publicacion PlayStore fuera de assets`

## Qué es

Evolución de **PACO** (original en Unity) reescrito en **Flutter**.
App de juegos de fiesta: **Yo Nunca, Ruleta, Pictionary**, con selector, ajustes, modo sin alcohol, audio/hápticos y contenido vendorizado.

Repo: `https://github.com/luisplata/PacoGames.git` — rama `main` limpia, al día con `origin/main`.

## Stack

- Flutter stable 3.41.x / Dart 3.11.x — **NO está en PATH**, usar full path:
  `C:\Users\luis_\flutter\bin\flutter` (Git Bash: `C:/Users/luis_/flutter/bin/flutter`)
- Estado/DI: `flutter_riverpod ^3.3.2` (sin get_it)
- Routing: `go_router ^17.5.0` (`lib/app/router.dart`, nunca `Navigator.push` directo)
- Audio: `audioplayers 6.5.1` (vía `BytesSource` — fix web del doble-prefix `7b94364`)
- Persistencia: `shared_preferences ^2.5.5`
- Lints: `flutter_lints` — `flutter analyze` debe dar 0 issues
- Plataformas: **android + web** solamente
- Versión: `0.1.0+1` (`pubspec.yaml`)
- Android: `applicationId = "com.bellseboss.v2.pacogame"`, label `PacoGames`, portrait, permiso `AD_ID` para declaración de Play Console

## Dónde estamos (por hito)

| Hito | Commit | Estado |
|---|---|---|
| M0 esqueleto PACO (base feature-first, theme, router, home) | `6899c35` | ✅ |
| Fix splash spinner eterno tras boot async | `fa37fd8` | ✅ |
| M1 Yo Nunca (mazo + providers) | `3f11297` | ✅ |
| M2 Ruleta | `33c5e91` | ✅ |
| M3 Pictionary (sesión + cronómetro) | `343b87f` | ✅ |
| M4 Pulido (ajustes, cómo se juega, diagnóstico, audio/hápticos, contenido) | `95c9b32` | ✅ |
| M5 CI Releases (APK dev + ZIP web por release) | `f4dffb6` + fixes `facb2d5`, `7b94364` | ✅ |
| CI manual-only + fix 403 release (`softprops v3`) | `edd3ee9`, `d03bc01` | ✅ |
| Release signing producción (keystore + AAB) | `bb119e1` + fixes base64 `e8046d8`, `51af061`, `6e9c723` | ✅ |
| Sitio GitHub Pages (`docs/`: index, privacidad, términos) | `8a3a624`, `ed9deff` | ✅ |
| Organización PlayStore + icono + listing | `ca2ab53`, `a30ad6d`, `08d8d57`, `49940ad` | ✅ base, falta captura + decisiones usuario |

Features hoy en `lib/features/`: `ajustes, como_se_juega, diagnostico, home, pictionary, ruleta, selector, splash, yo_nunca`
Core en `lib/core/`: `ajustes, audio, contenido, theme, widgets` + `lib/app/`: `app, boot, orientacion, router`.

Tests: **32 archivos `*_test.dart`** espejando `lib/` (`test/features/`, `test/core/`, `test/app/` + `app_smoke_test.dart`). Cobertura en `coverage/lcov.info`.

## CI + Release (manual)

Workflow: `.github/workflows/ci-release.yml` — **solo `workflow_dispatch`** (no auto por push).

Corre: `pub get → analyze → test → test_release_info.sh → build APK release + AAB + web → Release` con tag `v<version>-b<run>`.

Artefactos por release:
- `PacoGames-dev-<version>-b<run>.apk`
- `PacoGames-... .aab` (producción firmada, keystore vía `KEYSTORE_BASE64` + `KEY_PROPERTIES_B64` en secrets)
- `PacoGames-web-<version>-b<run>.zip`

Scripts: `scripts/release-info.sh`, `scripts/launcher_icons.sh` (+ sus `test_*.sh`).

## PlayStore (`PlayStore/`)

Índice y checklist: `PlayStore/README.md`. Icono canónico: `icono/icono_playstore_512.png` (de ahí derivan launcher, PWA, favicon).

| Requisito | Estado |
|---|---|
| Icono 512 + master 2134 | ✅ listo |
| Feature graphic 1024x500 | ✅ generada |
| Título / short / full description, categoría Party + tags | ✅ borrador en `textos/listing.md` |
| Screenshots 1080x1920 (mín 2) | 🔲 proceso documentado, **captura pendiente** (`screenshots/README.md`) |
| Privacy policy URL pública | 🔲 pendiente decisión usuario (draft en `textos/privacidad.md`, sitio en `docs/privacidad.html`) |
| Content rating | 🔲 pendiente — estimación **18+** por alcohol + picante (modo sin alcohol mitiga pero no elimina; decisión del usuario) |
| Subida a Play | 🔲 fuera de alcance |

Nota: `49940ad` sacó el arte de publicación de `assets/` para que **no se empaquete en la app**.

## Pendiente / next

1. Screenshots reales (seguir `PlayStore/screenshots/README.md`, 2–8, 1080x1920).
2. Decidir y publicar privacy policy (hostear `docs/` en Pages y pegar URL en Play).
3. Responder cuestionario content rating (anticipar 18+).
4. Subir AAB firmado a Play Console (interno → producción).
5. Subir versión (`pubspec.yaml` `0.1.0+1` sigue en 0.1.0).

## Comandos

```bash
C:/Users/luis_/flutter/bin/flutter pub get
C:/Users/luis_/flutter/bin/flutter run -d chrome
C:/Users/luis_/flutter/bin/flutter test
C:/Users/luis_/flutter/bin/flutter analyze
C:/Users/luis_/flutter/bin/flutter build web
# Android release local (requiere android/key.properties + keystore):
C:/Users/luis_/flutter/bin/flutter build apk --release
C:/Users/luis_/flutter/bin/flutter build appbundle --release
```

## Convenciones

- Conventional commits sobre `main`, una unidad entregable por commit.
- Navegación por `go_router`, estado por Riverpod, tests espejo de `lib/`.
- Arte de publicación vive en `PlayStore/`, **nunca** en `assets/`.
