# MongoDB Prisma CRUD Lab

This lab uses MongoDB for document data and Prisma ORM as the Node.js data access method.

## What this lab demonstrates

- Installing MongoDB on Ubuntu.
- Creating a MongoDB teaching user with password `123456`.
- Seeding the same class dataset used in the LMS page.
- Connecting Node.js to MongoDB through Prisma.
- Running complete CREATE, READ, UPDATE, DELETE operations.
- Querying array fields in a document model.
- Comparing document CRUD with the same class dataset used in the LMS page.

## Run on Ubuntu

```bash
chmod +x setup_ubuntu_mongodb_prisma.sh
./setup_ubuntu_mongodb_prisma.sh
npm start
```

## Manual MongoDB test

```bash
mongosh "mongodb://university_user:123456@localhost:27017/university_db?authSource=admin"
db.studentProfiles.find({}, { _id: 0, studentId: 1, name: 1, major: 1 }).sort({ studentId: 1 }).pretty()
exit
```

## Method used

This folder uses Prisma ORM:

- CREATE: `prisma.studentProfile.create()`
- READ: `prisma.studentProfile.findMany()`
- UPDATE: `prisma.studentProfile.update()`
- DELETE: `prisma.studentProfile.delete()`

Use this lab when you want students to see MongoDB through a structured ORM-style API.
