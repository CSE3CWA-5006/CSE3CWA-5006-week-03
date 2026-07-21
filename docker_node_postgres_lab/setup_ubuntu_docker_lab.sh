#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="$PROJECT_DIR/docker_lab_test.log"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
CONTAINER_NAME="cwa-postgres-lab"

: > "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

on_error() {
  local exit_code=$?
  echo
  echo "ERROR: setup stopped at line ${BASH_LINENO[0]} with exit code ${exit_code}."
  echo "Review: $LOG_FILE"
  exit "$exit_code"
}
trap on_error ERR

section() {
  echo
  echo "================================================================"
  echo "$1"
  echo "================================================================"
}

require_ubuntu() {
  if [[ ! -r /etc/os-release ]]; then
    echo "This script requires Ubuntu 22.04 or Ubuntu 24.04."
    exit 1
  fi

  # shellcheck disable=SC1091
  . /etc/os-release
  if [[ "${ID:-}" != "ubuntu" ]]; then
    echo "This script is for Ubuntu only. Detected: ${PRETTY_NAME:-unknown}."
    exit 1
  fi

  if grep -qiE '(microsoft|wsl)' /proc/version /proc/sys/kernel/osrelease 2>/dev/null; then
    echo "WSL was detected. Do not install a second Docker Engine inside WSL."
    echo "Use Docker Desktop with WSL integration, or run this script in the course Ubuntu VM."
    exit 1
  fi

  case "${VERSION_ID:-}" in
    22.04|24.04) ;;
    *)
      echo "Supported Ubuntu releases are 22.04 and 24.04. Detected: ${VERSION_ID:-unknown}."
      exit 1
      ;;
  esac

  echo "Operating system: $PRETTY_NAME"
}

install_base_tools() {
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg iproute2 python3
}

