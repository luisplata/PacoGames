#!/usr/bin/env bash
# Plain-bash asserts for release-info.sh (no framework).
# Self-verifying: git bash (Windows) y ubuntu runner.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$SCRIPT_DIR/release-info.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cat > "$TMP/pubspec.yaml" <<'EOF'
name: fixture_app
description: fixture for release-info tests
version: 0.1.0+1
EOF

cd "$TMP"

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

# Case 1: happy path (run 42)
OUT="$(RUN_NUMBER=42 bash "$SCRIPT")"
assert_line "VERSION=0.1.0+1" "$OUT"
assert_line "VERSION_NAME=0.1.0" "$OUT"
assert_line "VERSION_NUMBER=1" "$OUT"
assert_line "TAG=v0.1.0-b42" "$OUT"
assert_line "APK_NAME=PacoGames-dev-0.1.0-b42.apk" "$OUT"
assert_line "AAB_NAME=PacoGames-0.1.0-b42.aab" "$OUT"
assert_line "ZIP_NAME=PacoGames-web-0.1.0-b42.zip" "$OUT"

# Case 2: RUN_NUMBER empty/missing -> must fail
if RUN_NUMBER="" bash "$SCRIPT" >/dev/null 2>&1; then
  fail=$((fail + 1))
  echo "FAIL: expected non-zero exit when RUN_NUMBER is empty" >&2
else
  pass=$((pass + 1))
fi

echo
echo "release-info tests: $pass passed, $fail failed"
[ "$fail" -eq 0 ]