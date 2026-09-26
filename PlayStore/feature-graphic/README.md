# Feature graphic — regeneración

El feature graphic de Play Store se genera con ffmpeg a partir de los archivos vendidos. Si querés ajustar la composición (escala del logo, posición, fondo), regeneralo con este comando exacto:

```bash
ffmpeg -y -i PlayStore/feature-graphic/fondo_fuente.png -i PlayStore/icono/icono_playstore_512.png \
  -filter_complex "[0:v]scale=1024:500:force_original_aspect_ratio=increase,crop=1024:500[bg];[1:v]scale=-1:250[logo];[bg][logo]overlay=(W-w)/2:(H-h)/2" \
  -frames:v 1 -q:v 2 PlayStore/feature-graphic/feature_graphic_1024x500.jpg
```

## Qué hace

1. `fondo_fuente.png` (FondoMadera2, 1080x1920) → cover-crop a 1024x500 (escala con `force_original_aspect_ratio=increase` + `crop` centrado).
2. `icono_playstore_512.png` (logo con alpha) → escalado a 250px de alto (`scale=-1:250`).
3. Overlay centrado sobre el fondo (`(W-w)/2:(H-h)/2`).

## Verificación esperada

- Dimensiones: 1024x500
- Sin canal alpha (`yuvj420p` en ffprobe) — requisito de Play Store (JPG)

## Requisito Play

- 1024x500 exacto, JPG recomendado, sin alpha. ✓ (verificado programáticamente)