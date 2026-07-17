/*
 * Week 3 Lab V2 teaching code.
 * Copyright (C) 2026 Dr Shuo Ding <shuoding@outlook.com>.
 * Licensed under AGPL-3.0-or-later. Copies and modified versions must retain this notice.
 */
import 'dotenv/config';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function showStudents(label) {
  const students = await prisma.student.findMany({
    orderBy: { id: 'asc' },
  });
  console.log(`\n${label}`);
  console.table(students);
}

async function main() {
  console.log('PostgreSQL Prisma ORM CRUD demo');
  console.log('Access method: prisma.student.upsert/findMany/update/delete.');
  console.log('CREATE note: this demo uses upsert so repeated runs refresh S7 instead of failing.');
  console.log('Teaching tip: Prisma maps the students table to the Student model in prisma/schema.prisma.');

  await showStudents('READ 1: students before changes');

  // CREATE: create a row through the Student model. upsert keeps the demo repeatable.
  await prisma.student.upsert({
    where: { id: 'S7' },
    update: {
      name: 'Henry Wilson',
      email: 'henry.wilson@example.edu',
      major: 'Web Engineering',
    },
    create: {
      id: 'S7',
      name: 'Henry Wilson',
      email: 'henry.wilson@example.edu',
      major: 'Web Engineering',
    },
  });
  await showStudents('CREATE: added or refreshed S7 through Prisma');

  // READ: use Prisma filtering instead of writing a SQL WHERE clause.
  const webStudents = await prisma.student.findMany({
    where: {
      major: {
        contains: 'Web',
        mode: 'insensitive',
      },
    },
    orderBy: { id: 'asc' },
  });
  console.log('\nREAD 2: students whose major contains "Web"');
  console.table(webStudents);

  // UPDATE: change a field using Prisma's update method.
  await prisma.student.update({
    where: { id: 'S7' },
    data: { major: 'Cloud and Web Engineering' },
  });
  await showStudents('UPDATE: changed S7 major through Prisma');

  // DELETE: remove the demo row so the table returns to the teaching baseline.
  await prisma.student.delete({
    where: { id: 'S7' },
  });
  await showStudents('DELETE: removed S7 through Prisma');
}

main()
  .catch((error) => {
    console.error('Prisma demo failed:', error.message);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
