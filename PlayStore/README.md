# PlayStore — Materiales para Google Play

Todo lo que Play Store necesita de PacoGames, indexado. **El icono canónico es `icono/icono_playstore_512.png`** (512², spec exacta de Play) y de ahí se derivan launcher Android, web PWA y favicon.

## Checklist Play → archivo

| Requisito Play | Estado | Archivo |
|----------------|--------|---------|
| Ícono (512x512) | ✅ listo | `icono/icono_playstore_512.png` |
| Ícono maestro (alta resolución) | ✅ archivo | `icono/logo_master_2134.png` |
| Feature graphic (1024x500) | ✅ generado | `feature-graphic/feature_graphic_1024x500.jpg` |
| Screenshots (mín 2, máx 8, 1080x1920) | 🔲 proceso documentado, captura pendiente | `screenshots/README.md` |
| Título (≤30) | ✅ borrador | `textos/listing.md` |
| Short description (≤80) | ✅ borrador | `textos/listing.md` |
| Full description (≤4000) | ✅ borrador | `textos/listing.md` |
| Categoría (Games → Party) + tags | ✅ borrador | `textos/listing.md` |
| Privacy policy (URL pública) | 🔲 pendiente (decisión de usuario) | `textos/privacidad.md` (draft) |
| Content rating (cuestionario) | 🔲 pendiente (decisión de usuario) | ver sección abajo |
| Envío/subida a Play Store | 🔲 fuera de alcance | — |

## Content rating (cuestionario obligatorio de Play)

Play exige responder un cuestionario de clasificación de contenido. Estimación para PacoGames:

- **Contenido de alcohol** → probabilidad **18+**.
- **Contenido picante** (juegos de previa) → probablemente contribuye a 18+.
- **Mitigación**: el modo sin alcohol oculta contenido picante y convierte tragos en prendas/puntos; documentar esto al responder puede bajar la clasificación, pero **la app incluye alcohol como opción** → anticipar 18+ como base.
- Las respuestas finales son **decisión del usuario** (OUT de este cambio).

## Estructura

```
PlayStore/
├── README.md                ← este archivo (índice + checklist)
├── icono/
│   ├── icono_playstore_512.png   (canon, 512²)
│   ├── logo_master_2134.png      (master, archivo)
│   └── ORIGEN.md                 (procedencia + URLs)
├── feature-graphic/
│   ├── fondo_fuente.png          (FondoMadera2 vendido, 1080x1920)
│   ├── feature_graphic_1024x500.jpg  (generada, sin alpha)
│   └── README.md                 (comando regenerable)
├── screenshots/
│   └── README.md                 (proceso de captura real)
└── textos/
    ├── listing.md                (copy + contadores + checklist)
    └── privacidad.md             (draft + nota de hosting)
```