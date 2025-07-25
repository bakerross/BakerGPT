## ./utils/docker/rebuild-bakergpt-image.sh
## Bash file to create the image with interactive inputs

#!/bin/bash

# --- Read Previous Version ---
VERSION_FILE="./VERSION.txt"
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

# --- Show Git Status ---
echo -e "\n🧾 Current changes:"
git status

# --- Prompt User for Git Add ---
echo -e "\n📦 Enter files to add (or press Enter for 'git add .'):"
read -r FILES_TO_ADD

if [ -z "$FILES_TO_ADD" ]; then
    echo "➡️ Staging all changes..."
    git add .
else
    echo "➡️ Staging selected files: $FILES_TO_ADD"
    git add $FILES_TO_ADD
fi

# --- Prompt for Commit Message ---
echo -e "\n🖊️ Enter a commit message (or press Enter for default):"
read -r COMMIT_MSG

# Set a fallback message if user skips
if [ -z "$COMMIT_MSG" ]; then
    COMMIT_MSG="$NEW_VERSION"
fi

# --- Make Commit ---
git commit -m "$COMMIT_MSG"
COMMIT_SHA=$(git rev-parse --short HEAD)

git push origin main

# --- Generate Metadata ---
BUILD_TIMESTAMP=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

# --- Build the Docker Image ---
docker build -f Dockerfile.multi \
  -t bakergpt:$NEW_VERSION-$COMMIT_SHA \
  --build-arg BUILD_TITLE="BakerGPT $NEW_VERSION" \
  --build-arg BUILD_VERSION="$NEW_VERSION-$COMMIT_SHA" \
  --build-arg BUILD_TIMESTAMP="$BUILD_TIMESTAMP" \
  --build-arg COMMIT_SHA="$COMMIT_SHA" \
  .

COMPOSE_FILE="local-compose.yml"

# Update the image tag in local-compose.yml
sed -i.bak -E "s|(image:\s*bakergpt:).*|\1$NEW_VERSION-$COMMIT_SHA|" "$COMPOSE_FILE"

# --- Summary ---
echo ""
echo "📝 VERSION.txt updated with: $NEW_VERSION"
echo "🏷 GitHub commit: $COMMIT_SHA"
echo "🚀️ GitHub commit message: $COMMIT_MSG"
echo "🐳 Image built: bakergpt:$NEW_VERSION-$COMMIT_SHA"
echo "🔄 Updated $COMPOSE_FILE to use: bakergpt:$NEW_VERSION-$COMMIT_SHA"