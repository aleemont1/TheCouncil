# TheCouncil

> Dialectic AI Engineering Lenses & High-Constraint Skills for Autonomous Coding Agents.

`TheCouncil` is an open-source, modular repository of engineering constraints and dialectic code-review lenses designed for autonomous coding agents (Claude Code, Antigravity CLI, Cursor, Aider).

Frontier LLMs inherently suffer from **regression to the mean**. Shaped by massive general-purpose training corpora and conversational alignment (RLHF), they default to safe, generic enterprise patterns: superficial object hierarchies, defensive try/catch wrapping around ordinary logic, tiny fragmented pass-through functions, dynamic dispatch on execution hot-paths, and continuous heap allocations.

`TheCouncil` overrides these tendencies by injecting non-negotiable operational invariants distilled directly from the primary writings, benchmark studies, and production codebases of 18 foundational figures in computer systems, architecture, and engineering philosophy.

---

## The 18 Council Seats

| Domain | Lens Slug (`SKILL.md`) | Author / Pioneer | Core Invariant | Primary Use Cases |
|---|---|---|---|---|
| **Systems** | `antirez-pragmatic-c` | Salvatore Sanfilippo | Single-threaded event loops, zero-dependency flat C, radical readability. | TCP/UDP network servers, in-memory caches, high-throughput engines. |
| **Systems** | `stenberg-defensive-c` | Daniel Stenberg | Industrial C defensive verification, zero memory leaks, immutable ABI stability. | Network protocol parsers, shared libraries exposed to untrusted input. |
| **Systems** | `pike-unix-minimalism` | Rob Pike & Ken Thompson | Transparent $O(N)$ control flow, data-first design, orthogonal composition. | System daemons, CLI utilities, anti-overengineering Go/C refactoring. |
| **Systems** | `cantrill-observability-first` | Bryan Cantrill | Dynamic runtime tracing (DTrace/eBPF mindset), hardware-software co-design. | Low-level drivers, kernel-adjacent modules, production telemetry harnesses. |
| **Systems** | `bellard-autonomous-engine` | Fabrice Bellard | Monolithic standalone implementation, zero third-party dependencies, dense C. | Emulators, bytecode interpreters, audio/video encoders, compilers. |
| **Resilience** | `armstrong-fault-isolation` | Joe Armstrong | "Let it crash", process-level fault boundaries, supervision trees, share-nothing. | Distributed workers, message queues, concurrent state supervisors. |
| **Formal** | `lamport-state-invariants` | Leslie Lamport | Mathematical state verification before execution, temporal safety invariants. | Consensus protocols, concurrent locks, multi-agent state machines. |
| **Security** | `djb-isolated-privilege` | Daniel J. Bernstein | Privilege-dropped micro-binaries, constant-time algorithms, rejection of bloated libc. | Cryptographic routines, auth gates, network-facing perimeter daemons. |
| **Performance** | `muratori-data-oriented` | Casey Muratori | 64-byte CPU cache alignment, contiguous buffers, SoA, zero virtual dispatch. | Physics engines, rendering pipelines, high-frequency batch loops. |
| **Performance** | `carmack-inlined-execution` | John Carmack | Aggressive inlining, functional purity in imperative loops, zero call-stack bloat. | Audio synthesis, simulation loops, graphics frame generation. |
| **Performance** | `danluu-empirical-systems` | Dan Luu | Empirical p99/p99.9 distribution testing, disk crash-consistency, real hardware limits. | Database storage engines, filesystem operations, performance regression suites. |
| **Distributed** | `kleppmann-data-contracts` | Martin Kleppmann | Explicit consistency models, append-only log-centric storage, partition tolerance. | Replicated data stores, CRDTs, synchronization engines, event pipelines. |
| **Types** | `king-type-driven-design` | Alexis King | "Parse, don't validate", illegal states unrepresentable via algebraic type systems. | Compiler frontends, business domain input decoders, AST construction. |
| **State** | `hickey-simple-values` | Rich Hickey | Separation of Identity/State/Value, immutable persistent data, generic schemas. | Configuration systems, transactional state machines, data transformation pipelines. |
| **Architecture** | `ousterhout-deep-modules` | John Ousterhout | Deep modules (simple interfaces hiding complex logic), rejection of shallow shims. | Core library APIs, internal service boundaries, subsystem refactoring. |
| **Architecture** | `dhh-majestic-monolith` | David Heinemeier Hansson | Integrated monolithic applications, single-database stores, server-side velocity. | Full-stack web platforms, rapid product iterations, domain SaaS products. |
| **Architecture** | `fowler-evolutionary-design` | Martin Fowler | Continuous test-backed refactoring, explicit domain models, test pyramid discipline. | Complex enterprise domains, multi-stage billing/invoicing systems. |
| **Architecture** | `uncle-bob-solid-orthodox` | Robert C. Martin | Strict Single Responsibility, Dependency Inversion, rigorous test-first cycle. | Enterprise core modules requiring total decoupling from external drivers. |

