#!/usr/bin/env bash
set -Eeuo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if docker info >/dev/null 2>&1; then
  DOCKER=(docker)
else
  DOCKER=(sudo docker)
fi

"${DOCKER[@]}" compose -f "$PROJECT_DIR/docker-compose.yml" down -v --remove-orphans
rm -rf "$PROJECT_DIR/node_modules"
rm -f "$PROJECT_DIR/.env" "$PROJECT_DIR/docker_lab_test.log" "$PROJECT_DIR"/.env.backup.*
echo "The container, network, named database volume, .env and test log were removed."
echo "Run ./setup_ubuntu_docker_lab.sh to rebuild the lab from zero."
