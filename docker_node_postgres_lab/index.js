/*
CSE3CWA/CSE5006 Docker PostgreSQL direct-driver lab
Copyright (C) 2026 Dr Shuo Ding
SPDX-License-Identifier: AGPL-3.0-or-later
*/

import 'dotenv/config';
import pg from 'pg';

const { Pool } = pg;

if (!process.env.DATABASE_URL) {
  console.error('DATABASE_URL is missing. Copy .env.example to .env first.');
  process.exit(1);
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 5,
  connectionTimeoutMillis: 5000,
  idleTimeoutMillis: 10000
});

pool.on('error', (error) => {
  console.error('Unexpected PostgreSQL pool error:', error.message);
});

function heading(title) {
  console.log(`\n=== ${title} ===`);
}

async function main() {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    heading('1. READ the Lab 1 students');
    const initialStudents = await client.query(`
      SELECT id, name, email, major, created_at
      FROM students
      ORDER BY id
    `);
    console.table(initialStudents.rows);

    heading('2. CREATE S6 with a repeatable parameterised upsert');
    const created = await client.query(
      `INSERT INTO students (id, name, email, major)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (id) DO UPDATE SET
         name = EXCLUDED.name,
         email = EXCLUDED.email,
         major = EXCLUDED.major
       RETURNING id, name, email, major, created_at`,
      ['S6', 'Grace Huang', 'grace.huang@example.edu', 'Web Development']
    );
    console.table(created.rows);

    heading('3. UPDATE S6');
    const updated = await client.query(
      `UPDATE students
       SET major = $1
       WHERE id = $2
       RETURNING id, name, email, major, created_at`,
      ['Cloud Computing', 'S6']
    );
    console.table(updated.rows);

    heading('4. READ relational data with a JOIN');
    const enrolments = await client.query(`
      SELECT
        s.id AS student_id,
        s.name AS student_name,
        c.id AS course_id,
        c.title AS course_title
      FROM students AS s
      JOIN enrolments AS e ON e.student_id = s.id
      JOIN courses AS c ON c.id = e.course_id
      ORDER BY s.id, c.id
    `);
    console.table(enrolments.rows);

    heading('5. READ posts whose topic contains Python');
    const posts = await client.query(
      `SELECT
         p.id,
         s.name AS student_name,
         p.topic,
         p.content,
         p.created_at
       FROM posts AS p
       JOIN students AS s ON s.id = p.student_id
       WHERE p.topic ILIKE $1
       ORDER BY p.id`,
      ['%Python%']
    );
    console.table(posts.rows);

    heading('6. DELETE the temporary S6 record');
    const deleted = await client.query(
      `DELETE FROM students
       WHERE id = $1
       RETURNING id, name`,
      ['S6']
    );
    console.table(deleted.rows);

    const finalCheck = await client.query(
      `SELECT COUNT(*)::int AS student_count,
              COUNT(*) FILTER (WHERE id = 'S6')::int AS temporary_student_count
       FROM students`
    );

    if (finalCheck.rows[0].student_count !== 5 ||
        finalCheck.rows[0].temporary_student_count !== 0) {
      throw new Error('Final student data did not return to the five-row Lab 1 baseline.');
    }

    await client.query('COMMIT');
    heading('Completed successfully');
    console.log('The transaction committed and the database returned to the Lab 1 baseline.');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

try {
  await main();
} catch (error) {
  console.error('Lab failed:', error.message);
  process.exitCode = 1;
} finally {
  await pool.end();
}
