# Database Access in Node - Full Lab Code Pack
Copyright (C) 2026 Dr Shuo Ding

This teaching resource is licensed under the GNU Affero General Public License version 3 or later (AGPL-3.0-or-later). See the `LICENSE` file for details.


This package expands the Week 3 database access material into runnable Ubuntu labs. Each folder prepares a local database service, seeds the class dataset used in the LMS page, and then runs a complete Node.js CRUD demonstration.

## Included labs

| Folder | Database | Node.js data access method | Main learning purpose |
|---|---|---|---|
| `postgresql-pg-direct` | PostgreSQL | Direct `pg` driver | See raw SQL from Node.js. |
| `postgresql-prisma` | PostgreSQL | Prisma ORM | See model-based CRUD with generated client methods. |
| `postgresql-drizzle` | PostgreSQL | Drizzle ORM/query builder | See typed SQL-like query building. |
| `mongodb-driver-direct` | MongoDB | Official MongoDB Node.js driver | See direct document CRUD. |
| `mongodb-prisma` | MongoDB | Prisma ORM | See document CRUD through Prisma models. |
| `gremlin-direct` | TinkerGraph / Gremlin | Gremlin traversal API | See graph CRUD and relationship traversal. |

## Recommended teaching order

1. Start with `postgresql-pg-direct` so students can see real SQL.
2. Run `postgresql-prisma` to compare SQL tables with an ORM model.
3. Run `postgresql-drizzle` to compare ORM style with query-builder style.
4. Run `mongodb-driver-direct` to show document-oriented access.
5. Run `mongodb-prisma` to show how Prisma can also provide structure over documents.
6. Run `gremlin-direct` to show graph traversal thinking.

## Ubuntu workflow

Open Ubuntu Terminal inside the selected folder and run:

```bash
chmod +x setup_ubuntu_*.sh
./setup_ubuntu_*.sh
npm start
```

Each setup script prints:

- which database is being used,
- which Node.js CRUD method is being used,
- how to connect to the database manually,
- useful commands students can copy after connecting,
- how to run the Node.js CRUD demonstration.

## What students should learn from the scripts

The setup scripts are not just installers. They are part of the teaching material.

- They show how a database service is installed or prepared on Ubuntu.
- They show how a classroom user, password and database are created.
- They show how the dataset is seeded in a repeatable way.
- They print manual test commands so students can confirm the database works before running Node.js.
- They prepare the exact environment expected by the matching `index.js`, schema or Prisma files.

Students should read the script output carefully, then compare it with the LMS page explanation and the Node.js code inside the same folder.

## Recommended run pattern in class

For each folder:

1. Run the setup script.
2. Read the printed manual database test command and execute it.
3. Confirm that the service, user and dataset are working.
4. Run `npm start`.
5. Watch the CRUD output in the terminal.
6. Compare the coding style used in that folder:
   - direct driver,
   - ORM,
   - query builder,
   - graph traversal.

For `gremlin-direct`, keep the Gremlin server running in one Ubuntu terminal and run `npm start` in a second terminal.

## Dataset

All labs use the same teaching dataset:

- students,
- courses,
- enrolments or course arrays,
- posts or student-created notes.

The aim is not to make every database look identical. The aim is to show how the same classroom information is represented differently in relational, document, and graph systems.


