#!/usr/bin/env bash
set -euo pipefail

echo "Taking nineyards.pt offline (503)..."
npx wrangler deploy --config wrangler.offline.toml
echo "Done. Run 'bash deploy.sh' to bring the site back online."
