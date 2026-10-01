#!/usr/bin/env bash
# docs/legal/ is the single source of the legal texts; the app bundles copies.
#   tool/sync_legal.sh          copy docs → app assets
#   tool/sync_legal.sh --check  fail if the copies differ (CI)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
status=0
for doc in privacy-policy terms-and-conditions; do
  src="$ROOT/docs/legal/$doc.md"
  dst="$ROOT/app/assets/legal/$doc.md"
  if [ "${1:-}" = "--check" ]; then
    cmp -s "$src" "$dst" || { echo "out of sync: $dst (run tool/sync_legal.sh)"; status=1; }
  else
    cp "$src" "$dst"
  fi
done
exit $status
