/*
 * Week 3 Lab V2 teaching code.
 * Copyright (C) 2026 Dr Shuo Ding <shuoding@outlook.com>.
 * Licensed under AGPL-3.0-or-later. Copies and modified versions must retain this notice.
 */
import 'dotenv/config';
import pg from 'pg';

const { Pool } = pg;
const pool = new Pool({
  connectionString: process.env.POSTGRES_URL,
});

async function showStudents(label) {
  const result = await pool.query(
    'SELECT id, name, email, major, created_at FROM students ORDER BY id'
  );
  console.log(`\n${label}`);
  console.table(result.rows);
}

async function main() {
  console.log('PostgreSQL direct driver CRUD demo');
  console.log('Access method: raw SQL text executed with pool.query().');
  console.log('CREATE note: this demo uses INSERT ... ON CONFLICT so repeated runs refresh S6 instead of failing.');
  console.log('Teaching tip: comment out the blocks you do not want to run, then run npm run start:postgres again.');

  await showStudents('READ 1: students before changes');

  // CREATE: insert one new student. ON CONFLICT keeps the demo repeatable.
  await pool.query(
    `INSERT INTO students (id, name, email, major)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (id) DO UPDATE
     SET name = EXCLUDED.name, email = EXCLUDED.email, major = EXCLUDED.major`,
    ['S6', 'Grace Huang', 'grace.huang@example.edu', 'Cloud Computing']
  );
  await showStudents('CREATE: added or refreshed S6');

  // READ: filter students by major so students see a WHERE clause.
  const filtered = await pool.query(
    'SELECT id, name, major FROM students WHERE major ILIKE $1 ORDER BY id',
    ['%cloud%']
  );
  console.log('\nREAD 2: students whose major contains "cloud"');
  console.table(filtered.rows);

  // UPDATE: change one field for one student.
  await pool.query(
    'UPDATE students SET major = $1 WHERE id = $2',
    ['Cloud-Based Web Applications', 'S6']
  );
  await showStudents('UPDATE: changed S6 major');

  // DELETE: remove the demo row so the database returns to the teaching baseline.
  await pool.query('DELETE FROM students WHERE id = $1', ['S6']);
  await showStudents('DELETE: removed S6');
}

main()
  .catch((error) => {
    console.error('PostgreSQL demo failed:', error.message);
    process.exitCode = 1;
  })
  .finally(async () => {
    await pool.end();
  });
