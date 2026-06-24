# MongoDB CRUD Lab for Ubuntu

This lab installs MongoDB Community Edition on Ubuntu, creates a classroom user,
enables authentication, initialises a document dataset, and runs CRUD operations
from Node.js using the official MongoDB Node.js Driver.

The classroom database settings match the LMS page:

- Database: `university_db`
- User: `university_user`
- Password: `123456`

The password is for a local classroom VM only. Do not use it in production.

Run on Ubuntu 24.04 LTS:

```bash
chmod +x setup_ubuntu_mongodb.sh
./setup_ubuntu_mongodb.sh
npm start
```

Manual database test:

```bash
mongosh "mongodb://university_user:123456@localhost:27017/university_db?authSource=admin"
db.studentProfiles.find({}, { _id: 0, studentId: 1, name: 1, major: 1 }).pretty()
exit
```
