#!/usr/bin/env bash
# Hermetic asserts for launcher_icons.sh (no framework, no network, no repo state).
# Fixture 512x512 lavfi PNG -> env-override ICON_SRC/RES_ROOT/WEB_ROOT -> assert dims.
# Pattern: test_release_info.sh. Self-verifying: git bash (Windows) y ubuntu runner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GEN="$SCRIPT_DIR/launcher_icons.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Fixture: solid-color 512x512 PNG (alpha channel present, like the PS icon)
ffmpeg -y -v error -f lavfi -i "color=c=0xddc587:s=512x512" -frames:v 1 "$TMP/fixture.png"

pass=0
fail=0

assert_dims() { # $1 file, $2 expected WxH
  local f="$1" exp="$2" dims
  if [ ! -f "$f" ]; then
    fail=$((fail + 1))
    echo "FAIL: missing $f" >&2
    return
  fi
  dims="$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$f")"
  dims="${dims/,/x}" # ffprobe csv prints "48,48" -> normalize to "48x48"
  if [ "$dims" = "$exp" ]; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    echo "FAIL: $f dims=$dims expected=$exp" >&2
  fi
}

# Run the generator against the fixture (hermetic: all outputs under $TMP)
ICON_SRC="$TMP/fixture.png" RES_ROOT="$TMP/res" WEB_ROOT="$TMP/web" bash "$GEN"

# 5 Android mipmaps
assert_dims "$TMP/res/mipmap-mdpi/ic_launcher.png" "48x48"
assert_dims "$TMP/res/mipmap-hdpi/ic_launcher.png" "72x72"
assert_dims "$TMP/res/mipmap-xhdpi/ic_launcher.png" "96x96"
assert_dims "$TMP/res/mipmap-xxhdpi/ic_launcher.png" "144x144"
assert_dims "$TMP/res/mipmap-xxxhdpi/ic_launcher.png" "192x192"

# 5 web icons
assert_dims "$TMP/web/icons/Icon-192.png" "192x192"
assert_dims "$TMP/web/icons/Icon-512.png" "512x512"
assert_dims "$TMP/web/icons/Icon-maskable-192.png" "192x192"
assert_dims "$TMP/web/icons/Icon-maskable-512.png" "512x512"
assert_dims "$TMP/web/favicon.png" "32x32"

# Must NOT create round launcher icons (verified absent in template)
if [ -f "$TMP/res/mipmap-mdpi/ic_launcher_round.png" ]; then
  fail=$((fail + 1))
  echo "FAIL: round icon should NOT exist" >&2
else
  pass=$((pass + 1))
fi

echo
echo "launcher-icons tests: $pass passed, $fail failed"
[ "$fail" -eq 0 ]