# Presence Lab — Implementation Plan

Concrete, ordered steps for building the project described in `CURRICULUM.md`. Each step lists what to build, the success check, and the failure drill ("break it") that earns the lesson.

Estimated effort per milestone is a calm weekend (6–10 hrs). If a milestone takes much longer, the prior one was probably skipped.

## Conventions

- Branch per milestone: `m1-single-node`, `m2-two-nodes`, etc. Merge to `main` only when the success check passes.
- Every milestone ends with a `JOURNAL.md` entry — even if nothing dramatic happened.
- Do not skip the failure drill. It is the point.

---

## M0 — Bootstrap (≈ 1 hr)

Already done by `mix phx.new presence_lab`. Tasks:

- [ ] `mix deps.get`
- [ ] `mix ecto.create`
- [ ] `mix phx.server` — confirm the default page loads at `http://localhost:4000`.
- [ ] Read `lib/presence_lab/application.ex` and `lib/presence_lab_web/endpoint.ex`. Note every supervised child and what would happen if it crashed.
- [ ] Initialise `JOURNAL.md` with the headings `Date`, `What I tried`, `What I expected`, `What happened`, `What I learned`.

**Success check:** you can name every process started by `Application.start/2` without looking at the file.

---

## M1 — Single-node app (≈ 8 hrs)

### Build

- [ ] User schema (`id`, `username`, `password_hash`). Use `bcrypt_elixir`. No email, no reset flow — out of scope.
- [ ] Sign-up + log-in LiveViews. Cookie session.
- [ ] `Room` schema (`id`, `name`, `inserted_at`).
- [ ] Room index + show LiveViews. "Create room" form.
- [ ] `RoomChannel` (or LiveView equivalent) — join, list members currently in the LiveView mount.
- [ ] Use `Phoenix.Presence` (single-node, defaults) to track who is in each room.
- [ ] Per-room chat input. Messages are in-memory only for now (state in the LiveView process is fine).

### Success check

Open two browsers, log in as different users, join the same room. Both see each other in the presence list and each other's messages.

### Failure drill

- [ ] Crash the LiveView process (`Process.exit(self(), :kill)` from a debug button). Confirm the user reconnects cleanly.
- [ ] Stop the server mid-chat. Confirm messages from before the restart are gone (this is expected — fix is M6).

### Journal prompt

What did `Phoenix.Presence` give you for free? What would you have to build yourself if it didn't exist?

---

## M2 — Two nodes, no Docker (≈ 6 hrs)

### Build

- [ ] Run two iex sessions: `iex --sname a -S mix phx.server` (port 4000) and `iex --sname b -S mix phx.server` (port 4001 — set via `PORT=4001`).
- [ ] `Node.connect(:"a@<host>")` from node `b`. Confirm `Node.list/0`.
- [ ] Replace LiveView-local presence with `:pg` groups keyed by `{:room, room_id}`.
- [ ] Broadcast chat messages with `Phoenix.PubSub` (default `:pg2`/`:pg` adapter — already cluster-aware).
- [ ] User on node A and user on node B in the same room must see each other.

### Success check

Two browser windows pointed at port 4000 and port 4001 respectively, same room — presence and chat work across both.

### Failure drill

