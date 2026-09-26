#!/usr/bin/env bash
# Generate Android launcher mipmaps + web PWA icons from the canonical Play Store icon.
# Zero deps: ffmpeg only. Env-overridable (ICON_SRC/RES_ROOT/WEB_ROOT/MASK_COLOR) for hermetic tests.
# Usage: bash scripts/launcher_icons.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

ICON_SRC=${ICON_SRC:-$REPO_ROOT/PlayStore/icono/icono_playstore_512.png}
RES_ROOT=${RES_ROOT:-$REPO_ROOT/android/app/src/main/res}
WEB_ROOT=${WEB_ROOT:-$REPO_ROOT/web}
MASK_COLOR=${MASK_COLOR:-0x1C1410}

[ -f "$ICON_SRC" ] || { echo "ERROR: icon source not found: $ICON_SRC" >&2; exit 1; }

declare -A DENS=( [mdpi]=48 [hdpi]=72 [xhdpi]=96 [xxhdpi]=144 [xxxhdpi]=192 )
for d in "${!DENS[@]}"; do
  mkdir -p "$RES_ROOT/mipmap-$d"
  ffmpeg -y -v error -i "$ICON_SRC" -vf "scale=${DENS[$d]}:${DENS[$d]}" "$RES_ROOT/mipmap-$d/ic_launcher.png"
done

mkdir -p "$WEB_ROOT/icons"
ffmpeg -y -v error -i "$ICON_SRC" -vf "scale=192:192" "$WEB_ROOT/icons/Icon-192.png"
ffmpeg -y -v error -i "$ICON_SRC" -vf "scale=512:512" "$WEB_ROOT/icons/Icon-512.png"
ffmpeg -y -v error -i "$ICON_SRC" -vf "scale=116:116,pad=192:192:(ow-iw)/2:(oh-ih)/2:color=$MASK_COLOR" "$WEB_ROOT/icons/Icon-maskable-192.png"
ffmpeg -y -v error -i "$ICON_SRC" -vf "scale=310:310,pad=512:512:(ow-iw)/2:(oh-ih)/2:color=$MASK_COLOR" "$WEB_ROOT/icons/Icon-maskable-512.png"
ffmpeg -y -v error -i "$ICON_SRC" -vf "scale=32:32" "$WEB_ROOT/favicon.png"

echo "icons generated from $ICON_SRC"