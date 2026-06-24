import { pgTable, text, primaryKey } from "drizzle-orm/pg-core";

export const students = pgTable("students", {
  id: text("id").primaryKey(),
  name: text("name").notNull(),
  major: text("major").notNull()
});

export const courses = pgTable("courses", {
  id: text("id").primaryKey(),
  name: text("name").notNull()
});

export const enrolments = pgTable(
  "enrolments",
  {
    studentId: text("student_id").notNull(),
    courseId: text("course_id").notNull()
  },
  (table) => [primaryKey({ columns: [table.studentId, table.courseId] })]
);
