#!/usr/bin/env bash
# Plain-bash asserts for release-info.sh (no framework).
# Self-verifying: git bash (Windows) y ubuntu runner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/release-info.sh"

pass=0
fail=0

assert_line() { # $1 expected exact line, $2 actual output
  if printf '%s\n' "$2" | grep -Fxq "$1"; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
    echo "FAIL: expected line [$1] not found" >&2
  fi
}

# Case 1: patch 0.1.0 -> 0.1.1 (versionCode 1001)
OUT="$(CURRENT_VERSION=0.1.0 BUMP=patch bash "$SCRIPT")"
assert_line "CURRENT_VERSION=0.1.0" "$OUT"
assert_line "VERSION_NAME=0.1.1" "$OUT"
assert_line "VERSION_CODE=1001" "$OUT"
assert_line "TAG=v0.1.1" "$OUT"
assert_line "APK_NAME=PacoGames-0.1.1.apk" "$OUT"
assert_line "AAB_NAME=PacoGames-0.1.1.aab" "$OUT"
assert_line "ZIP_NAME=PacoGames-web-0.1.1.zip" "$OUT"

# Case 2: minor 0.1.0 -> 0.2.0 (versionCode 2000)
OUT="$(CURRENT_VERSION=0.1.0 BUMP=minor bash "$SCRIPT")"
assert_line "VERSION_NAME=0.2.0" "$OUT"
assert_line "VERSION_CODE=2000" "$OUT"

# Case 3: major 0.1.0 -> 1.0.0 (versionCode 1000000)
OUT="$(CURRENT_VERSION=0.1.0 BUMP=major bash "$SCRIPT")"
assert_line "VERSION_NAME=1.0.0" "$OUT"
assert_line "VERSION_CODE=1000000" "$OUT"

# Case 4: legacy tag suffix -b14 -> base 0.1.0
OUT="$(CURRENT_VERSION=0.1.0-b14 BUMP=patch bash "$SCRIPT")"
assert_line "CURRENT_VERSION=0.1.0" "$OUT"
assert_line "VERSION_NAME=0.1.1" "$OUT"

# Case 5: bump inválido -> must fail
if CURRENT_VERSION=0.1.0 BUMP=banana bash "$SCRIPT" >/dev/null 2>&1; then
  fail=$((fail + 1))
  echo "FAIL: expected non-zero exit for invalid BUMP" >&2
else
  pass=$((pass + 1))
fi

# Case 6: CURRENT_VERSION faltante -> must fail
if BUMP=patch bash "$SCRIPT" >/dev/null 2>&1; then
  fail=$((fail + 1))
  echo "FAIL: expected non-zero exit when CURRENT_VERSION is missing" >&2
else
  pass=$((pass + 1))
fi

# Case 7: CURRENT_VERSION inválida -> must fail
if CURRENT_VERSION=0.1 BUMP=patch bash "$SCRIPT" >/dev/null 2>&1; then
  fail=$((fail + 1))
  echo "FAIL: expected non-zero exit for invalid CURRENT_VERSION" >&2
else
  pass=$((pass + 1))
fi

echo
echo "release-info tests: $pass passed, $fail failed"
[ "$fail" -eq 0 ]
