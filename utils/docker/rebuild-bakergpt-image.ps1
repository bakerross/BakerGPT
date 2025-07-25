# PowerShell Script to Build Docker Image with Interactive Inputs

$VERSION_FILE = "./VERSION.txt"

# --- Read Previous Version ---
if (Test-Path $VERSION_FILE) {
    $LAST_VERSION = Get-Content $VERSION_FILE
} else {
    $LAST_VERSION = "(none yet)"
}
Write-Host "🔍 Last version used: $LAST_VERSION"
Write-Host ""

# --- Prompt for New Version ---
$NEW_VERSION = Read-Host "🆕 Enter new VERSION name"
if ([string]::IsNullOrWhiteSpace($NEW_VERSION)) {
    Write-Host "❌ Error: VERSION name cannot be empty."
    exit 1
}

# --- Save New Version ---
$NEW_VERSION | Set-Content $VERSION_FILE

# --- Show Git Status ---
Write-Host "`n🧾 Current changes:"
git status

# --- Prompt for Git Add ---
$FILES_TO_ADD = Read-Host "`n📦 Enter files to add (or press Enter for 'git add .')"
if ([string]::IsNullOrWhiteSpace($FILES_TO_ADD)) {
    Write-Host "➡️ Staging all changes..."
    git add .
} else {
    Write-Host "➡️ Staging selected files: $FILES_TO_ADD"
    git add $FILES_TO_ADD
}

# --- Prompt for Commit Message ---
$COMMIT_MSG = Read-Host "`n🖊️ Enter a commit message (or press Enter for default)"
if ([string]::IsNullOrWhiteSpace($COMMIT_MSG)) {
    $COMMIT_MSG = $NEW_VERSION
}

# --- Make Commit ---
git commit -m "$COMMIT_MSG"
$COMMIT_SHA = git rev-parse --short HEAD

git push origin main

# --- Generate Metadata ---
$BUILD_TIMESTAMP = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")

# --- Build the Docker Image ---
docker build -f Dockerfile.multi `
  -t "bakergpt:$NEW_VERSION-$COMMIT_SHA" `
  --build-arg BUILD_TITLE="BakerGPT $NEW_VERSION" `
  --build-arg BUILD_VERSION="$NEW_VERSION-$COMMIT_SHA" `
  --build-arg BUILD_TIMESTAMP="$BUILD_TIMESTAMP" `
  --build-arg COMMIT_SHA="$COMMIT_SHA" `
  .

# --- Update Image Tag in local-compose.yml ---
$COMPOSE_FILE = "local-compose.yml"
$composeText = Get-Content $COMPOSE_FILE
$updatedText = $composeText -replace 'image:\s*bakergpt:.*', "image: bakergpt:$NEW_VERSION-$COMMIT_SHA"
$updatedText | Set-Content $COMPOSE_FILE
Copy-Item $COMPOSE_FILE "$COMPOSE_FILE.bak" -Force

# --- Summary ---
Write-Host ""
Write-Host "📝 VERSION.txt updated with: $NEW_VERSION"
Write-Host "🏷 GitHub commit: $COMMIT_SHA"
Write-Host "🚀️ GitHub commit message: $COMMIT_MSG"
Write-Host "🐳 Image built: bakergpt:$NEW_VERSION-$COMMIT_SHA"
Write-Host "🛠 Updated $COMPOSE_FILE to use: bakergpt:$NEW_VERSION-$COMMIT_SHA"