---

## The Council Chancellor (Triage Router & Orchestrator)

In addition to the 18 specific seats, the repository includes an active triage orchestrator:

| Domain | Lens Slug (`SKILL.md`) | Author / Role | Core Invariant | Primary Use Cases |
|---|---|---|---|---|
| **Router** | `router/ask-council` | The Council Chancellor | Interactive triage decision tree routing to Solo Lenses, Sequential Pipelines, or Dialectic Tribunals. | Task triage, architectural dilemma arbitration, lens recommendation. |

---

## Operational Workflows

### 1. Interactive Triage via The Chancellor (`/ask-council`)
When unsure which engineering lens applies, invoke the Chancellor router to analyze the problem and output an execution plan:

```bash
# Example invocation in Claude Code or Antigravity CLI
claude "Apply skill router/ask-council to: We are designing a high-throughput event buffer in C++ and debating between virtual polymorphic streams vs contiguous cache arrays."
```

### 2. The Dialectic Tribunal (Mirror Code Reviews)
Rather than performing generic pull request audits that dilute opinions into consensus, execute a Dialectic Tribunal by pitting two irreconcilable philosophies against each other:

```bash
# Example invocation in Claude Code or Antigravity CLI
claude "Run a Dialectic Tribunal on src/engine/tick.rs:
- Lens A: performance/muratori-data-oriented
- Lens B: architecture/uncle-bob-solid-orthodox
Produce two uncompromising, independent audits followed by a trade-off matrix."
```

#### Pre-Configured Dialectic Clash Pairs (`conflict_matrix`):
1. **`muratori-data-oriented` vs `fowler-evolutionary-design`**: Hardware Mechanical Sympathy vs Enterprise Domain Model Abstractions.
2. **`ousterhout-deep-modules` vs `fowler-evolutionary-design`**: Deep Modules (Thick Classes) vs Granular Class/Method Refactoring.
3. **`armstrong-fault-isolation` vs `stenberg-defensive-c`**: Share-Nothing "Let It Crash" vs Defensive Error Handling and Never Abort.
4. **`dhh-majestic-monolith` vs `Microservices / Cloud-Native`**: Majestic Monolith & Bare-Metal vs Distributed Cloud-Native Topology.
5. **`hickey-simple-values` vs `OOP mutable encapsulation`**: Immutable Value Semantics & Epochal State vs Mutable In-Place Encapsulation (PLOP).
6. **`uncle-bob-solid-orthodox` vs `muratori-data-oriented`**: Dynamic Polymorphic Layers vs Cache-Aligned CPU Memory.
7. **`uncle-bob-solid-orthodox` vs `ousterhout-deep-modules`**: Granular Micro-Methods vs Deep Encapsulated Interfaces.
8. **`djb-isolated-privilege` vs `stenberg-defensive-c`**: OS-Level Privilege Drop & Micro-Binaries vs Internal Defensive Pointer Management.
9. **`king-type-driven-design` vs `pike-unix-minimalism`**: Algebraic Compile-Time Type Proofs vs Raw Byte Slices & Loose Interfaces.
10. **`lamport-state-invariants` vs `armstrong-fault-isolation`**: Mathematical State Validation Before Execution vs Reactive Supervision Trees.
11. **`carmack-inlined-execution` vs `fowler-evolutionary-design`**: Inline Execution Without Indirection vs Extracted Helper Methods & Evolutionary Layers.

### 3. Sequential Refinement Pipelines
Stack complementary skills across orthogonal layers of abstraction to take a feature from domain design down to hardware execution:

* **High-Throughput Network Engine:**
  1. `ousterhout-deep-modules`: Define a minimal, deep public API surface.
  2. `king-type-driven-design`: Parse untrusted network payloads into verified types at the boundary.
  3. `antirez-pragmatic-c`: Build the core async non-blocking event loop.
  4. `muratori-data-oriented`: Layout internal packet ring-buffers in contiguous cache lines.
  5. `stenberg-defensive-c`: Audit pointer boundaries, memory leak profiles, and return codes.

* **Distributed Fault-Tolerant Node:**
  1. `lamport-state-invariants`: Prove state transitions and race conditions on paper.
  2. `kleppmann-data-contracts`: Model persistence over an immutable log using explicit replication contracts.
  3. `armstrong-fault-isolation`: Wrap runtime execution in isolated, supervised workers.
  4. `danluu-empirical-systems`: Subject the implementation to crash testing and latency profiling.

