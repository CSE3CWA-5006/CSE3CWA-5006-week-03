#!/usr/bin/env bash
set -euo pipefail

# Ubuntu-only setup script for the MongoDB + Prisma CRUD lab.
# It installs MongoDB Community Server, creates a teaching user, seeds the
# student dataset, installs Node packages, and generates the Prisma client.

DB_NAME="university_db"
DB_USER="university_user"
DB_PASSWORD="123456"

echo "== CWA MongoDB Prisma CRUD lab setup =="
echo "Target platform: Ubuntu only. This script does not cover Red Hat, macOS, Windows, or Docker."
echo "Database: MongoDB"
echo "Node data access method after setup: Prisma ORM"
echo

sudo apt update
sudo apt install -y curl ca-certificates gnupg lsb-release

if ! command -v node >/dev/null 2>&1; then
  echo "Installing Node.js 24 LTS from NodeSource..."
  curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
  sudo apt install -y nodejs
else
  echo "Node.js already installed: $(node --version)"
fi

if ! command -v mongod >/dev/null 2>&1; then
  echo "Installing MongoDB Community Server 8.0 for Ubuntu 24.04..."
  curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
    sudo gpg --batch --yes -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
  echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu noble/mongodb-org/8.0 multiverse" | \
    sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list >/dev/null
  sudo apt update
  sudo apt install -y mongodb-org
else
  echo "MongoDB already installed: $(mongod --version | head -n 1)"
fi

sudo systemctl enable mongod
sudo systemctl start mongod
sleep 2

if grep -q "authorization: enabled" /etc/mongod.conf; then
  MONGO_ADMIN="mongosh mongodb://${DB_USER}:${DB_PASSWORD}@localhost:27017/admin?authSource=admin"
else
  MONGO_ADMIN="mongosh"
fi

echo "Creating or updating MongoDB user ${DB_USER} with password ${DB_PASSWORD}..."
$MONGO_ADMIN <<MONGO
use admin
if (db.getUser("${DB_USER}")) {
  db.updateUser("${DB_USER}", {
    pwd: "${DB_PASSWORD}",
    roles: [
      { role: "readWrite", db: "${DB_NAME}" },
      { role: "dbAdmin", db: "${DB_NAME}" }
    ]
  });
} else {
  db.createUser({
    user: "${DB_USER}",
    pwd: "${DB_PASSWORD}",
    roles: [
      { role: "readWrite", db: "${DB_NAME}" },
      { role: "dbAdmin", db: "${DB_NAME}" }
    ]
  });
}
MONGO

if ! grep -q "authorization: enabled" /etc/mongod.conf; then
  echo "Enabling MongoDB password authentication..."
  if grep -q "^#security:" /etc/mongod.conf; then
    sudo sed -i '/^#security:/c\security:' /etc/mongod.conf
  elif ! grep -q "^security:" /etc/mongod.conf; then
    echo "security:" | sudo tee -a /etc/mongod.conf >/dev/null
  fi
  sudo sed -i '/^security:/a\  authorization: enabled' /etc/mongod.conf
  sudo systemctl restart mongod
  sleep 3
else
  echo "MongoDB password authentication is already enabled."
fi

MONGO_URL="mongodb://${DB_USER}:${DB_PASSWORD}@localhost:27017/${DB_NAME}?authSource=admin"

echo "Seeding the class dataset in MongoDB..."
mongosh "$MONGO_URL" <<MONGO
db.studentProfiles.deleteMany({});
db.studentProfiles.insertMany([
  {
    studentId: "S1",
    name: "Alice",
    major: "Computer Science",
    courses: ["Python Programming", "Artificial Intelligence"],
    posts: [
      { id: "P1", text: "Python loops finally make sense.", tags: ["Python"] },
      { id: "P2", text: "AI needs a lot of data.", tags: ["AI"] }
    ]
  },
  {
    studentId: "S2",
    name: "Ben",
    major: "Information Technology",
    courses: ["Python Programming"],
    posts: [
      { id: "P3", text: "I built a small Python calculator.", tags: ["Python"] }
    ]
  },
  {
    studentId: "S3",
    name: "Chloe",
    major: "Data Science",
    courses: ["Artificial Intelligence"],
    posts: [
      { id: "P4", text: "Neural networks are interesting.", tags: ["AI"] }
    ]
  },
  {
    studentId: "S4",
    name: "Daniel",
    major: "Cyber Security",
    courses: ["Computer Networking"],
    posts: [
      { id: "P5", text: "IP addresses are confusing.", tags: ["Networking"] }
    ]
  },
  {
    studentId: "S5",
    name: "Emma",
    major: "Software Engineering",
    courses: ["Python Programming", "Computer Networking"],
    posts: [
      { id: "P6", text: "Python is useful for network scripts.", tags: ["Python", "Networking"] }
    ]
  }
]);
db.studentProfiles.createIndex({ studentId: 1 }, { unique: true });
db.studentProfiles.find({}, { _id: 0, studentId: 1, name: 1, major: 1 }).sort({ studentId: 1 });
MONGO

echo "Writing .env file..."
cp -n .env.example .env

echo "Installing npm packages..."
npm install

echo "Generating Prisma client..."
npx prisma generate

echo
echo "Setup complete."
echo
echo "Manual MongoDB connection test:"
echo "  mongosh \"${MONGO_URL}\""
echo
echo "Useful commands after connecting:"
echo "  show collections"
echo "  db.studentProfiles.find({}, { _id: 0 }).pretty()"
echo "  db.studentProfiles.find({ courses: 'Python Programming' }, { _id: 0, name: 1, courses: 1 })"
echo
echo "Node CRUD method used in this lab:"
echo "  Prisma ORM for MongoDB"
echo "  CREATE: prisma.studentProfile.create()"
echo "  READ:   prisma.studentProfile.findMany()"
echo "  UPDATE: prisma.studentProfile.update()"
echo "  DELETE: prisma.studentProfile.delete()"
echo
echo "Run the CRUD demonstration:"
echo "  npm start"