- [ ] `Node.disconnect(:"a@<host>")` from node B while a chat is open. What happens to the presence list on each side? How long until they notice?
- [ ] Kill node A entirely (`Ctrl+\` for SIGQUIT). What does node B see? When does node A drop out of the presence list?
- [ ] Re-start node A. Does it rejoin? Are old presences resurrected or gone?

### Journal prompt

Distributed Erlang needs three things to work: name, cookie, network. Which one did you get wrong first? How did the error manifest?

---

## M3 — Docker Compose (≈ 8 hrs)

### Build

- [ ] Multi-stage `Dockerfile` producing a `mix release`. Use `elixir:1.18-otp-27-alpine` for build, `alpine:3.20` for runtime.
- [ ] `rel/env.sh.eex` setting `RELEASE_NODE=presence@$(hostname -f)` and `RELEASE_COOKIE` from env.
- [ ] `docker-compose.yml`:
  - Postgres service.
  - Two `app` services with different hostnames (`node1`, `node2`), shared cookie via env.
  - A shared network so they can resolve each other.
- [ ] `libcluster` with the `Gossip` strategy (UDP multicast inside the Docker network) — simplest thing that works for Compose.

### Success check

`docker compose up --scale app=2`. Both nodes form a cluster within ~5 seconds of boot. Browser → either node, presence syncs.

### Failure drill

- [ ] Set the wrong cookie on one node. Read the actual error message. Is it useful? (Spoiler: barely.)
- [ ] Block port 4369 (EPMD) with an iptables rule inside one container. What changes?
- [ ] `docker stop` one node mid-chat. How long until the other node notices?

### Journal prompt

Why is the cookie a shared secret rather than a public identifier? What does it actually protect?

---

## M4 — k3d + libcluster on Kubernetes (≈ 10 hrs)

### Build

- [ ] `k3d cluster create lab --agents 2 --port "8080:80@loadbalancer"`.
- [ ] Push the image to k3d's local registry (or `k3d image import`).
- [ ] Manifests in `k8s/`:
  - `namespace.yaml`
  - `postgres.yaml` (StatefulSet + Service — fine for learning, not for prod).
  - `app-headless-service.yaml` — `clusterIP: None`, exposes a port like `epmd`.
  - `app-statefulset.yaml` — 3 replicas, mounts the cookie from a Secret.
  - `app-ingress.yaml` (or just NodePort if simpler).
- [ ] `libcluster` with `Cluster.Strategy.Kubernetes.DNS`, querying the headless service.
- [ ] Liveness probe = `/health` returning 200 only if the app's own supervisor tree is up.
- [ ] Readiness probe = the above **and** `length(Node.list()) >= 1` (so traffic doesn't hit a freshly-booted lonely node).

### Success check

- `kubectl get pods` shows 3 `presence-lab-N` pods.
- IEx into one: `kubectl exec -it presence-lab-0 -- bin/presence_lab remote` → `Node.list/0` returns the other two.
- Browser through the ingress, presence works across pods.

### Failure drill

- [ ] `kubectl delete pod presence-lab-1` mid-chat. What does the user on that pod see? What about users on other pods who were in a room with them?
- [ ] `kubectl rollout restart statefulset presence-lab`. Time how long until all sockets are back. What changes if you increase `terminationGracePeriodSeconds`?
- [ ] Scale down to 1 replica, then back up to 3. Does the new pod join? In how many seconds?

### Journal prompt

Why a StatefulSet, not a Deployment, for a stateless web app? (Hint: stateless to your *users* is not the same as stateless to *Erlang*.)

---

## M5 — Observability (≈ 8 hrs)

### Build

- [ ] Add `opentelemetry`, `opentelemetry_phoenix`, `opentelemetry_ecto`. Export to a local Tempo or Jaeger running in the cluster.
- [ ] Add `prom_ex` (or `telemetry_metrics_prometheus_core`) with the Phoenix, Ecto, BEAM, and Application plugins.
- [ ] Deploy Prometheus + Grafana to the cluster (the `kube-prometheus-stack` Helm chart is fine, even if Helm is otherwise out of scope).
- [ ] One Grafana dashboard with at least: request rate + p95 latency, BEAM run queue length, total process count, memory by type, message queue length of the top 5 processes.

### Success check

You can answer "is the app healthy?" by glancing at one dashboard, without `kubectl logs`.

### Failure drill

- [ ] Start a hot loop in one pod: `spawn(fn -> Stream.repeatedly(fn -> :ok end) |> Stream.run() end)`. Which metric moves first?
- [ ] Leak ETS: `:ets.new(:leaky, [:public, :named_table])` and insert 1M rows. Which metric tells you?
- [ ] Pile up a message queue: a slow `GenServer` with a fast producer. Find it on the dashboard before reading the code.

### Journal prompt

Which one of {logs, metrics, traces} did you reach for first for each failure? Was it the right one?

---

## M6 — Durable + replicated state (≈ 10 hrs)

### Build

- [ ] Move chat history to Postgres: `Message` schema, ordered by `inserted_at`, indexed on `room_id`.
- [ ] On room join, load the last 50 messages from Postgres.
- [ ] Keep presence in `:pg` / `Phoenix.Tracker` (ephemeral, in-memory, replicated).
- [ ] **Optional spike:** try Khepri (or Mnesia, if you can stomach it) for a "currently-typing" indicator. Then write down in the journal why you would not ship Mnesia for this in production.

### Success check

Restart all pods. Re-join a room. Last 50 messages reappear. Presence rebuilds from scratch (which is correct — presence is ephemeral).

### Failure drill

- [ ] Induce a netsplit: `kubectl exec presence-lab-0 -- iptables -A INPUT -s <pod-1-ip> -j DROP` (or use a NetworkPolicy). Hold for 30s, then heal.
- [ ] During the split: send messages on each side. After heal: who saw what? Is the order consistent? Was anything lost?

### Journal prompt

Name three places state lives in this app now. For each: what happens to it on pod restart, on netsplit, on cluster restart?

---

## M7 — Graceful shutdown + backpressure (≈ 6 hrs)

### Build

- [ ] Catch `SIGTERM` (Erlang gives you this via `:init.stop/0` hooks or by trapping in a dedicated supervisor child).
- [ ] Drain sequence: stop the Phoenix endpoint listener (no new sockets), broadcast a "draining" message to connected clients, wait up to N seconds for in-flight work, then exit.
- [ ] `terminationGracePeriodSeconds: 30` in the StatefulSet to give the drain time to run.
- [ ] Bounded mailbox somewhere fan-out can overflow — pick one place and use `GenStage` or a manual back-pressure check.

### Success check

`kubectl delete pod presence-lab-1` mid-traffic. Users connected to that pod see "reconnecting…", then reconnect to another pod within 2s, and see no missing messages.

### Failure drill

- [ ] Flood a room with a script (5000 messages/sec from one client). Where does memory grow? Does the bounded queue actually bound?
- [ ] Set `terminationGracePeriodSeconds: 1` and repeat the delete-pod test. Compare.

### Journal prompt

What is the difference between a *graceful* and a *fast* shutdown for this app? When would you choose each?

---

## M8 (optional) — Multi-region (≈ 10 hrs)

### Build

- [ ] Fly.io deploy: `fly launch`, `fly scale count 2 --region lhr,fra`. Or two Hetzner k3s clusters in different regions joined via WireGuard.
- [ ] Measure cross-region PubSub latency. Add it to the Grafana dashboard.
- [ ] Decide a policy for rooms: pin to a region? Allow cross-region? Replicate eagerly or lazily?

### Failure drill

- [ ] Partition the regions with a firewall rule. Observe what happens on each side. How would you decide which side keeps writing?

### Journal prompt

You have now met CAP in person. Which letter did you give up, and what did the user notice?

---

## Definition of done for the whole project

- All milestones merged to `main`.
- `JOURNAL.md` has at least 15 entries.
- The `k8s/` manifests apply cleanly on a fresh `k3d` cluster from a clean checkout.
- The README has a "what I learned" section that is the *only* part of this repo you would share with a future employer.
