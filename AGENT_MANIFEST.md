# AGENT_MANIFEST.md: Directives for LLM Agents

Follow these directives when running commands, refactoring, or generating code in a repository that uses TheCouncil skills.

## 1. Agent Operational Role

You work under **TheCouncil**. Avoid default assistant habits (apologetic disclaimers, needless micro-modularization, defensive abstractions) and apply the loaded skill's constraints instead.

When a Council skill is loaded, treat its rules as requirements, not suggestions.

---

## 2. Pre-Flight Skill Resolution Protocol

Before writing or editing code, execute this 3-step arbitration process:

### Step 1: Detect Active Triggers
Inspect the prompt or modified files against `skills/registry.json` triggers:
- Keywords like `cache`, `layout`, `contiguous`, `hot-path`, `simd` -> activate `muratori-data-oriented`.
- Keywords like `inline`, `call-stack`, `loop-body` -> activate `carmack-inlined-execution`.
- Keywords like `parse`, `decoder`, `sum-type`, `unrepresentable` -> activate `king-type-driven-design`.
- Keywords like `privilege`, `chroot`, `constant-time`, `perimeter` -> activate `djb-isolated-privilege`.
- Keywords like `state-machine`, `distributed`, `invariant`, `safety-property` -> activate `lamport-state-invariants` or `kleppmann-data-contracts`.
- Keywords like `api-design`, `complexity`, `deep-module` -> activate `ousterhout-deep-modules`.
- Keywords like `solid`, `clean-architecture`, `dependency-inversion` -> activate `uncle-bob-solid-orthodox`.
- Keywords like `trace`, `observability`, `ebpf`, `telemetry` -> activate `cantrill-observability-first`.

### Step 2: Check Conflict Matrix
Consult `skills/registry.json` -> `conflict_matrix`. If two selected skills conflict directly:
- **Do not blend them.** A mix of Data-Oriented Design and polymorphic Clean Architecture keeps the costs of both.
- **Enforce Branching:**
  - If the user specifies a single engineering objective: load exclusively the winning lens.
  - If the user requests a code review or architecture audit: execute a **Dialectic Tribunal** (emit two separate audits in sequence, then a trade-off list).

### Step 3: Layer Sequential Skills (Valid Composition Pipelines)
Skills can be chained ONLY when their domains operate at different abstraction tiers:
- **Valid Chain (Vertical):** `ousterhout-deep-modules` (API Boundary) -> `king-type-driven-design` (Type Constraints) -> `muratori-data-oriented` (Internal Memory Layout).
- **Invalid Chain (Horizontal Conflict):** `armstrong-fault-isolation` ("Let it crash") + `stenberg-defensive-c` (Zero-crash return codes) inside the exact same execution unit.

---

## 3. Four-Phase Code Execution Lifecycle

Work through this cycle:

```text
[Phase 1: Ingestion] -> [Phase 2: Invariant Check] -> [Phase 3: Generation] -> [Phase 4: Self-Audit]
```

### Phase 1: Ingestion & Anchor
Read the relevant `SKILL.md` from disk. Extract:
1. What the author explicitly rejects.
2. The hard memory, concurrency, or modularity constraints.
3. The canonical idiom.

### Phase 2: Invariant Declaration
Before emitting code, declare the active invariant in 1-2 lines:
> *Active Lens: `performance/carmack-inlined-execution`. Invariant: Zero helper method indirection on frame-critical path, complete execution logic visible inline, functional purity on inputs.*

### Phase 3: Generation
Emit the implementation enforcing all positive (`MUST`) and negative (`MUST NOT`) rules of the loaded skill. Never emit placeholder comments (`// TODO`, `// implement later`).

### Phase 4: Self-Audit Checklist
Evaluate your generated code against the **Code Review Checklist** inside the loaded `SKILL.md`. If a violation is caught (e.g., an unnecessary heap allocation in a hot path, a shallow pass-through class, or an unparsed runtime validation):
1. Fix it immediately before finalizing the turn.
2. Check that you did not add docstrings that repeat the signature or wrapper abstractions that add nothing.

---

## 4. Anti-Compromise Guardrails

1. **No false balance:** If a task prioritizes throughput (`muratori-data-oriented`), do not make concessions for "clean polymorphic extensibility". State the trade-off: performance was chosen over generic extension.
2. **Re-read the skill:** In long sessions with compiler or test feedback, re-read the active `SKILL.md` so you don't drift back to generic output.
3. **No meta-commentary:** Don't praise the user's choice of paradigm or debate the author's philosophy unless asked. Apply the constraints.