#!/usr/bin/env bash
# Compute the next SemVer + Android versionCode for a release.
# Usage: CURRENT_VERSION=<x.y.z> BUMP=<patch|minor|major> bash scripts/release-info.sh [>> "$GITHUB_OUTPUT"]
set -euo pipefail

CURRENT_VERSION=${CURRENT_VERSION:?}
BUMP=${BUMP:?}

# Acepta tags legacy tipo 0.1.0-b14 → base SemVer 0.1.0.
CURRENT_VERSION="${CURRENT_VERSION%%-*}"

IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
for part in "$MAJOR" "$MINOR" "$PATCH"; do
  case "$part" in
    '' | *[!0-9]*)
      echo "CURRENT_VERSION must be SemVer x.y.z (got '$CURRENT_VERSION')" >&2
      exit 1
      ;;
  esac
done

case "$BUMP" in
  patch) PATCH=$((PATCH + 1)) ;;
  minor) MINOR=$((MINOR + 1)); PATCH=0 ;;
  major) MAJOR=$((MAJOR + 1)); MINOR=0; PATCH=0 ;;
  *)
    echo "BUMP must be patch|minor|major (got '$BUMP')" >&2
    exit 1
    ;;
esac

VERSION_NAME="${MAJOR}.${MINOR}.${PATCH}"
# versionCode estilo Play/Galaga: major*1e6 + minor*1e3 + patch.
# 0.1.1 -> 1001 · 0.2.0 -> 2000 · 1.0.0 -> 1000000. Siempre monótono.
VERSION_CODE=$((MAJOR * 1000000 + MINOR * 1000 + PATCH))

TAG="v${VERSION_NAME}"
APK_NAME="PacoGames-${VERSION_NAME}.apk"
AAB_NAME="PacoGames-${VERSION_NAME}.aab"
ZIP_NAME="PacoGames-web-${VERSION_NAME}.zip"

echo "CURRENT_VERSION=${CURRENT_VERSION}"
echo "VERSION_NAME=${VERSION_NAME}"
echo "VERSION_CODE=${VERSION_CODE}"
echo "TAG=${TAG}"
echo "APK_NAME=${APK_NAME}"
echo "AAB_NAME=${AAB_NAME}"
echo "ZIP_NAME=${ZIP_NAME}"
