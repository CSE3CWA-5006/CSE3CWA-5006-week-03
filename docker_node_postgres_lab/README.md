# Docker PostgreSQL Node.js Lab

Copyright (C) 2026 Dr Shuo Ding

This teaching resource is licensed under the GNU Affero General Public License version 3 or later (AGPL-3.0-or-later). See the `LICENSE` file for details.

## Overview

This optional lab runs PostgreSQL in Docker and runs Node.js manually on Ubuntu, WSL Ubuntu, or another terminal that has Node.js and Docker available.

Students use this lab to understand how a database runtime can be packaged as a container while the application code continues to run outside the container. The Node.js application connects to PostgreSQL through the mapped host port `localhost:5433`.

## Why this lab exists

In the earlier PostgreSQL direct-driver lab, students installed PostgreSQL directly on Ubuntu. This version uses Docker to package the database runtime. The Node.js program still runs outside the database container and connects to PostgreSQL through `localhost:5433`.

This makes the database environment easier to create, stop, remove, and recreate. It also demonstrates a common professional development pattern: the application code runs on the developer machine, while service dependencies such as PostgreSQL run in containers.

## Files

- `docker-compose.yml` defines the PostgreSQL container, database name, user, password, health check, volume, and port mapping.
- `postgres-init/01_init.sql` creates and seeds the teaching database.
- `setup_ubuntu_docker_lab.sh` installs required Ubuntu tools where needed and starts the lab.
- `index.js` runs the Node.js CRUD and query demonstration using the direct `pg` driver.
- `.env.example` provides the `DATABASE_URL` used by Node.js.
- `package.json` defines the Node.js dependencies and the `npm start` command.
- `LICENSE` contains the AGPL-3.0 license text.

## Ubuntu setup and installation

Use these steps on Ubuntu or WSL Ubuntu.

### 1. Enter the lab folder

If you downloaded the lab as a zip file, first unzip it and enter the folder:

```bash
unzip docker_node_postgres_lab.zip
cd docker_node_postgres_lab
```

If the folder has already been extracted, just enter the folder:

```bash
cd docker_node_postgres_lab
```

### 2. Make the setup script executable

```bash
chmod +x setup_ubuntu_docker_lab.sh
```

### 3. Run the setup script

```bash
./setup_ubuntu_docker_lab.sh
```

The setup script will:

1. Check whether Docker is available.
2. Install Docker Engine and the Docker Compose plugin on Ubuntu if required.
3. Start the PostgreSQL container using `docker compose up -d`.
4. Wait until the PostgreSQL health check reports that the database is ready.
5. Copy `.env.example` to `.env` if `.env` does not already exist.
6. Install Node.js dependencies with `npm install`.
7. Print useful commands for inspecting and stopping the lab.

If your user account does not yet have Docker permissions, the script may use `sudo docker compose`. After Docker is installed, you may need to log out and log back in before running Docker without `sudo`.

## Run on Ubuntu or WSL Ubuntu

After setup finishes, run the Node.js application:

```bash
npm start
```

The application should connect to the PostgreSQL container and demonstrate basic database operations, including reading students, creating a new student, updating data, deleting data, and querying posts.

## Run when Docker and Node.js are already installed

If Docker, Docker Compose, and Node.js are already installed, you can run the lab manually:

```bash
cd docker_node_postgres_lab
cp -n .env.example .env
npm install
docker compose up -d
npm start
```

## Manual database inspection

To open the PostgreSQL shell inside the running container:

```bash
docker exec -it cwa-postgres-lab psql -U university_user -d university_db
```

Useful `psql` commands:

```sql
\dt
SELECT * FROM students;
SELECT * FROM posts;
SELECT s.name, c.name AS course
FROM students s
JOIN enrolments e ON e.student_id = s.id
JOIN courses c ON c.id = e.course_id
ORDER BY s.id, c.id;
\q
```

## Expected learning outcomes

After completing this lab, students should be able to:

- Explain why Docker is useful for packaging service dependencies such as PostgreSQL.
- Describe the difference between the host port `5433` and the container port `5432`.
- Start and stop a PostgreSQL database using Docker Compose.
- Connect a Node.js application to a containerised PostgreSQL database.
- Inspect database tables from inside the PostgreSQL container.
- Explain how `.env`, `docker-compose.yml`, and `index.js` work together.

## Stop the Docker environment

```bash
docker compose down
```

If your user account does not yet have Docker permissions, the setup script may use `sudo docker compose`. In that case:

```bash
sudo docker compose down
```

## Clean reset

This removes the PostgreSQL volume and all stored data:

```bash
docker compose down -v
```

Use this only when you want to recreate the database from the SQL initialisation files.

## Port choice

The container uses PostgreSQL port `5432` internally. The host uses port `5433` so this lab does not conflict with a PostgreSQL server that may already be installed directly on the computer.

## Licence

Copyright (C) 2026 Dr Shuo Ding

This teaching resource is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License as published by the Free Software Foundation, either version 3 of the License, or, at your option, any later version.

This teaching resource is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY, without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
