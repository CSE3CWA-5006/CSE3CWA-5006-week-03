import "dotenv/config";
import { PrismaClient } from "@prisma/client";

if (!process.env.DATABASE_URL) {
  console.error("DATABASE_URL is missing. Run ./setup_ubuntu_mongodb_prisma.sh first, or copy .env.example to .env.");
  process.exit(1);
}

const prisma = new PrismaClient();

const methodLabel = "Prisma ORM for MongoDB";

const sampleStudent = {
  studentId: "S6",
  name: "Frank",
  major: "Computer Science",
  courses: ["Python Programming"],
  posts: [
    {
      id: "P7",
      text: "I am learning MongoDB CRUD through Prisma.",
      tags: ["MongoDB", "Prisma", "CRUD"]
    }
  ]
};

async function resetDemoStudent() {
  await prisma.studentProfile.deleteMany({
    where: { studentId: sampleStudent.studentId }
  });
}

async function createStudentProfile(profile) {
  console.log("\nCREATE with prisma.studentProfile.create()");
  return prisma.studentProfile.create({ data: profile });
}

async function readStudentProfiles() {
  console.log("\nREAD with prisma.studentProfile.findMany()");
  return prisma.studentProfile.findMany({
    orderBy: { studentId: "asc" }
  });
}

async function updateStudentMajor(studentId, newMajor) {
  console.log("\nUPDATE with prisma.studentProfile.update()");
  return prisma.studentProfile.update({
    where: { studentId },
    data: { major: newMajor }
  });
}

async function deleteStudentProfile(studentId) {
  console.log("\nDELETE with prisma.studentProfile.delete()");
  return prisma.studentProfile.delete({
    where: { studentId }
  });
}

async function findPythonStudents() {
  console.log("\nFILTER with Prisma array query: courses has 'Python Programming'");
  return prisma.studentProfile.findMany({
    where: {
      courses: { has: "Python Programming" }
    },
    orderBy: { studentId: "asc" }
  });
}

async function main() {
  console.log("MongoDB CRUD lab using Prisma ORM");
  console.log(`Current CRUD method: ${methodLabel}`);
  console.log("Dataset: the same class dataset used in the LMS page.");
  console.log("Connected with:", process.env.DATABASE_URL);

  console.log("\n1. Reset the demo student so the lab can be rerun cleanly");
  await resetDemoStudent();

  console.log("\n2. Create: insert Frank as a new student profile document");
  const created = await createStudentProfile(sampleStudent);
  console.log(created);

  console.log("\n3. Update: change Frank's major");
  const updated = await updateStudentMajor(sampleStudent.studentId, "Artificial Intelligence");
  console.log(updated);

  console.log("\n4. Read: list all student profile documents");
  const allStudents = await readStudentProfiles();
  console.table(
    allStudents.map((student) => ({
      studentId: student.studentId,
      name: student.name,
      major: student.major,
      courseCount: student.courses.length,
      postCount: student.posts.length
    }))
  );

  console.log("\n5. Read: filter students whose courses include Python Programming");
  const pythonStudents = await findPythonStudents();
  console.table(
    pythonStudents.map((student) => ({
      studentId: student.studentId,
      name: student.name,
      courses: student.courses.join(", ")
    }))
  );

  console.log("\n6. Delete: remove Frank so the lab can be rerun");
  const deleted = await deleteStudentProfile(sampleStudent.studentId);
  console.log(`Deleted ${deleted.studentId}: ${deleted.name}`);
}

main()
  .catch((error) => {
    console.error("CRUD demo failed.");
    console.error(error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
