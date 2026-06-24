#!/usr/bin/env bash
set -euo pipefail

# PostgreSQL + Drizzle CRUD lab setup for Ubuntu only.
# This installs PostgreSQL, prepares the shared classroom database,
# and installs Drizzle dependencies.

DB_NAME="university_db"
DB_USER="university_user"
DB_PASSWORD="123456"

echo "==> This lab uses Drizzle ORM with PostgreSQL."
echo "==> Ubuntu only. Red Hat, macOS, Windows, and Docker are not covered."
echo "==> Password 123456 is for local classroom VMs only."

sudo apt update

if ! command -v node >/dev/null 2>&1; then
  sudo apt install -y curl ca-certificates gnupg
  curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable --now postgresql

sudo -u postgres psql <<SQL
DO
\\$\\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${DB_USER}') THEN
    CREATE ROLE ${DB_USER} LOGIN PASSWORD '${DB_PASSWORD}';
  ELSE
    ALTER ROLE ${DB_USER} WITH PASSWORD '${DB_PASSWORD}';
  END IF;
END
\\$\\$;

SELECT 'CREATE DATABASE ${DB_NAME} OWNER ${DB_USER}'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${DB_NAME}')\\gexec

GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};
SQL

PGPASSWORD="${DB_PASSWORD}" psql -h localhost -U "${DB_USER}" -d "${DB_NAME}" <<'SQL'
CREATE TABLE IF NOT EXISTS students (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  major TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS courses (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS enrolments (
  student_id TEXT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  course_id TEXT NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  PRIMARY KEY (student_id, course_id)
);

INSERT INTO students (id, name, major) VALUES
  ('S1', 'Alice', 'Computer Science'),
  ('S2', 'Ben', 'Information Technology'),
  ('S3', 'Chloe', 'Data Science'),
  ('S4', 'Daniel', 'Cyber Security'),
  ('S5', 'Emma', 'Software Engineering')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name, major = EXCLUDED.major;

INSERT INTO courses (id, name) VALUES
  ('C1', 'Python Programming'),
  ('C2', 'Artificial Intelligence'),
  ('C3', 'Computer Networking')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO enrolments (student_id, course_id) VALUES
  ('S1', 'C1'), ('S1', 'C2'), ('S2', 'C1'), ('S3', 'C2'),
  ('S4', 'C3'), ('S5', 'C1'), ('S5', 'C3')
ON CONFLICT DO NOTHING;
SQL

PGPASSWORD="${DB_PASSWORD}" psql -h localhost -U "${DB_USER}" -d "${DB_NAME}" \
  -c "SELECT current_database(), current_user;"

cp -n .env.example .env
npm install

cat <<'HELP'

This lab uses Drizzle ORM CRUD methods:
- db.insert(students).values()
- db.select().from(students)
- db.update(students).set().where()
- db.delete(students).where()

Run:
npm start
HELP
