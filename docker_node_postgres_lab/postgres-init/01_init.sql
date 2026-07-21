\set ON_ERROR_STOP on

-- CSE3CWA/CSE5006 Week 3 teaching dataset.
-- This script intentionally resets only the four lab tables so every run starts
-- from the same known state. Do not use this reset script on a production database.

DROP TABLE IF EXISTS posts;
DROP TABLE IF EXISTS enrolments;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS courses;

CREATE TABLE students (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  major TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE courses (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL
);

CREATE TABLE enrolments (
  student_id TEXT REFERENCES students(id) ON DELETE CASCADE,
  course_id TEXT REFERENCES courses(id) ON DELETE CASCADE,
  PRIMARY KEY (student_id, course_id)
);

CREATE TABLE posts (
  id TEXT PRIMARY KEY,
  student_id TEXT REFERENCES students(id) ON DELETE CASCADE,
  topic TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

INSERT INTO students (id, name, email, major) VALUES
  ('S1', 'Alice Chen', 'alice.chen@example.edu', 'Computer Science'),
  ('S2', 'Ben Taylor', 'ben.taylor@example.edu', 'Information Technology'),
  ('S3', 'Chloe Wang', 'chloe.wang@example.edu', 'Data Science'),
  ('S4', 'Daniel Smith', 'daniel.smith@example.edu', 'Cybersecurity'),
  ('S5', 'Emma Li', 'emma.li@example.edu', 'Software Engineering');

INSERT INTO courses (id, title) VALUES
  ('C1', 'Python Programming'),
  ('C2', 'Artificial Intelligence'),
  ('C3', 'Computer Networking');

INSERT INTO enrolments (student_id, course_id) VALUES
  ('S1', 'C1'),
  ('S1', 'C2'),
  ('S2', 'C2'),
  ('S3', 'C3'),
  ('S5', 'C1'),
  ('S5', 'C3');

INSERT INTO posts (id, student_id, topic, content) VALUES
  ('P1', 'S1', 'Python', 'Alice shared a Python practice note.'),
  ('P2', 'S1', 'AI', 'Alice asked a question about AI tools.'),
  ('P3', 'S2', 'AI', 'Ben posted about model evaluation.'),
  ('P4', 'S3', 'Networking', 'Chloe discussed packet routing.'),
  ('P5', 'S4', 'Security', 'Daniel posted about password hashing.'),
  ('P6', 'S5', 'Python/Networking', 'Emma connected Python scripts with networking.');

SELECT 'students' AS table_name, COUNT(*) AS row_count FROM students
UNION ALL
SELECT 'courses', COUNT(*) FROM courses
UNION ALL
SELECT 'enrolments', COUNT(*) FROM enrolments
UNION ALL
SELECT 'posts', COUNT(*) FROM posts
ORDER BY table_name;
