#!/bin/bash

set -euo pipefail

WORKSPACE="Amplitude.xcworkspace"
CONFIGURATION="Static Library"
BUILD_DIR="build"

# List of schemes and corresponding SDKs for each platform
PLATFORMS=(
  "Amplitude_macOS:macosx"
  "Amplitude_iOS:iphoneos"
  "Amplitude_tvOS:appletvos"
  "Amplitude_watchOS:watchos"
)

echo "📦 Starting multi-platform build..."

for entry in "${PLATFORMS[@]}"; do
  SCHEME="${entry%%:*}"
  SDK="${entry##*:}"

  echo "🚧 Building scheme '$SCHEME' with SDK '$SDK'..."

  xcodebuild \
    -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -sdk "$SDK" \
    BUILD_DIR="$BUILD_DIR" \
    build

  echo "✅ Finished building $SCHEME ($SDK)"
done

echo "🎉 All platform builds completed successfully."