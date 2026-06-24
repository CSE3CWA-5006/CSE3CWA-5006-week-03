# PostgreSQL Drizzle CRUD Lab

This lab uses Drizzle ORM with PostgreSQL.

Run on Ubuntu:

```bash
chmod +x setup_ubuntu_postgresql_drizzle.sh
./setup_ubuntu_postgresql_drizzle.sh
npm start
```

The program demonstrates:

- `db.insert(students).values()`
- `db.select().from(students)`
- `db.update(students).set().where()`
- `db.delete(students).where()`

Database:

- `university_db`
- `university_user`
- `123456`

The password is for a local classroom VM only.
