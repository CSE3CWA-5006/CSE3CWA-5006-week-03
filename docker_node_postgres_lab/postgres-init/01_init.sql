-- -----------------------------------------------------------------------------
-- PostgreSQL initialisation script for the Docker lab.
-- Docker's official postgres image runs files in /docker-entrypoint-initdb.d
-- when the database volume is created for the first time.
--
-- The setup script also re-applies this file manually after the container starts.
-- Therefore, this file is written to be idempotent: it can be run more than once
-- without creating duplicate rows or breaking the database.
-- -----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS students (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  major TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS courses (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL
);

-- A small posts table is included so students can inspect a text[] array column.
-- The main CRUD demonstration focuses on students, courses and enrolments.
CREATE TABLE IF NOT EXISTS posts (
  id TEXT PRIMARY KEY,
  author_id TEXT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  post_text TEXT NOT NULL,
  tags TEXT[] NOT NULL DEFAULT '{}'
);

-- This linking table models a many-to-many relationship:
-- one student can enrol in many courses, and one course can contain many students.
CREATE TABLE IF NOT EXISTS enrolments (
  student_id TEXT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
  course_id TEXT NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  PRIMARY KEY (student_id, course_id)
);

INSERT INTO students (id, name, major) VALUES
  ('S1', 'Alice', 'Computer Science'),
  ('S2', 'Ben', 'Information Technology'),
  ('S3', 'Chloe', 'Data Science'),
  ('S4', 'Daniel', 'Cyber Security'),
  ('S5', 'Emma', 'Software Engineering')
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  major = EXCLUDED.major;

INSERT INTO courses (id, name) VALUES
  ('C1', 'Python Programming'),
  ('C2', 'Artificial Intelligence'),
  ('C3', 'Computer Networking')
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name;

INSERT INTO enrolments (student_id, course_id) VALUES
  ('S1', 'C1'),
  ('S1', 'C2'),
  ('S2', 'C1'),
  ('S3', 'C2'),
  ('S4', 'C3'),
  ('S5', 'C1'),
  ('S5', 'C3')
ON CONFLICT DO NOTHING;

INSERT INTO posts (id, author_id, post_text, tags) VALUES
  ('P1', 'S1', 'Python loops finally make sense.', ARRAY['Python']),
  ('P2', 'S1', 'AI needs a lot of data.', ARRAY['AI']),
  ('P3', 'S2', 'I built a small Python calculator.', ARRAY['Python']),
  ('P4', 'S3', 'Neural networks are interesting.', ARRAY['AI']),
  ('P5', 'S4', 'IP addresses are confusing.', ARRAY['Networking']),
  ('P6', 'S5', 'Python is useful for network scripts.', ARRAY['Python', 'Networking'])
ON CONFLICT (id) DO UPDATE SET
  author_id = EXCLUDED.author_id,
  post_text = EXCLUDED.post_text,
  tags = EXCLUDED.tags;
