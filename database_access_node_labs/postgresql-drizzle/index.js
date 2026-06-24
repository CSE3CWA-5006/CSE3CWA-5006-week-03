import "dotenv/config";
import pg from "pg";
import { drizzle } from "drizzle-orm/node-postgres";
import { eq, asc } from "drizzle-orm";
import { students, courses, enrolments } from "./schema.js";

const { Pool } = pg;

if (!process.env.DATABASE_URL) {
  console.error("DATABASE_URL is missing. Run ./setup_ubuntu_postgresql_drizzle.sh first, or copy .env.example to .env.");
  process.exit(1);
}

const pool = new Pool({
  connectionString: process.env.DATABASE_URL
});

const db = drizzle(pool);

async function resetDemoStudent() {
  await db.delete(students).where(eq(students.id, "S6"));
}

async function createStudent(student) {
  // Drizzle insert() maps to INSERT while keeping a SQL-like shape.
  await db.insert(students).values(student);
}

async function readStudents() {
  return db.select().from(students).orderBy(asc(students.id));
}

async function updateStudentMajor(id, major) {
  await db.update(students).set({ major }).where(eq(students.id, id));
}

async function deleteStudent(id) {
  await db.delete(students).where(eq(students.id, id));
}

async function readStudentCourses() {
  return db
    .select({
      studentId: students.id,
      student: students.name,
      course: courses.name
    })
    .from(students)
    .innerJoin(enrolments, eq(enrolments.studentId, students.id))
    .innerJoin(courses, eq(courses.id, enrolments.courseId))
    .orderBy(asc(students.id), asc(courses.id));
}

async function run() {
  console.log("PostgreSQL CRUD lab using Drizzle ORM");
  console.log("Current CRUD method: db.insert/select/update/delete");

  console.log("\n1. Existing dataset");
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

  console.log("\n4. Read relationship data through Drizzle joins");
  console.table(await readStudentCourses());

  console.log("\n5. Delete: remove Frank");
  await deleteStudent("S6");
  console.table(await readStudents());

  console.log("\nDrizzle PostgreSQL CRUD lab complete.");
}

run()
  .catch((error) => {
    console.error("Drizzle PostgreSQL lab failed:", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await pool.end();
  });
