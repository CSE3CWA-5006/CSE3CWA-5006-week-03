import "dotenv/config";
import { MongoClient } from "mongodb";

if (!process.env.DATABASE_URL) {
  console.error("DATABASE_URL is missing. Run ./setup_ubuntu_mongodb.sh first, or copy .env.example to .env.");
  process.exit(1);
}

const client = new MongoClient(process.env.DATABASE_URL);

const sampleStudent = {
  studentId: "S6",
  name: "Frank",
  major: "Computer Science",
  courses: ["Python Programming"],
  posts: [
    {
      id: "P7",
      text: "I am learning MongoDB CRUD in Node.js.",
      tags: ["MongoDB", "Node.js"]
    }
  ]
};

async function connectCollection() {
  await client.connect();
  const db = client.db("university_db");
  return db.collection("studentProfiles");
}

async function resetDemoStudent(collection) {
  // Keep the lab repeatable by removing Frank before the CRUD demonstration.
  await collection.deleteOne({ studentId: sampleStudent.studentId });
}

async function createStudentProfile(collection, profile) {
  // MongoDB creates a document in a collection.
  await collection.insertOne(profile);
}

async function readStudentProfiles(collection) {
  return collection
    .find({}, { projection: { _id: 0 } })
    .sort({ studentId: 1 })
    .toArray();
}

async function updateStudentMajor(collection, studentId, major) {
  await collection.updateOne({ studentId }, { $set: { major } });
}

async function deleteStudentProfile(collection, studentId) {
  await collection.deleteOne({ studentId });
}

async function findPythonStudents(collection) {
  return collection
    .find(
      { courses: "Python Programming" },
      { projection: { _id: 0, studentId: 1, name: 1, courses: 1 } }
    )
    .sort({ studentId: 1 })
    .toArray();
}

function printProfiles(title, profiles) {
  console.log(`\n${title}`);
  console.table(
    profiles.map((profile) => ({
      studentId: profile.studentId,
      name: profile.name,
      major: profile.major,
      courses: profile.courses.join(", ")
    }))
  );
}

async function run() {
  console.log("MongoDB CRUD lab using the official MongoDB Node.js Driver");
  console.log("Current CRUD method: collection.insertOne/find/updateOne/deleteOne");
  console.log("Connected with:", process.env.DATABASE_URL);

  const collection = await connectCollection();

  printProfiles("1. Existing dataset from setup script", await readStudentProfiles(collection));

  console.log("\n2. Create: insert a new student profile document");
  await resetDemoStudent(collection);
  await createStudentProfile(collection, sampleStudent);
  printProfiles("After create", await readStudentProfiles(collection));

  console.log("\n3. Update: change Frank's major");
  await updateStudentMajor(collection, "S6", "Artificial Intelligence");
  printProfiles("After update", await readStudentProfiles(collection));

  console.log("\n4. Read: find students connected to Python Programming");
  console.table(await findPythonStudents(collection));

  console.log("\n5. Delete: remove Frank so the lab can be rerun");
  await deleteStudentProfile(collection, "S6");
  printProfiles("After delete", await readStudentProfiles(collection));

  console.log("\nMongoDB CRUD lab complete.");
}

run()
  .catch((error) => {
    console.error("MongoDB lab failed:", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await client.close();
  });
