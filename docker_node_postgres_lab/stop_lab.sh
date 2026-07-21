#!/usr/bin/env bash
set -Eeuo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if docker info >/dev/null 2>&1; then
  docker compose -f "$PROJECT_DIR/docker-compose.yml" down
else
  sudo docker compose -f "$PROJECT_DIR/docker-compose.yml" down
fi
