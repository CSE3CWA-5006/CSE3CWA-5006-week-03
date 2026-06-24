#!/usr/bin/env bash
set -euo pipefail

# CSE3CWA PostgreSQL CRUD lab setup for Ubuntu only.
# This script does not cover Red Hat, macOS, Windows, or Docker.
# Password 123456 is for a local classroom VM only. Do not use it in production.

DB_NAME="university_db"
DB_USER="university_user"
DB_PASSWORD="123456"

echo "==> Updating Ubuntu packages"
sudo apt update

echo "==> Installing Node.js 24 LTS if node is missing"
if ! command -v node >/dev/null 2>&1; then
  sudo apt install -y curl ca-certificates gnupg
  curl -fsSL https://deb.nodesource.com/setup_24.x | sudo -E bash -
  sudo apt-get install -y nodejs
fi

echo "==> Installing PostgreSQL stable package from Ubuntu repository"
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable --now postgresql

echo "==> Creating PostgreSQL database and classroom user"
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

echo "==> Initialising schema and sample dataset"
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

CREATE TABLE IF NOT EXISTS posts (
  id TEXT PRIMARY KEY,
  author_id TEXT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  post_text TEXT NOT NULL,
  tags TEXT[] NOT NULL DEFAULT '{}'
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
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  major = EXCLUDED.major;

INSERT INTO courses (id, name) VALUES
  ('C1', 'Python Programming'),
  ('C2', 'Artificial Intelligence'),
  ('C3', 'Computer Networking')
ON CONFLICT (id) DO UPDATE SET name = EXCLUDED.name;

INSERT INTO enrolments (student_id, course_id) VALUES
  ('S1', 'C1'),
  ('S1', 'C2'),
  ('S2', 'C1'),
  ('S3', 'C2'),
  ('S4', 'C3'),
  ('S5', 'C1'),
  ('S5', 'C3')
ON CONFLICT DO NOTHING;

INSERT INTO posts (id, author_id, post_text, tags) VALUES
  ('P1', 'S1', 'Python loops finally make sense.', ARRAY['Python']),
  ('P2', 'S1', 'AI needs a lot of data.', ARRAY['AI']),
  ('P3', 'S2', 'I built a small Python calculator.', ARRAY['Python']),
  ('P4', 'S3', 'Neural networks are interesting.', ARRAY['AI']),
  ('P5', 'S4', 'IP addresses are confusing.', ARRAY['Networking']),
  ('P6', 'S5', 'Python is useful for network scripts.', ARRAY['Python', 'Networking'])
ON CONFLICT (id) DO UPDATE SET
  author_id = EXCLUDED.author_id,
  post_text = EXCLUDED.post_text,
  tags = EXCLUDED.tags;
SQL

echo "==> Testing PostgreSQL connection"
PGPASSWORD="${DB_PASSWORD}" psql -h localhost -U "${DB_USER}" -d "${DB_NAME}" \
  -c "SELECT current_database(), current_user;"

echo "==> Useful manual test commands for students"
cat <<'HELP'
# Copy and run these after setup if you want to test PostgreSQL manually:
PGPASSWORD=123456 psql -h localhost -U university_user -d university_db
SELECT * FROM students;
SELECT s.name, c.name AS course
FROM students s
JOIN enrolments e ON e.student_id = s.id
JOIN courses c ON c.id = e.course_id
ORDER BY s.id, c.id;
\q
HELP

echo "==> Installing Node.js dependencies"
cp -n .env.example .env
npm install

echo "==> PostgreSQL lab setup complete"
echo "Node CRUD method used in this lab:"
echo "  Direct PostgreSQL driver: pg"
echo "  CREATE/READ/UPDATE/DELETE: SQL text executed with pool.query()"
echo "Run: npm start"
