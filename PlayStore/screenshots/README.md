# Screenshots — proceso de captura (pendiente)

Las screenshots de Play Store se capturan del juego REAL. **Nunca fakes** (no edición/maquetado de imágenes falsas): Google Play lo penaliza.

## Requisitos de Play

- Mínimo **2**, máximo **8** capturas.
- Recomendado: **1080x1920** portrait (móvil), JPG o PNG de 24-bit.
- Deben mostrar la app real corriendo.

## Cómo capturar (cuando haya emulador/dispositivo)

1. **Fuente**: integration_test con `takeScreenshot` (binding.takeScreenshot) o captura de emulador (adb).
2. **Dispositivo**: emulador Android con resolución 1080x1920 (o redimensionar a esa resolución exacta después).
3. **Escenas sugeridas**: pantalla de inicio, Yo Nunca (carta en juego), Ruleta (girando/resultado), Pictionary (tablero con palabra).
4. **Sin fakes**: captura real del juego, sin overlays ni retoques que no reflejen la app.

## Estado

- 🔲 Captura real: **pendiente** (requiere emulador) — fuera del alcance de este cambio.
- ✅ Proceso documentado acá.

## Flujo recomendado

1. Levantar emulador 1080x1920.
2. Correr `flutter test integration_test/screenshots_test.dart` (o similar) que navega las 4 escenas y toma `takeScreenshot`.
3. Copiar los PNGs a `PlayStore/screenshots/`.
4. Verificar dims 1080x1920 + que la app se vea real (revisión humana).