install_docker_if_needed() {
  if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
    echo "Docker and the Compose plugin are already installed."
    if command -v systemctl >/dev/null 2>&1; then
      sudo systemctl enable --now docker || true
    fi
    return
  fi

  local conflicts=()
  for package in docker.io docker-compose docker-compose-v2 podman-docker containerd runc; do
    if dpkg-query -W -f='${Status}' "$package" 2>/dev/null | grep -q 'install ok installed'; then
      conflicts+=("$package")
    fi
  done

  if (( ${#conflicts[@]} > 0 )); then
    echo "A conflicting Docker package is installed: ${conflicts[*]}"
    echo "This safety check will not remove existing container software automatically."
    echo "Use a fresh course Ubuntu VM, or follow Docker's official uninstall-conflict instructions first."
    exit 1
  fi

  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # shellcheck disable=SC1091
  . /etc/os-release
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu ${VERSION_CODENAME} stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt-get update
  sudo apt-get install -y \
    docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo systemctl enable --now docker
}

select_docker_command() {
  if docker info >/dev/null 2>&1; then
    DOCKER=(docker)
  else
    sudo docker info >/dev/null
    DOCKER=(sudo docker)
  fi

  local login_user="${SUDO_USER:-$USER}"
  if [[ "$login_user" != "root" ]] && ! id -nG "$login_user" | tr ' ' '\n' | grep -qx docker; then
    sudo usermod -aG docker "$login_user"
    echo "Added $login_user to the docker group. This takes effect after the next login."
  fi

  "${DOCKER[@]}" --version
  "${DOCKER[@]}" compose version
}

install_node_24_if_needed() {
  local major=""
  local installed_system_node=0
  if command -v node >/dev/null 2>&1; then
    major="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || true)"
  fi

  if [[ "$major" != "24" ]]; then
    echo "Installing the Node.js 24 release line from NodeSource."
    curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
    sudo apt-get install -y nodejs
    installed_system_node=1
  else
    echo "Node.js 24 is already installed at: $(command -v node)"
  fi

  if [[ "$installed_system_node" == "1" ]]; then
    # Prefer the system Node just installed by apt over an older nvm entry.
    export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
    hash -r
  fi

  node -e '
    const major = Number(process.versions.node.split(".")[0]);
    if (major !== 24) {
      console.error(`Node.js 24 is required. Current version: ${process.version}`);
      process.exit(1);
    }
    console.log(`Node.js version OK: ${process.version}`);
  '
  npm --version
}

check_container_and_port() {
  local compose_id running_id existing_id
  compose_id="$("${DOCKER[@]}" compose -f "$COMPOSE_FILE" ps -a -q postgres 2>/dev/null || true)"
  running_id="$("${DOCKER[@]}" compose -f "$COMPOSE_FILE" ps -q postgres 2>/dev/null || true)"
  existing_id="$("${DOCKER[@]}" ps -aq --filter "name=^/${CONTAINER_NAME}$" | head -n 1)"

  if [[ -n "$existing_id" && -z "$compose_id" ]]; then
    echo "A container named $CONTAINER_NAME already exists but does not belong to this Compose project."
    echo "Inspect it with: ${DOCKER[*]} ps -a --filter name=$CONTAINER_NAME"
    echo "Remove it only if it is an old copy: ${DOCKER[*]} rm -f $CONTAINER_NAME"
    exit 1
  fi

  if [[ -z "$running_id" ]] && ss -ltnH | awk '{print $4}' | grep -Eq '(^|:)5433$'; then
    echo "Host port 5433 is already in use."
    echo "Stop the existing service or change the host port in docker-compose.yml and .env together."
    exit 1
  fi
}

wait_for_postgres() {
  local status=""
  for _ in {1..36}; do
    status="$("${DOCKER[@]}" inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$CONTAINER_NAME" 2>/dev/null || true)"
    if [[ "$status" == "healthy" ]]; then
      echo "PostgreSQL container is healthy."
      return
    fi
    if [[ "$status" == "unhealthy" || "$status" == "exited" || "$status" == "dead" ]]; then
      echo "PostgreSQL container status: $status"
      "${DOCKER[@]}" compose -f "$COMPOSE_FILE" logs postgres || true
      exit 1
    fi
    echo "Waiting for PostgreSQL... status=${status:-starting}"
    sleep 5
  done

  echo "PostgreSQL did not become healthy within 180 seconds."
  "${DOCKER[@]}" compose -f "$COMPOSE_FILE" logs postgres || true
  exit 1
}

section "1. Check the Ubuntu environment"
require_ubuntu

section "2. Install required Ubuntu tools"
install_base_tools

section "3. Install or verify Docker Engine and Docker Compose"
install_docker_if_needed
select_docker_command

section "4. Install or verify Node.js 24"
install_node_24_if_needed

section "5. Check container names and host port 5433"
check_container_and_port

section "6. Create the deterministic Node.js environment file"
if [[ -f "$PROJECT_DIR/.env" ]] && ! cmp -s "$PROJECT_DIR/.env" "$PROJECT_DIR/.env.example"; then
  backup="$PROJECT_DIR/.env.backup.$(date +%Y%m%d-%H%M%S)"
  cp "$PROJECT_DIR/.env" "$backup"
  echo "Backed up the previous .env to: $backup"
fi
cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env"
echo "Configured .env for the classroom database on 127.0.0.1:5433."

section "7. Start PostgreSQL 17.10 in Docker"
"${DOCKER[@]}" compose -f "$COMPOSE_FILE" config -q
"${DOCKER[@]}" compose -f "$COMPOSE_FILE" up -d
wait_for_postgres
"${DOCKER[@]}" compose -f "$COMPOSE_FILE" ps

section "8. Reset and seed the exact Lab 1 dataset"
"${DOCKER[@]}" exec -i "$CONTAINER_NAME" \
  psql -v ON_ERROR_STOP=1 -U university_user -d university_db \
  < "$PROJECT_DIR/postgres-init/01_init.sql"

section "9. Verify the public npm lock file"
if grep -RqiE 'applied-caas|internal\.api\.openai|"latest"' \
  "$PROJECT_DIR/package.json" "$PROJECT_DIR/package-lock.json"; then
  echo "The npm files contain an internal registry URL or an unpinned latest dependency."
  exit 1
fi
python3 -m json.tool "$PROJECT_DIR/package.json" >/dev/null
python3 -m json.tool "$PROJECT_DIR/package-lock.json" >/dev/null

echo "package.json and package-lock.json use fixed versions and public registry URLs."

section "10. Install the exact Node.js dependency tree"
cd "$PROJECT_DIR"
npm ci --registry=https://registry.npmjs.org --no-audit --no-fund

section "11. Check JavaScript syntax and verify the database"
npm run check
npm run verify

section "12. Run the complete CRUD demonstration"
npm start

section "13. Verify that the temporary student was removed"
npm run verify

section "LAB COMPLETED SUCCESSFULLY"
echo "PostgreSQL remains running in Docker on 127.0.0.1:5433."
echo "Run the demo again: npm start"
echo "Inspect PostgreSQL: ${DOCKER[*]} exec -it $CONTAINER_NAME psql -U university_user -d university_db"
echo "Stop the lab: ${DOCKER[*]} compose -f $COMPOSE_FILE down"
echo "Clean reset: ${DOCKER[*]} compose -f $COMPOSE_FILE down -v"
echo "Complete log: $LOG_FILE"
if [[ "${DOCKER[0]}" == "sudo" ]]; then
  echo "Docker required sudo in this shell. Log out and back in after joining the docker group if you want non-sudo Docker commands."
fi
