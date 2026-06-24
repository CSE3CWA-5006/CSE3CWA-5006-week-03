# TinkerGraph / Gremlin CRUD Lab for Ubuntu

This lab installs Java and Apache TinkerPop Gremlin Server on Ubuntu, then runs
CRUD operations from Node.js using the `gremlin` package.

Important:

- This is an Ubuntu-only classroom setup.
- It does not cover Red Hat, macOS, Windows, or Docker.
- TinkerGraph is an in-memory teaching graph.
- The local Gremlin Server setup does not use a database username or password.
- Keep it for local learning only.

Run setup:

```bash
chmod +x setup_ubuntu_tinkergraph.sh
./setup_ubuntu_tinkergraph.sh
```

Start Gremlin Server in a separate terminal:

```bash
cd ~/apache-tinkerpop-gremlin-server-3.7.4
./bin/gremlin-server.sh conf/gremlin-server-modern.yaml
```

Manual database test in another terminal:

```bash
cd ~/apache-tinkerpop-gremlin-server-3.7.4
./bin/gremlin.sh
:remote connect tinkerpop.server conf/remote.yaml
:remote console
g.V().count()
g.V().hasLabel('person').values('name')
```

Run the Node.js CRUD lab:

```bash
npm start
```
