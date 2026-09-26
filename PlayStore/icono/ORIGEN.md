# PlayStore/icono — Origen de los archivos

Procedencia y verificación del arte vendido desde el repo Unity `luisplata/PACO` (rama `main`). Verificado el 2026-09-26.

## icono_playstore_512.png — ICONO CANÓNICO de Play Store (decisión de usuario)

| Campo | Valor |
|-------|-------|
| Fuente | `Assets/Images/RediseñoPacoVectorial/Logos/Logo PACO_PS.png` |
| URL | `https://media.githubusercontent.com/media/luisplata/PACO/main/Assets/Images/Redise%C3%B1oPacoVectorial/Logos/Logo%20PACO_PS.png` |
| Servido por | media.githubusercontent.com (LFS pointer, verificado HTTP 200) |
| Dimensión | 512x512 (spec exacta de Play Store) |
| Rol | Fuente única de todos los iconos derivados (launcher Android, web PWA, favicon) |

## logo_master_2134.png — MASTER (solo archivo/procedencia)

| Campo | Valor |
|-------|-------|
| Fuente | `Assets/Images/RediseñoPacoVectorial/Logos/Logo PACO 1-02.png` |
| URL | `https://raw.githubusercontent.com/luisplata/PACO/main/Assets/Images/Redise%C3%B1oPacoVectorial/Logos/Logo%20PACO%201-02.png` |
| Servido por | raw.githubusercontent.com (blob plano, verificado HTTP 200) |
| Dimensión | 2134x2134 |
| Rol | Archivo maestro de máxima resolución. NO se usa como fuente de iconos (canon = PS 512²). |

## Notas de encoding

- `Rediseño` → `%C3%B1` (ñ minúscula)
- `DISEÑOS` → `%C3%91` (Ñ mayúscula, solo aplica a fondo_fuente.png)

## Verificación

- Magic bytes PNG (`89 50 4E 47`) ✓ para ambos archivos
- Dimensiones IHDR (parse struct, sin PIL): 512x512 y 2134x2134 ✓