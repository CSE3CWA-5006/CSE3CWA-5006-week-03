import "dotenv/config";
import { PrismaClient } from "@prisma/client";

if (!process.env.DATABASE_URL) {
  console.error("DATABASE_URL is missing. Run ./setup_ubuntu_postgresql_prisma.sh first, or copy .env.example to .env.");
  process.exit(1);
}

const prisma = new PrismaClient();

async function resetDemoStudent() {
  await prisma.student.deleteMany({ where: { id: "S6" } });
}

async function createStudent(student) {
  // Prisma create() maps to an INSERT into the students table.
  return prisma.student.create({ data: student });
}

async function readStudents() {
  return prisma.student.findMany({ orderBy: { id: "asc" } });
}

async function updateStudentMajor(id, major) {
  return prisma.student.update({
    where: { id },
    data: { major }
  });
}

async function deleteStudent(id) {
  return prisma.student.delete({ where: { id } });
}

async function readStudentCourses() {
  return prisma.enrolment.findMany({
    orderBy: [{ studentId: "asc" }, { courseId: "asc" }],
    include: {
      student: true,
      course: true
    }
  });
}

async function run() {
  console.log("PostgreSQL CRUD lab using Prisma ORM");
  console.log("Current CRUD method: prisma.student.create/findMany/update/delete");

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

  console.log("\n4. Read relationship data through Prisma relations");
  console.table(
    (await readStudentCourses()).map((row) => ({
      studentId: row.studentId,
      student: row.student.name,
      course: row.course.name
    }))
  );

  console.log("\n5. Delete: remove Frank");
  await deleteStudent("S6");
  console.table(await readStudents());

  console.log("\nPrisma PostgreSQL CRUD lab complete.");
}

run()
  .catch((error) => {
    console.error("Prisma PostgreSQL lab failed:", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
