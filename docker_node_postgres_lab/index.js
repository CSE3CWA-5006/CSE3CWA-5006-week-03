import "dotenv/config";
import pg from "pg";

const { Pool } = pg;

// -----------------------------------------------------------------------------
// Docker PostgreSQL + Node.js teaching lab
// -----------------------------------------------------------------------------
// PostgreSQL runs inside a Docker container.
// This Node.js program runs on Ubuntu/WSL/your terminal and connects to the
// container through the mapped host port in DATABASE_URL.
//
// The default .env value is:
// DATABASE_URL=postgresql://university_user:123456@localhost:5433/university_db
//
// Why localhost:5433?
// - PostgreSQL uses port 5432 inside the container.
// - Docker maps host port 5433 to container port 5432.
// - Using 5433 avoids conflict with a PostgreSQL server already installed on
//   the student's computer.
// -----------------------------------------------------------------------------

if (!process.env.DATABASE_URL) {
  console.error(
    "DATABASE_URL is missing. Run ./setup_ubuntu_docker_lab.sh first, or copy .env.example to .env."
  );
  process.exit(1);
}

// A Pool manages database connections for us. Even though this small lab only
// runs a few queries, using a Pool reflects common real-world Node.js practice.
const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

// The demo inserts a temporary student with id S6. We delete S6 before and after
// the demo so students can safely run npm start multiple times.
async function resetDemoStudent() {
  await pool.query("DELETE FROM students WHERE id = $1", ["S6"]);
}

// CREATE: use a parameterised INSERT query.
// $1, $2 and $3 are placeholders. Values are supplied separately in the array.
// This is safer than building SQL by joining strings together.
async function createStudent(student) {
  console.log("CREATE method: direct SQL INSERT through pool.query()");
  await pool.query(
    "INSERT INTO students (id, name, major) VALUES ($1, $2, $3)",
    [student.id, student.name, student.major]
  );
}

// READ: retrieve rows from the students table.
async function readStudents() {
  console.log("READ method: direct SQL SELECT through pool.query()");
  const result = await pool.query(
    "SELECT id, name, major FROM students ORDER BY id"
  );
  return result.rows;
}

// UPDATE: change one value in one row.
async function updateStudentMajor(id, major) {
  console.log("UPDATE method: direct SQL UPDATE through pool.query()");
  await pool.query("UPDATE students SET major = $1 WHERE id = $2", [major, id]);
}

// DELETE: remove the temporary row so the lab can be repeated.
async function deleteStudent(id) {
  console.log("DELETE method: direct SQL DELETE through pool.query()");
  await pool.query("DELETE FROM students WHERE id = $1", [id]);
}

// RELATIONAL QUERY: join three tables to show how SQL represents relationships.
async function showStudentCourses() {
  const result = await pool.query(`
    SELECT s.id, s.name AS student, c.name AS course
    FROM students s
    JOIN enrolments e ON e.student_id = s.id
    JOIN courses c ON c.id = e.course_id
    ORDER BY s.id, c.id
  `);
  return result.rows;
}

// ARRAY QUERY: the posts table contains a PostgreSQL text[] column for tags.
// This gives students a small example of data that is less strictly tabular,
// while still being stored in PostgreSQL for this lab.
async function showPostsByTag(tag) {
  const result = await pool.query(
    `
      SELECT p.id, s.name AS author, p.post_text, p.tags
      FROM posts p
      JOIN students s ON s.id = p.author_id
      WHERE $1 = ANY(p.tags)
      ORDER BY p.id
    `,
    [tag]
  );
  return result.rows;
}

async function run() {
  console.log("Docker PostgreSQL CRUD lab using Node.js and the direct pg driver");
  console.log("Current CRUD method: SQL text executed with pool.query()");
  console.log("Database connection configured through DATABASE_URL.");
  console.log("PostgreSQL is running inside Docker. Node.js is running outside the container.");

  console.log("\n1. Existing dataset from the Docker PostgreSQL container");
  console.table(await readStudents());

  console.log("\n2. Create: insert Frank");
  await resetDemoStudent();
  await createStudent({
    id: "S6",
    name: "Frank",
    major: "Computer Science"
  });
  console.table(await readStudents());

  console.log("\n3. Update: change Frank's major");
  await updateStudentMajor("S6", "Artificial Intelligence");
  console.table(await readStudents());

  console.log("\n4. Read relationship data through SQL joins");
  console.table(await showStudentCourses());

  console.log("\n5. Read posts tagged with Python");
  console.table(await showPostsByTag("Python"));

  console.log("\n6. Delete: remove Frank so the lab can be rerun");
  await deleteStudent("S6");
  console.table(await readStudents());

  console.log("\nDocker PostgreSQL CRUD lab complete.");
  console.log("To stop and remove the Docker database environment, run: docker compose down");
}

run()
  .catch((error) => {
    console.error("Docker PostgreSQL lab failed.");
    console.error("Check that Docker is running and that the PostgreSQL container is healthy.");
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await pool.end();
  });