---

## Repository Layout

```text
TheCouncil/
├── README.md                      # Human-facing specification, catalog, and workflows
├── AGENT_MANIFEST.md              # Agent-facing operational manifest (Claude Code / Antigravity)
├── skills/
│   ├── registry.json              # Machine-readable registry and conflict matrix
│   ├── router/
│   │   └── ask-council/SKILL.md   # The Council Chancellor interactive triage router
│   ├── systems/
│   │   ├── antirez-pragmatic-c/SKILL.md
│   │   ├── stenberg-defensive-c/SKILL.md
│   │   ├── pike-unix-minimalism/SKILL.md
│   │   ├── cantrill-observability-first/SKILL.md
│   │   └── bellard-autonomous-engine/SKILL.md
│   ├── resilience/
│   │   └── armstrong-fault-isolation/SKILL.md
│   ├── formal/
│   │   └── lamport-state-invariants/SKILL.md
│   ├── security/
│   │   └── djb-isolated-privilege/SKILL.md
│   ├── performance/
│   │   ├── muratori-data-oriented/SKILL.md
│   │   ├── carmack-inlined-execution/SKILL.md
│   │   └── danluu-empirical-systems/SKILL.md
│   ├── distributed/
│   │   └── kleppmann-data-contracts/SKILL.md
│   ├── types/
│   │   └── king-type-driven-design/SKILL.md
│   ├── state/
│   │   └── hickey-simple-values/SKILL.md
│   └── architecture/
│       ├── ousterhout-deep-modules/SKILL.md
│       ├── dhh-majestic-monolith/SKILL.md
│       ├── fowler-evolutionary-design/SKILL.md
│       └── uncle-bob-solid-orthodox/SKILL.md
```

---

## Acknowledgements & Primary Sources

### Structural & Agentic Inspiration
The architectural blueprint for turning expert mental models into modular, manifest-driven LLM skills is directly inspired by **Matt Pocock** and his work on [mattpocock/skills](https://github.com/mattpocock/skills), which demonstrated how structured, trigger-aware skill catalogs empower autonomous coding agents.

### Primary Engineering Works
Every rule, constraint, and checklist in this repository is directly derived from the published works, essays, and production architectures of the following authors:

* **Salvatore Sanfilippo (antirez):** *Redis System Architecture* and *Optimization: The Code You Don't Write*.
* **Daniel Stenberg:** *HTTP/3 Explained*, *libcurl Source Architecture*, and *The curl Security Vulnerability Process*.
* **Rob Pike & Ken Thompson:** *Notes on Programming in C*, *Go Proverbs*, and *Unix Philosophy Core Maxims*.
* **Bryan Cantrill:** *Forked: A Decade of DTrace* and *Platform as a Reflection of Values*.
* **Fabrice Bellard:** *QuickJS Javascript Engine Architecture* and *Tiny C Compiler (TCC) Design*.
* **Joe Armstrong:** *Making Reliable Distributed Systems in the Presence of Software Errors* (PhD Thesis) and *Systems That Run Forever*.
* **Leslie Lamport:** *Time, Clocks, and the Ordering of Events in a Distributed System* and *Specifying Systems (TLA+)*.
* **Daniel J. Bernstein (djb):** *Some Thoughts on Security After Ten Years of qmail* and *daemontools Architecture*.
* **Casey Muratori:** *Clean Code, Horrible Performance* and *Recompute Everything*.
* **John Carmack:** *On Inlined Code* and *Functional Programming in C++*.
* **Dan Luu:** *Filesystem Crash Consistency*, *Terminal Latency*, and *Performance Tracing*.
* **Martin Kleppmann:** *Designing Data-Intensive Applications* and *Conflict-free Replicated Data Types*.
* **Alexis King:** *Parse, Don't Validate* and *Types as Axioms*.
* **Rich Hickey:** *Simple Made Easy* and *The Value of Values*.
* **John Ousterhout:** *A Philosophy of Software Design* and *Red Flags in Software Architecture*.
* **David Heinemeier Hansson (DHH):** *The Majestic Monolith*, *TDD is Dead. Long Live Testing*, and *Why We Are Leaving the Cloud*.
* **Martin Fowler:** *Patterns of Enterprise Application Architecture*, *Refactoring*, and *MonolithFirst*.
* **Robert C. Martin (Uncle Bob):** *Clean Architecture*, *Design Principles and Design Patterns (SOLID)*, and *The Cycles of TDD*.