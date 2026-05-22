#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

bash "$ROOT_DIR/build.sh"

echo
echo "Deploying to Cloudflare Workers..."
npx wrangler deploy
