#!/usr/bin/env bash
set -Eeuo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

node -e '
  const major = Number(process.versions.node.split(".")[0]);
  if (major !== 24) {
    console.error(`Node.js 24 is required. Current version: ${process.version}`);
    process.exit(1);
  }
'

npm ci --registry=https://registry.npmjs.org --no-audit --no-fund
npm run check
npm run verify
npm start
npm run verify
