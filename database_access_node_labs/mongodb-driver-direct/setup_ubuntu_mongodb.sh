#!/usr/bin/env bash
set -euo pipefail

# CSE3CWA MongoDB CRUD lab setup for Ubuntu only.
# This script does not cover Red Hat, macOS, Windows, or Docker.
# Password 123456 is for a local classroom VM only. Do not use it in production.

DB_NAME="university_db"
DB_USER="university_user"
DB_PASSWORD="123456"

echo "==> Updating Ubuntu packages"
sudo apt-get update

echo "==> Installing Node.js 24 LTS if node is missing"
if ! command -v node >/dev/null 2>&1; then
  sudo apt-get install -y curl ca-certificates gnupg
  curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
  sudo apt-get install -y nodejs
else
  echo "Node.js already installed: $(node --version)"
fi

if ! command -v mongod >/dev/null 2>&1; then
  echo "==> Installing MongoDB Community Edition 8.0 for Ubuntu 24.04 LTS"
  sudo apt-get install -y gnupg curl
  curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
    sudo gpg --batch --yes -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor

  echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | \
    sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list >/dev/null

  sudo apt-get update
  sudo apt-get install -y mongodb-org
else
  echo "MongoDB already installed: $(mongod --version | head -n 1)"
fi
sudo systemctl enable --now mongod
sleep 2

echo "==> Creating or updating MongoDB classroom user"
if grep -q "authorization: enabled" /etc/mongod.conf; then
  MONGO_SHELL="mongosh mongodb://${DB_USER}:${DB_PASSWORD}@localhost:27017/admin?authSource=admin"
else
  MONGO_SHELL="mongosh"
fi

$MONGO_SHELL <<MONGO
use admin
if (db.getUser("${DB_USER}")) {
  db.updateUser("${DB_USER}", {
    pwd: "${DB_PASSWORD}",
    roles: [
      { role: "readWrite", db: "${DB_NAME}" },
      { role: "dbAdmin", db: "${DB_NAME}" }
    ]
  })
} else {
  db.createUser({
    user: "${DB_USER}",
    pwd: "${DB_PASSWORD}",
    roles: [
      { role: "readWrite", db: "${DB_NAME}" },
      { role: "dbAdmin", db: "${DB_NAME}" }
    ]
  })
}
MONGO

echo "==> Enabling MongoDB authentication if not already enabled"
if ! grep -q "authorization: enabled" /etc/mongod.conf; then
  if grep -q "^#security:" /etc/mongod.conf; then
    sudo sed -i '/^#security:/c\security:' /etc/mongod.conf
  elif ! grep -q "^security:" /etc/mongod.conf; then
    echo "security:" | sudo tee -a /etc/mongod.conf >/dev/null
  fi
  sudo sed -i '/^security:/a\  authorization: enabled' /etc/mongod.conf
else
  echo "MongoDB authentication is already enabled."
fi
sudo systemctl restart mongod
sleep 3

echo "==> Initialising sample dataset"
mongosh "mongodb://${DB_USER}:${DB_PASSWORD}@localhost:27017/${DB_NAME}?authSource=admin" <<'MONGO'
db.studentProfiles.deleteMany({});
db.studentProfiles.insertMany([
  {
    studentId: "S1",
    name: "Alice",
    major: "Computer Science",
    courses: ["Python Programming", "Artificial Intelligence"],
    posts: [
      {
        id: "P1",
        text: "Python loops finally make sense.",
        tags: ["Python"]
      },
      {
        id: "P2",
        text: "AI needs a lot of data.",
        tags: ["AI"]
      }
    ]
  },
  {
    studentId: "S2",
    name: "Ben",
    major: "Information Technology",
    courses: ["Python Programming"],
    posts: [
      {
        id: "P3",
        text: "I built a small Python calculator.",
        tags: ["Python"]
      }
    ]
  },
  {
    studentId: "S3",
    name: "Chloe",
    major: "Data Science",
    courses: ["Artificial Intelligence"],
    posts: [
      {
        id: "P4",
        text: "Neural networks are interesting.",
        tags: ["AI"]
      }
    ]
  },
  {
    studentId: "S4",
    name: "Daniel",
    major: "Cyber Security",
    courses: ["Computer Networking"],
    posts: [
      {
        id: "P5",
        text: "IP addresses are confusing.",
        tags: ["Networking"]
      }
    ]
  },
  {
    studentId: "S5",
    name: "Emma",
    major: "Software Engineering",
    courses: ["Python Programming", "Computer Networking"],
    posts: [
      {
        id: "P6",
        text: "Python is useful for network scripts.",
        tags: ["Python", "Networking"]
      }
    ]
  }
]);
db.studentProfiles.createIndex({ studentId: 1 }, { unique: true });
MONGO

echo "==> Testing MongoDB connection"
mongosh "mongodb://${DB_USER}:${DB_PASSWORD}@localhost:27017/${DB_NAME}?authSource=admin" \
  --eval 'db.runCommand({ connectionStatus: 1 })'

echo "==> Useful manual test commands for students"
cat <<'HELP'
# Copy and run these after setup if you want to test MongoDB manually:
mongosh "mongodb://university_user:123456@localhost:27017/university_db?authSource=admin"
db.studentProfiles.find({}, { _id: 0, studentId: 1, name: 1, major: 1 }).pretty()
db.studentProfiles.find({ courses: "Python Programming" }).pretty()
exit
HELP

echo "==> Installing Node.js dependencies"
cp -n .env.example .env
npm install

echo "==> MongoDB lab setup complete"
echo "Node CRUD method used in this lab:"
echo "  Official MongoDB Node.js driver"
echo "  CREATE: collection.insertOne()"
echo "  READ:   collection.find()"
echo "  UPDATE: collection.updateOne()"
echo "  DELETE: collection.deleteOne()"
echo "Run: npm start"
