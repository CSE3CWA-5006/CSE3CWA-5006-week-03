#!/usr/bin/env bash
set -euo pipefail

# CSE3CWA TinkerGraph / Gremlin CRUD lab setup for Ubuntu only.
# This script does not cover Red Hat, macOS, Windows, or Docker.
# TinkerGraph in this classroom setup is an in-memory graph behind Gremlin Server.
# It does not use a database username or password in this local teaching setup.

TINKERPOP_VERSION="3.7.4"
INSTALL_DIR="$HOME/apache-tinkerpop-gremlin-server-${TINKERPOP_VERSION}"
ZIP_FILE="$HOME/apache-tinkerpop-gremlin-server.zip"

echo "==> Updating Ubuntu packages"
sudo apt update

echo "==> Installing Node.js 24 LTS if node is missing"
if ! command -v node >/dev/null 2>&1; then
  sudo apt install -y curl ca-certificates gnupg
  curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

echo "==> Installing Java and tools"
sudo apt install -y openjdk-21-jre curl unzip
java -version

if [ ! -d "$INSTALL_DIR" ]; then
  echo "==> Downloading Apache TinkerPop Gremlin Server ${TINKERPOP_VERSION}"
  curl -L -o "$ZIP_FILE" \
    "https://dlcdn.apache.org/tinkerpop/${TINKERPOP_VERSION}/apache-tinkerpop-gremlin-server-${TINKERPOP_VERSION}-bin.zip"
  unzip -q "$ZIP_FILE" -d "$HOME"
else
  echo "==> Gremlin Server already exists at $INSTALL_DIR"
fi

echo "==> Installing Node.js dependencies"
cp -n .env.example .env
npm install

echo "==> TinkerGraph / Gremlin lab setup complete"
cat <<HELP

Start Gremlin Server in a separate terminal:

cd "$INSTALL_DIR"
./bin/gremlin-server.sh conf/gremlin-server-modern.yaml

Then test it manually in another terminal:

cd "$INSTALL_DIR"
./bin/gremlin.sh
:remote connect tinkerpop.server conf/remote.yaml
:remote console
g.V().count()
g.V().hasLabel('person').values('name')

Then run the Node.js CRUD lab from this folder:

npm start

Node CRUD method used in this lab:
  Direct Gremlin traversal API
  CREATE: g.addV() and g.addE()
  READ:   g.V() and traversal steps
  UPDATE: g.V().property()
  DELETE: g.V().drop()

HELP
