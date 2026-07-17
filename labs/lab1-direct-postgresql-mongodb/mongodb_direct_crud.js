/*
 * Week 3 Lab V2 teaching code.
 * Copyright (C) 2026 Dr Shuo Ding <shuoding@outlook.com>.
 * Licensed under AGPL-3.0-or-later. Copies and modified versions must retain this notice.
 */
import 'dotenv/config';
import { MongoClient } from 'mongodb';

const client = new MongoClient(process.env.MONGODB_URL);

async function showProfiles(collection, label) {
  const profiles = await collection
    .find({}, { projection: { _id: 0, studentId: 1, name: 1, major: 1, courses: 1 } })
    .sort({ studentId: 1 })
    .toArray();
  console.log(`\n${label}`);
  console.dir(profiles, { depth: null });
}

async function main() {
  console.log('MongoDB direct driver CRUD demo');
  console.log('Access method: official MongoDB driver with find, updateOne with upsert, updateOne and deleteOne.');
  console.log('CREATE note: this demo uses updateOne(..., { upsert: true }) so repeated runs refresh S6 instead of failing.');
  console.log('Teaching tip: comment out the blocks you do not want to run, then run npm run start:mongo again.');

  await client.connect();
  const db = client.db('university_db');
  const profiles = db.collection('studentProfiles');

  await showProfiles(profiles, 'READ 1: profiles before changes');

  // CREATE: insert one document. updateOne with upsert keeps the demo repeatable.
  await profiles.updateOne(
    { studentId: 'S6' },
    {
      $set: {
        studentId: 'S6',
        name: 'Grace Huang',
        email: 'grace.huang@example.edu',
        major: 'Cloud Computing',
        courses: ['Cloud-Based Web Applications'],
        posts: [],
      },
    },
    { upsert: true }
  );
  await showProfiles(profiles, 'CREATE: added or refreshed S6 document');

  // READ: find documents where the courses array contains a value.
  const pythonStudents = await profiles
    .find(
      { courses: 'Python Programming' },
      { projection: { _id: 0, studentId: 1, name: 1, courses: 1 } }
    )
    .toArray();
  console.log('\nREAD 2: profiles with Python Programming in the courses array');
  console.dir(pythonStudents, { depth: null });

  // UPDATE: change a field and add a value to an array.
  await profiles.updateOne(
    { studentId: 'S6' },
    {
      $set: { major: 'Cloud-Based Web Applications' },
      $addToSet: { courses: 'Database Systems' },
    }
  );
  await showProfiles(profiles, 'UPDATE: changed S6 major and added a course');

  // DELETE: remove the demo document so the collection returns to the teaching baseline.
  await profiles.deleteOne({ studentId: 'S6' });
  await showProfiles(profiles, 'DELETE: removed S6 document');
}

main()
  .catch((error) => {
    console.error('MongoDB demo failed:', error.message);
    process.exitCode = 1;
  })
  .finally(async () => {
    await client.close();
  });
