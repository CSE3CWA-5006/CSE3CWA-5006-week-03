#!/usr/bin/env bash
set -euo pipefail

# CSE3CWA Docker + PostgreSQL + Node.js lab setup for Ubuntu.
# This script installs Docker Engine if needed, starts a PostgreSQL container,
# applies an idempotent teaching dataset, installs npm dependencies, and prints
# the commands students need for manual inspection.

DB_CONTAINER="cwa-postgres-lab"
DB_NAME="university_db"
DB_USER="university_user"
DB_PASSWORD="123456"  # Classroom-only password. Do not use this in production.
HOST_PORT="5433"

echo "== CSE3CWA Docker PostgreSQL Lab =="
echo "Platform: Ubuntu with Docker Engine and Docker Compose plugin."
echo "Purpose: run PostgreSQL in a container, then run Node.js manually on Ubuntu."
echo "Database user: ${DB_USER}"
echo "Database password: classroom demo password only"
echo "Host port: ${HOST_PORT}"
echo

echo "==> Installing basic Ubuntu packages"
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

if ! command -v node >/dev/null 2>&1; then
  echo "==> Installing Node.js 20 LTS from NodeSource"
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs
else
  echo "Node.js already installed: $(node --version)"
fi

if ! command -v docker >/dev/null 2>&1 || ! docker compose version >/dev/null 2>&1; then
  echo "==> Installing Docker Engine and Docker Compose plugin from Docker's official apt repository"
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
  echo "Docker already installed: $(docker --version)"
  echo "Docker Compose plugin already installed: $(docker compose version)"
fi

echo "==> Starting Docker service"
sudo systemctl enable --now docker

if ! docker ps >/dev/null 2>&1; then
  echo "==> Current user cannot access Docker without sudo."
  echo "Adding ${USER} to the docker group. You may need to log out and back in after this lab."
  sudo usermod -aG docker "$USER" || true
  DOCKER_CMD="sudo docker"
  COMPOSE_CMD="sudo docker compose"
else
  DOCKER_CMD="docker"
  COMPOSE_CMD="docker compose"
fi

echo "==> Preparing .env for Node.js"
cp -n .env.example .env

echo "==> Starting PostgreSQL container with Docker Compose"
${COMPOSE_CMD} up -d

echo "==> Waiting for PostgreSQL container to become healthy"
for attempt in {1..30}; do
  STATUS="$(${DOCKER_CMD} inspect -f '{{.State.Health.Status}}' "${DB_CONTAINER}" 2>/dev/null || echo starting)"
  echo "Health check attempt ${attempt}: ${STATUS}"
  if [ "${STATUS}" = "healthy" ]; then
    break
  fi
  sleep 3
done

if [ "$(${DOCKER_CMD} inspect -f '{{.State.Health.Status}}' "${DB_CONTAINER}")" != "healthy" ]; then
  echo "PostgreSQL container did not become healthy in time."
  echo "Try: ${COMPOSE_CMD} logs postgres"
  exit 1
fi

echo "==> Re-applying database schema and sample dataset safely"
${DOCKER_CMD} exec -i "${DB_CONTAINER}" psql -U "${DB_USER}" -d "${DB_NAME}" < postgres-init/01_init.sql

echo "==> Installing Node.js dependencies"
npm install

echo "==> Testing PostgreSQL connection from inside the container"
${DOCKER_CMD} exec "${DB_CONTAINER}" psql -U "${DB_USER}" -d "${DB_NAME}" -c "SELECT current_database(), current_user;"

echo "==> Testing seed data"
${DOCKER_CMD} exec "${DB_CONTAINER}" psql -U "${DB_USER}" -d "${DB_NAME}" -c "SELECT COUNT(*) AS student_count FROM students;"
${DOCKER_CMD} exec "${DB_CONTAINER}" psql -U "${DB_USER}" -d "${DB_NAME}" -c "SELECT COUNT(*) AS post_count FROM posts;"

cat <<HELP

Docker lab setup complete.

What is running now:
  - PostgreSQL is running inside Docker container: ${DB_CONTAINER}
  - Container port 5432 is mapped to Ubuntu host port ${HOST_PORT}
  - Node.js will run on Ubuntu and connect to localhost:${HOST_PORT}

Run the Node.js CRUD program:
  npm start

Manual PostgreSQL test from Ubuntu:
  ${DOCKER_CMD} exec -it ${DB_CONTAINER} psql -U ${DB_USER} -d ${DB_NAME}

Useful psql commands after entering the database:
  \\dt
  SELECT * FROM students;
  SELECT s.name, c.name AS course
  FROM students s
  JOIN enrolments e ON e.student_id = s.id
  JOIN courses c ON c.id = e.course_id
  ORDER BY s.id, c.id;
  \\q

Useful Docker commands:
  ${COMPOSE_CMD} ps
  ${COMPOSE_CMD} logs postgres
  ${DOCKER_CMD} exec -it ${DB_CONTAINER} bash
  ${COMPOSE_CMD} down

To remove the database volume as well, use this only when you want a clean reset:
  ${COMPOSE_CMD} down -v

HELP
