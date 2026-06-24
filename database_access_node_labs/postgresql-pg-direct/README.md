# PostgreSQL CRUD Lab for Ubuntu

This lab installs PostgreSQL on Ubuntu, creates a classroom database, tests the
connection, and runs CRUD operations from Node.js using the direct `pg` driver.

The classroom database settings match the LMS page:

- Database: `university_db`
- User: `university_user`
- Password: `123456`

The password is for a local classroom VM only. Do not use it in production.

Run on Ubuntu:

```bash
chmod +x setup_ubuntu_postgresql.sh
./setup_ubuntu_postgresql.sh
npm start
```

Manual database test:

```bash
PGPASSWORD=123456 psql -h localhost -U university_user -d university_db
SELECT * FROM students;
\q
```
