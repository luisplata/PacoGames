#!/usr/bin/env bash
# Extract version from pubspec.yaml + derive tag/artifact names.
# Usage: RUN_NUMBER=<n> bash scripts/release-info.sh [>> "$GITHUB_OUTPUT"]
set -euo pipefail

VERSION=$(grep "^version: " pubspec.yaml | awk '{print $2}')
VERSION_NAME=$(echo "$VERSION" | cut -d'+' -f1)
VERSION_NUMBER=$(echo "$VERSION" | cut -d'+' -f2)
RUN=${RUN_NUMBER:?}

TAG="v${VERSION_NAME}-b${RUN}"
APK_NAME="PacoGames-dev-${VERSION_NAME}-b${RUN}.apk"
ZIP_NAME="PacoGames-web-${VERSION_NAME}-b${RUN}.zip"

echo "VERSION=${VERSION}"
echo "VERSION_NAME=${VERSION_NAME}"
echo "VERSION_NUMBER=${VERSION_NUMBER}"
echo "TAG=${TAG}"
echo "APK_NAME=${APK_NAME}"
echo "ZIP_NAME=${ZIP_NAME}"