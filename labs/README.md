# Week 3 Lab V2: Database Access in Node.js

Copyright (C) 2026 Dr Shuo Ding <shuoding@outlook.com>.  
Released under the GNU Affero General Public License version 3 or later (AGPL-3.0-or-later). Copies, modified versions and redistributed versions must retain the original author attribution and licence notice. See `LICENSE`.

This folder contains three separate lab activities. Each lab has its own LMS HTML page. Students should follow the page step by step instead of running an automatic setup script.

## Safety note

Run these labs only inside a dedicated course Ubuntu VM. The commands install database services, change local configuration files, and reset teaching data. Do not run them on a production server or on a machine that already stores important PostgreSQL or MongoDB data.

## Runtime requirement

- Ubuntu 22.04 or Ubuntu 24.04
- Node.js 22.11.0 or newer. Node.js 22 LTS is recommended, but newer stable versions such as Node.js 24 can also be used if already installed.
- npm
- Visual Studio Code is recommended. If the `code` command is not available in Ubuntu Terminal, open VS Code manually and use **File > Open Folder**.
- Internet access for installing packages

## What students should do

1. Open the LMS page for the lab.
2. Copy one command block at a time into Ubuntu Terminal.
3. Read what the command does before running the next command.
4. Open the JavaScript file in VS Code.
5. Run the program once.
6. Comment out or edit one CRUD block.
7. Run the program again and compare the terminal output.

The direct dependency versions are pinned in each `package.json` and locked in each `package-lock.json`. Use `npm ci` in the lab folders so every student installs the tested dependency tree.

## Lab pages

- `lab1_manual_postgresql_mongodb_lms.html`
  - Install PostgreSQL and MongoDB.
  - Create the teaching database manually.
  - Test CRUD manually in `psql` and `mongosh`.
  - Run Node.js direct-driver CRUD.

- `lab2_postgresql_prisma_lms.html`
  - Use the PostgreSQL database from Lab 1.
  - Learn why an ORM is useful.
  - Install Prisma with fixed package versions.
  - Generate Prisma Client.
  - Run and edit Prisma CRUD code.

- `lab3_optional_gremlin_lms.html`
  - Optional for CSE5006.
  - Install Java and Gremlin Server.
  - Start Gremlin Server in one terminal.
  - Run Node.js Gremlin CRUD in another terminal.


For an unattended check, use:

```bash
NO_PAUSE=1 bash run_all_check_ubuntu.sh
```

## Teaching database account

The local teaching account is:

- database: `university_db`
- user: `university_user`
- password: `123456`

This password is for a local teaching VM only. Do not use it in production or cloud deployment.
