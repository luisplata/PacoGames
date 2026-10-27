#!/usr/bin/env bash
# Extract version from pubspec.yaml + derive tag/artifact names.
# Usage: RUN_NUMBER=<n> [RUN_ATTEMPT=<n>] bash scripts/release-info.sh [>> "$GITHUB_OUTPUT"]
set -euo pipefail

VERSION=$(grep "^version: " pubspec.yaml | awk '{print $2}')
VERSION_NAME=$(echo "$VERSION" | cut -d'+' -f1)
VERSION_NUMBER=$(echo "$VERSION" | cut -d'+' -f2)
RUN=${RUN_NUMBER:?}
ATTEMPT=${RUN_ATTEMPT:-1}

case "$RUN" in ''|*[!0-9]*)
  echo "RUN_NUMBER must be a positive integer" >&2
  exit 1
  ;;
esac
case "$ATTEMPT" in ''|*[!0-9]*)
  echo "RUN_ATTEMPT must be a positive integer" >&2
  exit 1
  ;;
esac

# Android versionCode: entero monótono y único por run + intento.
# No se commitea: el +N del pubspec es solo el default de desarrollo.
# Play exige que cada AAB subido tenga un versionCode mayor al anterior.
BUILD_NUMBER=$((RUN * 10 + ATTEMPT))

TAG="v${VERSION_NAME}-b${RUN}"
APK_NAME="PacoGames-dev-${VERSION_NAME}-b${RUN}.apk"
AAB_NAME="PacoGames-${VERSION_NAME}-b${RUN}.aab"
ZIP_NAME="PacoGames-web-${VERSION_NAME}-b${RUN}.zip"

echo "VERSION=${VERSION}"
echo "VERSION_NAME=${VERSION_NAME}"
echo "VERSION_NUMBER=${VERSION_NUMBER}"
echo "BUILD_NUMBER=${BUILD_NUMBER}"
echo "TAG=${TAG}"
echo "APK_NAME=${APK_NAME}"
echo "AAB_NAME=${AAB_NAME}"
echo "ZIP_NAME=${ZIP_NAME}"