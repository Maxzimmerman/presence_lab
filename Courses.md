# Courses

Courses run *alongside* the project, never before it. The project (see `CURRICULUM.md`)
is the spine; each course starts right before the module that needs it. One course at
a time.

## The four courses (Udemy)

1. **Kubernetes for the Absolute Beginners — Hands-on** (Mumshad Mannambeth)
2. **The Complete Microservices & Event-Driven Architecture**
3. **Software Architecture & Design of Modern Large Scale Systems**
4. **Ultimate AWS Certified Solutions Architect Associate 2026** (Stéphane Maarek)

## When to take what

| When | Project work | Course on the side |
|---|---|---|
| Now | Modules 0–2: OTP, single-node Phoenix, two-node clustering | **None** — nothing here needs a course; just build |
| Modules 3–4 | Docker Compose → k3d + libcluster | **Kubernetes for the Absolute Beginners** — start during Module 3 so pods/services/deployments are fresh for Module 4 |
| Modules 5–8 | Observability, state, backpressure, Oban/Broadway/SQS | **Microservices & Event-Driven Architecture** — covers exactly what Module 8 builds: at-least-once delivery, idempotency, DLQs |
| Module 9 → | EKS, ECR, S3, SQS, IAM, Secrets Manager | **AWS SAA 2026** — start ~2 weeks before Module 9. It's ~65 hours and will run long past the module; that's fine — exam breadth is a separate goal from the project |
| Module 10 | System design reps (one-page designs) | **Software Architecture & Design of Modern Large Scale Systems** — one section per design rep, plus the DDIA chapters the curriculum assigns |

Rules of thumb:

- Start the project first. Modules 0–2 have no course prerequisite; front-loading
  courses is tutorial hell, and course content sticks when applied within days.
- The two systems-design courses overlap. If time gets tight: Large Scale Systems
  + DDIA for Module 10; the Microservices one narrowly around Module 8. Neither
  needs finishing cover-to-cover.

## Books (reference, alongside — see CURRICULUM.md reading list)

- *Designing Data-Intensive Applications* — Kleppmann.
- *System Design Interview vol. 1 & 2* — Alex Xu.
- *Elixir in Action* — Saša Jurić.
- *Real-Time Phoenix* — Stephen Bussey.
