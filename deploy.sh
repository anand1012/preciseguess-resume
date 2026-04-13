#!/bin/bash
# =============================================================================
# deploy.sh — preciseguess.com
# Deploys website to GCS, purges Cloudflare cache, pushes to GitHub
# Usage: ./deploy.sh
# =============================================================================

set -e

# Load environment variables from .env
if [ -f "$(dirname "$0")/.env" ]; then
  export $(cat "$(dirname "$0")/.env" | grep -v '#' | xargs)
else
  echo "❌ .env file not found! Create it with CLOUDFLARE_TOKEN and CLOUDFLARE_ZONE_ID"
  exit 1
fi

# Check required vars
if [ -z "$CLOUDFLARE_TOKEN" ] || [ -z "$CLOUDFLARE_ZONE_ID" ]; then
  echo "❌ CLOUDFLARE_TOKEN or CLOUDFLARE_ZONE_ID missing in .env"
  exit 1
fi

SITE_DIR="$(dirname "$0")"
GCS_BUCKET="gs://preciseguess.com"

echo "🚀 Starting deployment of preciseguess.com..."
echo ""

# -----------------------------------------------------------------------------
# 1. Upload to GCS
# -----------------------------------------------------------------------------
echo "📦 Uploading files to GCS..."
gsutil -h "Cache-Control:no-cache, no-store, must-revalidate" cp "$SITE_DIR/index.html" "$GCS_BUCKET/"
gsutil -h "Cache-Control:no-cache, no-store, must-revalidate" cp "$SITE_DIR/style.css" "$GCS_BUCKET/"
echo "✅ Files uploaded to GCS"
echo ""

# -----------------------------------------------------------------------------
# 2. Purge Cloudflare cache
# -----------------------------------------------------------------------------
echo "🧹 Purging Cloudflare cache..."
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
  "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/purge_cache" \
  -H "Authorization: Bearer $CLOUDFLARE_TOKEN" \
  -H "Content-Type: application/json" \
  --data '{"purge_everything":true}')

if [ "$RESPONSE" = "200" ]; then
  echo "✅ Cloudflare cache purged"
else
  echo "⚠️  Cloudflare purge returned HTTP $RESPONSE — check token/zone ID"
fi
echo ""

# -----------------------------------------------------------------------------
# 3. Push to GitHub
# -----------------------------------------------------------------------------
echo "📤 Pushing to GitHub..."
cd "$SITE_DIR"
git add index.html style.css gcp-commands.sh deploy.sh
git commit -m "Deploy: $(date '+%Y-%m-%d %H:%M')" || echo "ℹ️  Nothing new to commit"
git push
echo "✅ Pushed to GitHub"
echo ""

echo "🎉 Done! Visit https://preciseguess.com"
