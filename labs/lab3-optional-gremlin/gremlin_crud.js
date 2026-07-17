/*
 * Week 3 Lab V2 teaching code.
 * Copyright (C) 2026 Dr Shuo Ding <shuoding@outlook.com>.
 * Licensed under AGPL-3.0-or-later. Copies and modified versions must retain this notice.
 */
import gremlin from 'gremlin';

const { driver } = gremlin;

const client = new driver.Client('ws://localhost:8182/gremlin', {
  traversalSource: 'g',
});

async function submit(query, bindings = {}) {
  return client.submit(query, bindings);
}

async function showStudents(label) {
  const result = await submit("g.V().hasLabel('student').has('lab','week3').valueMap(true)");
  console.log(`\n${label}`);
  console.dir(result.toArray(), { depth: null });
}

async function main() {
  console.log('TinkerGraph / Gremlin CRUD demo');
  console.log('Access method: direct Gremlin traversal strings sent to Gremlin Server.');
  console.log('Teaching tip: this optional lab stores data as vertices and edges, not rows or documents.');

  // Clear only the teaching vertices created by this demo.
  await submit("g.V().has('lab','week3').drop()");

  // CREATE: add student and course vertices.
  await submit("g.addV('student').property('lab','week3').property('studentId','S1').property('name','Alice Chen')");
  await submit("g.addV('student').property('lab','week3').property('studentId','S5').property('name','Emma Li')");
  await submit("g.addV('course').property('lab','week3').property('courseId','C1').property('title','Python Programming')");
  await submit("g.addV('topic').property('lab','week3').property('name','Python')");

  // CREATE RELATIONSHIPS: students enrol in the same course.
  await submit(`
    g.V().has('student','studentId','S1').as('alice').
      V().has('student','studentId','S5').as('emma').
      V().has('course','courseId','C1').as('pythonCourse').
      addE('ENROLLED_IN').from('alice').to('pythonCourse').
      addE('ENROLLED_IN').from('emma').to('pythonCourse')
  `);
  await showStudents('CREATE: added Alice, Emma and a shared Python course');

  // READ: discover who shares a course with Alice.
  const sharedCourse = await submit(`
    g.V().has('student','studentId','S1').as('alice').
      out('ENROLLED_IN').
      in('ENROLLED_IN').
      hasLabel('student').
      where(neq('alice')).
      dedup().
      values('name')
  `);
  console.log('\nREAD: students connected to Alice through an enrolled course');
  console.log(sharedCourse.toArray());

  // UPDATE: change one vertex property.
  await submit("g.V().has('student','studentId','S5').property('name','Emma Li-Wilson')");
  await showStudents('UPDATE: changed Emma name');

  // DELETE: delete the teaching graph so repeated runs start cleanly.
  await submit("g.V().has('lab','week3').drop()");
  await showStudents('DELETE: removed Week 3 teaching graph');
}

main()
  .catch((error) => {
    console.error('Gremlin demo failed:', error.message);
    console.error('Check that Gremlin Server is running on ws://localhost:8182/gremlin.');
    globalThis.process.exitCode = 1;
  })
  .finally(async () => {
    await client.close();
  });
