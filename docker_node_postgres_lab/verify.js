/*
CSE3CWA/CSE5006 Docker PostgreSQL verification script
Copyright (C) 2026 Dr Shuo Ding
SPDX-License-Identifier: AGPL-3.0-or-later
*/

import 'dotenv/config';
import pg from 'pg';

const { Pool } = pg;

if (!process.env.DATABASE_URL) {
  throw new Error('DATABASE_URL is missing. Copy .env.example to .env first.');
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 2,
  connectionTimeoutMillis: 5000
});

const expectedColumns = {
  students: ['id', 'name', 'email', 'major', 'created_at'],
  courses: ['id', 'title'],
  enrolments: ['student_id', 'course_id'],
  posts: ['id', 'student_id', 'topic', 'content', 'created_at']
};

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

try {
  const connection = await pool.query(
    'SELECT current_database() AS database, current_user AS database_user'
  );
  console.table(connection.rows);

  const counts = await pool.query(`
    SELECT
      (SELECT COUNT(*)::int FROM students) AS students,
      (SELECT COUNT(*)::int FROM courses) AS courses,
      (SELECT COUNT(*)::int FROM enrolments) AS enrolments,
      (SELECT COUNT(*)::int FROM posts) AS posts
  `);

  const row = counts.rows[0];
  assert(row.students === 5, `Expected 5 students, found ${row.students}.`);
  assert(row.courses === 3, `Expected 3 courses, found ${row.courses}.`);
  assert(row.enrolments === 6, `Expected 6 enrolments, found ${row.enrolments}.`);
  assert(row.posts === 6, `Expected 6 posts, found ${row.posts}.`);

  const columnsResult = await pool.query(`
    SELECT table_name, column_name, ordinal_position
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = ANY($1::text[])
    ORDER BY table_name, ordinal_position
  `, [Object.keys(expectedColumns)]);

  const actualColumns = {};
  for (const item of columnsResult.rows) {
    actualColumns[item.table_name] ??= [];
    actualColumns[item.table_name].push(item.column_name);
  }

  for (const [table, columns] of Object.entries(expectedColumns)) {
    assert(
      JSON.stringify(actualColumns[table]) === JSON.stringify(columns),
      `${table} columns are not aligned with Lab 1. Expected ${columns.join(', ')}; found ${(actualColumns[table] || []).join(', ')}.`
    );
  }

  const alice = await pool.query(`
    SELECT id, name, email, major
    FROM students
    WHERE id = 'S1'
  `);
  assert(alice.rowCount === 1, 'S1 is missing.');
  assert(alice.rows[0].name === 'Alice Chen', 'S1 name is not aligned with Lab 1.');
  assert(alice.rows[0].email === 'alice.chen@example.edu', 'S1 email is not aligned with Lab 1.');

  console.table(counts.rows);
  console.log('Verification passed: schema, seed data, connection and row counts match Lab 1.');
} finally {
  await pool.end();
}
