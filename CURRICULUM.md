# Presence Lab — Curriculum

A self-directed curriculum for learning distributed Elixir, Docker, and Kubernetes by building a multi-node presence service end-to-end.

## Learning goals

By the end you should be able to:

- Reason about what BEAM distribution gives you (and what it doesn't).
- Cluster Elixir nodes on a laptop, in Docker Compose, and on Kubernetes.
- Debug distributed failures: split brain, netsplits, slow nodes, stuck processes.
- Operate the system: rolling deploys, observability, graceful shutdown, backpressure.
- Make principled trade-offs between consistency, availability, and operational complexity.

## The project

A Phoenix app where users join "rooms" and see who is online — across every node in the cluster. Simple enough to finish; only interesting *because* it is distributed.

Core features:
- Authenticated users (cookie-based — keep it simple).
- Rooms with a member list that updates in real time.
- Presence (who is online right now, on which node).
- Per-room chat (last 50 messages, replicated).

## Method

**Build → break → observe → predict → fix.** For every milestone:

1. Make the happy path work. Resist over-engineering.
2. Deliberately break it (`docker kill`, `kubectl delete pod`, `tc qdisc` for latency, fill the disk).
3. Read the logs and traces *before* fixing it.
4. Write down what you predict will fix it.
5. Apply the fix and verify your prediction.

Keep a `JOURNAL.md` with one entry per incident: what broke, what you expected, what actually happened, what you changed. After ~20 entries your distributed-systems intuition becomes calibrated to your own wrong assumptions — which is the only kind of intuition that helps under pressure.

## Modules

### Module 0 — Foundations (1 evening)
- Read `lib/presence_lab/application.ex`. Understand the supervision tree before touching anything.
- Watch Sasa Juric's *The Soul of Erlang and Elixir*.
- Outcome: explain `:permanent` vs `:transient` vs `:temporary` restarts without looking it up.

### Module 1 — Single-node Phoenix (weekend)
- Auth (basic, cookie sessions).
- Rooms CRUD + room channel.
- LiveView presence list per room.
- Outcome: it works. Tests cover the channel join path.

### Module 2 — Two nodes on your laptop, no Docker (weekend)
- Start two `iex --sname a` / `iex --sname b` nodes, manually `Node.connect/1`.
- Use `:pg` for cross-node presence groups.
- Use `Phoenix.PubSub` to broadcast chat messages.
- **Break it:** kill one node, observe what happens to processes registered with `:global`, to linked processes, to monitored ones.
- Outcome: you can articulate what `Node.disconnect/1` does to in-flight messages.

### Module 3 — Docker Compose, two nodes (weekend)
- Multi-stage Dockerfile producing a release (`mix release`).
- `docker-compose.yml` with two app nodes + Postgres.
- Erlang cookie via env var (note: this is fine for learning; production wants secrets).
- EPMD vs `inet_dist_listen_min/max` — pick one and understand why.
- **Break it:** wrong cookie, blocked EPMD port, asymmetric DNS.
- Outcome: you can explain why distributed Erlang needs three things — node name, cookie, network reachability.

### Module 4 — k3d + libcluster (weekend)
- Local k3d cluster (`k3d cluster create lab --agents 2`).
- StatefulSet (not Deployment — stable hostnames matter for `node@host`).
- `libcluster` with the `Kubernetes.DNS` strategy + headless service.
- Readiness/liveness probes that mean something (don't just hit `/`).
- **Break it:** rolling deploy while holding open WebSockets. What does the user see? What did you lose?
- Outcome: nodes form a cluster automatically on pod boot; you can do a rolling deploy without dropping all sockets.

### Module 5 — Observability before you need it (weekend)
- OpenTelemetry from Phoenix + Ecto, exported to a local Tempo or Jaeger.
- Prometheus + Grafana for VM metrics (run queue, memory by type, message queue lengths).
- A dashboard that would actually help you at 11pm.
- **Break it:** hot-loop a process, leak ETS, pile up a message queue. Watch which signal shows up first.
- Outcome: you know which metric matters when and why.

### Module 6 — State that lives somewhere (weekend)
- Postgres for durable data (rooms, users, message history).
- `:pg` or Phoenix.Tracker for ephemeral state (presence).
- Try Mnesia or Khepri for replicated in-memory state. Then write down why you would not use Mnesia for this in production.
- **Break it:** netsplit between two nodes for 30 seconds, then heal. Who wins?
- Outcome: you can name three places state can live and the trade-offs of each.

### Module 7 — Graceful shutdown & backpressure (weekend)
- `SIGTERM` handler that drains: stop accepting new connections, finish in-flight work, then exit.
- Phoenix endpoint draining + a shutdown hook on your channel.
- GenStage or simple bounded queues somewhere chat fan-out can overflow.
- **Break it:** flood a room with messages from a script. Where does memory grow?
- Outcome: a `kubectl delete pod` mid-traffic loses zero messages for connected users.

### Module 8 — Multi-region (optional weekend)
- Two Hetzner regions, or Fly.io with `fly scale count 2 --region lhr,fra`.
- Now latency is real. Cross-region PubSub costs milliseconds.
- **Break it:** partition the regions (firewall rule). Watch CAP stop being theoretical.
- Outcome: you can explain why someone might pin a room to a region.

## When you are done

You should have:
- A working presence service on Kubernetes you could demo.
- A `JOURNAL.md` with 15–25 incident write-ups.
- An opinion on at least three things (libcluster strategies, where presence state belongs, what to put in your shutdown hook). Opinions, not memorised facts.

## Reading list (use alongside, not before)

- *Designing for Scalability with Erlang/OTP* — Cesarini & Vinoski. The only book where distribution is the subject, not the appendix.
- *Adopting Erlang* (free online) — deployment & releases chapters.
- *The Soul of Erlang and Elixir* — Sasa Juric talk. Watch twice: before Module 1 and after Module 4.
- Source code: `libcluster`, `Horde`, `Phoenix.PubSub`, `Phoenix.Tracker`. Small, well-written, real.

## Anti-goals

Things this curriculum deliberately skips so you can finish it:

- A production-grade auth system. Use cookies and a single user table.
- Helm charts. Plain manifests are clearer for learning.
- A real CI/CD pipeline. `docker build && kubectl apply` is enough.
- Multi-tenancy, billing, RBAC. Not the lesson.
