# Docker PostgreSQL + Node.js Direct Driver Lab

Copyright (C) 2026 Dr Shuo Ding  
Licence: AGPL-3.0-or-later

## Purpose

This optional CSE3CWA/CSE5006 lab runs PostgreSQL in Docker while the Node.js 24 application runs directly on Ubuntu. It uses the same PostgreSQL schema and seed data as Week 3 Lab 1:

- `students(id, name, email, major, created_at)`
- `courses(id, title)`
- `enrolments(student_id, course_id)`
- `posts(id, student_id, topic, content, created_at)`

Node.js connects to PostgreSQL through `127.0.0.1:5433`. PostgreSQL remains on its normal internal container port `5432`.

## Supported environment

- A fresh Ubuntu 22.04 or Ubuntu 24.04 VM
- Internet access
- A user account with `sudo`
- About 2 GB of free disk space

The Ubuntu setup script intentionally stops on WSL. Windows students should use Docker Desktop instructions separately rather than installing a second Docker Engine inside WSL.

## One-command setup and test

Extract the ZIP, open a terminal in this folder, and run:

```bash
chmod +x setup_ubuntu_docker_lab.sh test_lab.sh stop_lab.sh reset_lab.sh
./setup_ubuntu_docker_lab.sh
```

The script will:

1. Check Ubuntu 22.04/24.04.
2. Install Docker Engine from Docker's official Ubuntu repository when needed.
3. Install and verify Node.js 24.
4. Check for a conflicting container name or occupied port 5433.
5. Start the pinned `postgres:17.10-bookworm` image.
6. Reset and seed the exact Lab 1 dataset.
7. Validate that the npm lock uses only public registry URLs and fixed versions.
8. Run `npm ci`.
9. Verify the schema and seed data.
10. Run the complete parameterised CRUD demonstration.
11. Verify that the database returned to its five-student baseline.

The complete output is saved to `docker_lab_test.log`.

## Run again

```bash
npm start
```

Run the full test again:

```bash
./test_lab.sh
```

## Inspect PostgreSQL

```bash
docker exec -it cwa-postgres-lab   psql -U university_user -d university_db
```

Useful SQL:

```sql
\dt
SELECT id, name, email, major FROM students ORDER BY id;
SELECT id, title FROM courses ORDER BY id;
SELECT s.name, c.title
FROM students AS s
JOIN enrolments AS e ON e.student_id = s.id
JOIN courses AS c ON c.id = e.course_id
ORDER BY s.id, c.id;
\q
```

Use `sudo docker ...` when Docker permissions have not yet taken effect for the current login session.

## Stop or reset

Stop the container but keep the named database volume:

```bash
./stop_lab.sh
```

Remove the container and database volume for a completely clean reset:

```bash
./reset_lab.sh
```

Then rebuild:

```bash
./setup_ubuntu_docker_lab.sh
```

## Fixed versions

- Node.js: major version 24
- PostgreSQL image: `postgres:17.10-bookworm`
- `pg`: `8.22.0`
- `dotenv`: `17.4.2`

No dependency uses `latest`, and `package-lock.json` contains public `registry.npmjs.org` URLs only.

## Safety

The SQL script drops and recreates only the four classroom tables in `university_db`. Use this project only in the dedicated course VM or another disposable teaching environment. Do not point its `.env` file at a production database.
