import "dotenv/config";
import gremlin from "gremlin";

const { DriverRemoteConnection } = gremlin.driver;
const { Graph } = gremlin.structure;
const __ = gremlin.process.statics;

const endpoint = process.env.GREMLIN_ENDPOINT || "ws://localhost:8182/gremlin";
const connection = new DriverRemoteConnection(endpoint);
const graph = new Graph();
const g = graph.traversal().withRemote(connection);

const students = [
  { id: "S1", name: "Alice", major: "Computer Science" },
  { id: "S2", name: "Ben", major: "Information Technology" },
  { id: "S3", name: "Chloe", major: "Data Science" },
  { id: "S4", name: "Daniel", major: "Cyber Security" },
  { id: "S5", name: "Emma", major: "Software Engineering" }
];

const courses = [
  { id: "C1", name: "Python Programming" },
  { id: "C2", name: "Artificial Intelligence" },
  { id: "C3", name: "Computer Networking" }
];

const enrolments = [
  ["S1", "C1"],
  ["S1", "C2"],
  ["S2", "C1"],
  ["S3", "C2"],
  ["S4", "C3"],
  ["S5", "C1"],
  ["S5", "C3"]
];

async function clearTeachingGraph() {
  // TinkerGraph is used for teaching. We reset our labelled vertices each run.
  await g.V().hasLabel("Student").drop().iterate();
  await g.V().hasLabel("Course").drop().iterate();
  await g.V().hasLabel("Post").drop().iterate();
  await g.V().hasLabel("Tag").drop().iterate();
}

async function createStudentVertex(student) {
  await g
    .addV("Student")
    .property("studentId", student.id)
    .property("name", student.name)
    .property("major", student.major)
    .next();
}

async function createCourseVertex(course) {
  await g
    .addV("Course")
    .property("courseId", course.id)
    .property("name", course.name)
    .next();
}

async function createEnrolmentEdge(studentId, courseId) {
  await g
    .V()
    .has("Student", "studentId", studentId)
    .addE("ENROLLED_IN")
    .to(__.V().has("Course", "courseId", courseId))
    .next();
}

async function seedTeachingGraph() {
  await clearTeachingGraph();

  for (const student of students) {
    await createStudentVertex(student);
  }

  for (const course of courses) {
    await createCourseVertex(course);
  }

  for (const [studentId, courseId] of enrolments) {
    await createEnrolmentEdge(studentId, courseId);
  }
}

async function readStudents() {
  const result = await g
    .V()
    .hasLabel("Student")
    .project("studentId", "name", "major")
    .by("studentId")
    .by("name")
    .by("major")
    .toList();
  return result.sort((a, b) => a.studentId.localeCompare(b.studentId));
}

async function readStudentCourses(studentId) {
  return g
    .V()
    .has("Student", "studentId", studentId)
    .out("ENROLLED_IN")
    .values("name")
    .toList();
}

async function updateStudentMajor(studentId, major) {
  await g
    .V()
    .has("Student", "studentId", studentId)
    .property("major", major)
    .next();
}

async function deleteStudent(studentId) {
  // Dropping a vertex also removes its incident edges in TinkerGraph.
  await g.V().has("Student", "studentId", studentId).drop().iterate();
}

async function printStudents(title) {
  console.log(`\n${title}`);
  console.table(await readStudents());
}

async function run() {
  console.log("Gremlin / TinkerGraph CRUD lab using Node.js gremlin package");
  console.log("Current CRUD method: direct Gremlin traversal API");
  console.log("Connecting to:", endpoint);
  console.log("Make sure Gremlin Server is running before this script starts.");

  console.log("\n0. Seed the teaching graph");
  await seedTeachingGraph();
  await printStudents("Initial students");

  console.log("\n1. Create: add Frank as a new Student vertex");
  await createStudentVertex({
    id: "S6",
    name: "Frank",
    major: "Computer Science"
  });
  await printStudents("After create");

  console.log("\n2. Create edge: connect Frank to Python Programming");
  await createEnrolmentEdge("S6", "C1");
  console.log("Frank's courses:", await readStudentCourses("S6"));

  console.log("\n3. Read: Alice's courses through ENROLLED_IN edges");
  console.log("Alice's courses:", await readStudentCourses("S1"));

  console.log("\n4. Update: change Frank's major");
  await updateStudentMajor("S6", "Artificial Intelligence");
  await printStudents("After update");

  console.log("\n5. Delete: remove Frank so the lab can be rerun");
  await deleteStudent("S6");
  await printStudents("After delete");

  console.log("\nGremlin / TinkerGraph CRUD lab complete.");
}

run()
  .catch((error) => {
    console.error("Gremlin lab failed:", error);
    console.error("Check that Gremlin Server is running at:", endpoint);
    process.exitCode = 1;
  })
  .finally(async () => {
    await connection.close();
  });
