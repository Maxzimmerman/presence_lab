# Presence Lab — Curriculum

A self-directed curriculum for learning distributed Elixir, Docker, Kubernetes, AWS, and system design by building a multi-node presence service end-to-end.

## Learning goals

By the end you should be able to:

- Reason about what BEAM distribution gives you (and what it doesn't).
- Cluster Elixir nodes on a laptop, in Docker Compose, and on Kubernetes.
- Debug distributed failures: split brain, netsplits, slow nodes, stuck processes.
- Operate the system: rolling deploys, observability, graceful shutdown, backpressure.
- Make principled trade-offs between consistency, availability, and operational complexity.
- Design a system on paper — data model, failure modes, rough numbers — before writing code, and defend the design to someone senior.
- Navigate the AWS pieces a real Elixir deployment touches: EKS, ECR, S3, SQS, IAM.

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

**Design before you build.** From Module 3 onward, start each module with a one-page design doc in `designs/` *before* touching code:

- What are you building and what can go wrong? (failure modes, not features)
- Where does state live and who owns it?
- Back-of-envelope numbers: how many rooms, messages/sec, bytes per presence entry, what breaks first at 10× load?
- One decision you considered and rejected, and why.

Then, at the end of the module, annotate the doc with what the design got wrong. The gap between your paper design and what actually happened is the system-design skill — senior engineers are the ones whose gap has shrunk. This is the same muscle as writing an RFC at work; the format is deliberately similar.

## Modules

### Module 0 — Foundations (1 evening)
- Read `lib/presence_lab/application.ex`. Understand the supervision tree before touching anything.
- Read the [`Supervisor` module docs](https://hexdocs.pm/elixir/Supervisor.html) — especially the sections on child specifications and restart values.
- Watch Sasa Juric's *The Soul of Erlang and Elixir* (the *why* of supervision; the restart-option details come from the docs above).
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
- `libcluster` with the `Cluster.Strategy.Kubernetes` strategy (queries the K8s API for pods by label selector — same setup as mosaic; already wired in `config/runtime.exs`, needs `RELEASE_NAME`, `K8S_NODE_SELECTOR`, `K8S_NAMESPACE` env vars plus RBAC to list pods).
- Compare with the `Kubernetes.DNS` strategy + headless service: what does the API strategy buy you, and what extra permissions does it cost?
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

### Module 8 — Queues and background jobs (weekend)

The async backbone of most production Elixir systems (including the one you work on).

- Add a feature that needs async work: notify offline room members by "email" (write to a table; the point is the pipeline, not SMTP).
- Oban for DB-backed jobs: retries, uniqueness, a scheduled job that prunes old messages.
- SQS via LocalStack + Broadway for a stream-shaped problem: fan chat messages into an SQS queue, consume with a Broadway pipeline, batch-write analytics counts.
- Understand *why* two tools: Oban when the job belongs to your transaction (enqueue-with-insert, exactly-once-ish); SQS/Broadway when producers are external or volume is high (at-least-once, so consumers must be idempotent).
- Dead-letter queues: configure one, then earn a message in it.
- **Break it:** make a consumer crash on one poison message. Watch it retry, then land in the DLQ. Then make a non-idempotent consumer double-process a message and observe the corruption.
- Outcome: you can explain at-least-once vs exactly-once delivery, and why idempotency keys exist, from an incident you caused.

### Module 9 — AWS for real (weekend + teardown discipline)

Everything so far ran locally. Real AWS adds IAM, cost, and the console — learn them on a system you already understand.

- Push your image to ECR. Deploy the app to EKS (smallest node group you can) *or* — cheaper — keep k3d locally and use real AWS only for the managed services.
- S3: store chat-export files. Presigned URLs for download.
- Swap LocalStack SQS for real SQS. Notice what changed: IAM credentials, not code.
- IAM roles for service accounts (IRSA): give the pod, not a hardcoded key, permission to read the queue. This is the single most work-relevant thing in this module.
- Secrets: Erlang cookie and DB password from AWS Secrets Manager, not env-var plaintext.
- **Break it:** revoke the IAM permission and watch how the failure presents (hint: badly, and far from the cause).
- **Tear it down the same weekend.** Set a billing alarm at $10 before you create anything. The skill of leaving no orphaned resources *is* part of the module.
- Outcome: you can trace a request's permissions from pod → service account → IAM role → policy, and your bill is under $10.

### Module 10 — System design reps (ongoing, 1–2 hours each)

The build modules give you calibration; this module gives you range. Classic system-design exercises, done on paper, using what you now know. One page each, in `designs/`, same format as your module design docs.

- Design a **webhook delivery system** (at-least-once, retries with backoff, per-endpoint ordering, a customer whose endpoint is down for 6 hours). You built the pieces in Module 8.
- Design a **shipment tracking page**: 50k drivers sending GPS pings every 10s, customers watching live ETAs. Where does presence-style ephemeral state end and durable state begin? (This is your day job — design it from scratch anyway.)
- Design **rate limiting** for a public API: per-tenant, distributed across nodes. Token bucket where? What do you give up if it's per-node only?
- Design **read scaling** for room history: when does Postgres need a cache in front, what gets invalidated when, and what breaks with a read replica lagging 2 seconds?
- For each: numbers first (QPS, storage/day, fan-out factor), then data model, then failure modes, then the one thing you'd cut to ship in a month.
- Outcome: you can fill a whiteboard for 45 minutes on a system you've never built, anchored in things you *have* built.

### Module 11 — Multi-region (optional weekend)
- Two Hetzner regions, or Fly.io with `fly scale count 2 --region lhr,fra`.
- Now latency is real. Cross-region PubSub costs milliseconds.
- **Break it:** partition the regions (firewall rule). Watch CAP stop being theoretical.
- Outcome: you can explain why someone might pin a room to a region.

## When you are done

You should have:
- A working presence service on Kubernetes you could demo.
- A `JOURNAL.md` with 15–25 incident write-ups.
- A `designs/` folder with ~10 one-page design docs, each annotated with what reality disagreed with.
- An opinion on at least three things (libcluster strategies, where presence state belongs, what to put in your shutdown hook). Opinions, not memorised facts.

## Reading list (use alongside, not before)

- *Designing for Scalability with Erlang/OTP* — Cesarini & Vinoski. The only book where distribution is the subject, not the appendix.
- *Designing Data-Intensive Applications* — Kleppmann. The system-design book. Read chapters 5 (replication), 8 (trouble with distributed systems), and 11 (stream processing) alongside Modules 6 and 8; the rest as reference.
- *Adopting Erlang* (free online) — deployment & releases chapters.
- *The Soul of Erlang and Elixir* — Sasa Juric talk. Watch twice: before Module 1 and after Module 4.
- Source code: `libcluster`, `Horde`, `Phoenix.PubSub`, `Phoenix.Tracker`, `broadway`, `oban`. Small, well-written, real.
- Your own codebase at work: the RFCs in `docs/rfcs` and the DB-partition-maintenance doc are worked examples of the design-doc habit this curriculum practices.

## Anti-goals

Things this curriculum deliberately skips so you can finish it:

- A production-grade auth system. Use cookies and a single user table.
- Helm charts. Plain manifests are clearer for learning. (Work uses Helm — read the chart there *after* Module 4, when the manifests underneath will make sense.)
- A real CI/CD pipeline. `docker build && kubectl apply` is enough. (Same trick: read the GitHub Actions → ECR → EKS pipeline at work after Module 9.)
- Multi-tenancy, billing, RBAC. Not the lesson.
- AWS breadth. Nine services deep beats ninety services shallow; EKS, ECR, S3, SQS, IAM, Secrets Manager cover what your job touches.
