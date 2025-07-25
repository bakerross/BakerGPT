## Bash file to create the image with interactive filenaming

#!/bin/bash

# --- Read Previous Version ---
VERSION_FILE="./client/public/VERSION.txt"
if [[ -f "$VERSION_FILE" ]]; then
  LAST_VERSION=$(cat "$VERSION_FILE")
else
  LAST_VERSION="(none yet)"
fi

echo "🔍 Last version used: $LAST_VERSION"
echo ""

# --- Prompt for New Version ---
read -p "🆕 Enter new VERSION name: " NEW_VERSION

if [[ -z "$NEW_VERSION" ]]; then
  echo "❌ Error: VERSION name cannot be empty."
  exit 1
fi

# --- Save New Version ---
echo "$NEW_VERSION" > "$VERSION_FILE"

# --- Generate Metadata ---
COMMIT_SHA=$(git rev-parse --short HEAD)
BUILD_TIMESTAMP=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

# --- Build the Docker Image ---
docker build -f Dockerfile.multi \
  -t bakergpt:$NEW_VERSION-$COMMIT_SHA \
  --build-arg BUILD_TITLE="BakerGPT $NEW_VERSION" \
  --build-arg BUILD_VERSION="$NEW_VERSION-$COMMIT_SHA" \
  --build-arg BUILD_TIMESTAMP="$BUILD_TIMESTAMP" \
  --build-arg COMMIT_SHA="$COMMIT_SHA" \
  .

# --- Summary ---
echo ""
echo "✅ Image built: bakergpt:$NEW_VERSION-$COMMIT_SHA"
echo "📝 VERSION.txt updated with: $NEW_VERSION"