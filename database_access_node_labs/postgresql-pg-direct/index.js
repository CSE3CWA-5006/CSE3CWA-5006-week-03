import "dotenv/config";
import pg from "pg";

const { Pool } = pg;

if (!process.env.DATABASE_URL) {
  console.error("DATABASE_URL is missing. Run ./setup_ubuntu_postgresql.sh first, or copy .env.example to .env.");
  process.exit(1);
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

const studentsSeed = [
  { id: "S1", name: "Alice", major: "Computer Science" },
  { id: "S2", name: "Ben", major: "Information Technology" },
  { id: "S3", name: "Chloe", major: "Data Science" },
  { id: "S4", name: "Daniel", major: "Cyber Security" },
  { id: "S5", name: "Emma", major: "Software Engineering" }
];

async function resetDemoStudent() {
  // Keep the lab repeatable by removing Frank before the CRUD demonstration.
  await pool.query("DELETE FROM students WHERE id = $1", ["S6"]);
}

async function createStudent(student) {
  // Direct SQL uses parameter placeholders ($1, $2, $3) to avoid SQL injection.
  await pool.query(
    "INSERT INTO students (id, name, major) VALUES ($1, $2, $3)",
    [student.id, student.name, student.major]
  );
}

async function readStudents() {
  const result = await pool.query(
    "SELECT id, name, major FROM students ORDER BY id"
  );
  return result.rows;
}

async function updateStudentMajor(id, major) {
  await pool.query("UPDATE students SET major = $1 WHERE id = $2", [major, id]);
}

async function deleteStudent(id) {
  await pool.query("DELETE FROM students WHERE id = $1", [id]);
}

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

async function run() {
  console.log("PostgreSQL CRUD lab using direct pg driver");
  console.log("Current CRUD method: SQL text executed with pool.query()");
  console.log("Connected with:", process.env.DATABASE_URL);

  console.log("\n1. Existing dataset from setup script");
  console.table(await readStudents());

  console.log("\n2. Create: insert a new student");
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

  console.log("\n5. Delete: remove Frank so the lab can be rerun");
  await deleteStudent("S6");
  console.table(await readStudents());

  console.log("\nPostgreSQL CRUD lab complete.");
}

run()
  .catch((error) => {
    console.error("PostgreSQL lab failed:", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await pool.end();
  });
