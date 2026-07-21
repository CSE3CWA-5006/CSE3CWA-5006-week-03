# Validation Record

The final project was checked before packaging.

Passed checks:

- All four shell scripts pass `bash -n`.
- `index.js` and `verify.js` pass `node --check`.
- `package.json` and `package-lock.json` parse as valid JSON.
- `package.json` and the lock root have identical fixed dependencies and engines.
- `npm install --package-lock-only --offline` accepted the lock and did not modify it.
- Every lock `resolved` URL uses `https://registry.npmjs.org/`.
- No dependency uses `latest`; no OpenAI/internal registry URL remains.
- `docker-compose.yml` parses as YAML and uses `postgres:17.10-bookworm` with `127.0.0.1:5433:5432`.
- The SQL schema and seed data match Week 3 Lab 1.
- A mock PostgreSQL driver executed the complete `verify.js` and `index.js` control flow successfully, including BEGIN, parameterised create/update/read/delete, COMMIT and pool shutdown.

Runtime note:

- The current build environment does not provide a Docker daemon, so the real container was not started here. On Ubuntu, `setup_ubuntu_docker_lab.sh` performs the real Docker pull, health check, SQL execution, `npm ci`, database verification, CRUD run and final baseline verification in one run.
