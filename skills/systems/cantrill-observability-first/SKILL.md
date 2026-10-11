---
name: cantrill-observability-first
description: "Observability first: production tracing with zero disabled probe effect, bounded telemetry, safe instrumentation, explicit platform values. Use when adding logging, metrics or tracing, designing for production debuggability, or reviewing hot-path telemetry."
triggers: ["observability-first", "dtrace-architecture", "zero-overhead-probing", "mechanical-sympathy", "platform-values", "production-debuggability"]
conflicts_with: ["types/king-type-driven-design"]
primary_sources:
  - title: "Forked: A Decade of DTrace"
    url: "https://www.youtube.com/watch?v=l6XQU9NP74A"
  - title: "Platform as a Reflection of Values"
    url: "https://queue.acm.org/detail.cfm?id=3329585"
---

# Bryan Cantrill: Observability-First Systems & Mechanical Sympathy

**Apply**: write or review the target under Sections 2 and 3. Done when every rule is either satisfied or reported as violated, and every checklist item is marked hit (with `file:line`) or clear. When a rule collides with a stated requirement, name the trade-off from Section 1 rather than bending the rule silently.

## 1. Core Philosophy & Deliberate Rejections
- **Prioritizes**: Observability as an uncompromising day-zero engineering constraint; zero disabled probe effect (instrumentation points must cost zero instructions or a single `nop` when inactive, never degrading production throughput); absolute probe safety (tracing must never cause kernel panics, page faults, deadlocks, or process crashes); deep mechanical sympathy with operating system internals; and explicit alignment around core engineering values (debuggability, robustness, performance, operational transparency).
- **Rejects**: Treating debugging and telemetry as an afterthought added via scattered `printf` statements; instrumentation that introduces constant latency overhead to production transactions; telemetry pipelines that can block or exhaust memory in production; and opaque, black-box systems that cannot be introspected while running live customer traffic.
- **Primary Trade-off**: Sacrifices rapid, unmonitored feature delivery to ensure that every system component can be dynamically inspected, measured, and debugged in production under full production load without downtime or instability.

## 2. Hard Implementation Rules
- **Rule 1 (Zero Disabled Probe Effect)**: System instrumentation and trace points (e.g., USDT - User-level Statically Defined Tracing) MUST have zero measurable overhead when disabled. Code MUST NOT execute string formatting, allocation, or branching for inactive tracepoints.
- **Rule 2 (Absolute Probe Safety)**: Telemetry and tracing logic MUST NOT perturb or mutate application state. Dynamic instrumentation actions MUST NOT acquire application locks, perform blocking I/O, or throw unhandled exceptions that could terminate the production service.
- **Rule 3 (Bounded Memory & Telemetry Ring Buffers)**: Observability data gathering MUST use pre-allocated, bounded per-CPU ring buffers. Instrumentation MUST drop metrics or log entries under extreme pressure rather than exhausting heap memory or blocking computational threads.
- **Rule 4 (Mechanical Sympathy with OS & Hardware)**: Systems software MUST align with kernel execution models (CPU affinity, virtual memory pages, non-blocking asynchronous multiplexing). Developers MUST NOT layer abstractions that conceal hardware realities.
- **Rule 5 (Explicit Conflict of Values)**: Architectural disagreements MUST be framed as explicit trade-offs among conflicting engineering values (e.g., approachability vs debuggability, velocity vs robustness). Code MUST NOT sacrifice debuggability for superficial developer convenience.

## 3. Code Review Checklist
- [ ] **Inactive Tracepoint Tax**: Does an inactive logging or tracing call format strings, allocate memory, or execute regex checks before verifying if the probe is enabled?
- [ ] **Blocking in Telemetry Path**: Does an error reporter, log writer, or metric publisher acquire a lock or perform a blocking network socket write inside a latency-critical hot path?
- [ ] **Unbounded Log Buffering**: Does the telemetry collection system use an unbounded queue that can trigger Out-Of-Memory (OOM) crashes during downstream ingestion outages?
- [ ] **Black-Box Component**: Has a new critical subsystem or daemon been written without native static tracepoints or introspectable state counters?
- [ ] **Disregard for Mechanical Sympathy**: Does the implementation create hundreds of worker threads or ignore kernel paging behavior, causing severe CPU cache thrashing?

## 4. Canonical Idiom (Reference Pattern)

### REJECTED: Ad-hoc logging with string allocations, locks, and runtime overhead on hot paths
```c
/* REJECTED: Anti-pattern of hot-path logging causing allocation and blocking */
#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>

static pthread_mutex_t log_lock = PTHREAD_MUTEX_INITIALIZER;

void process_transaction(int tx_id, double amount) {
    // FATAL: Allocates memory and acquires lock on every hot transaction, even in production!
    char *msg = malloc(128);
    snprintf(msg, 128, "Processing TX: %d, Amount: %.2f\n", tx_id, amount);

    pthread_mutex_lock(&log_lock); // Lock contention across all worker threads!
    FILE *f = fopen("/var/log/tx.log", "a"); // Blocking disk I/O on critical path!
    fputs(msg, f);
    fclose(f);
    pthread_mutex_unlock(&log_lock);
    free(msg);
}
```

### ACCEPTED: Zero-cost static probe (USDT / DTrace style) with zero disabled overhead
```c
/* ACCEPTED: Canonical Cantrill / DTrace pattern with zero disabled probe overhead */
#include <sys/sdt.h> /* Standard DTrace/USDT provider macros */
#include <stdint.h>

/*
 * When disabled, DTRACE_PROBE2 expands to a single nop instruction.
 * Zero string formatting, zero allocations, zero lock contention!
 * When enabled, the kernel dynamically patches the instruction to jump into
 * the safe DTrace VM to inspect registers with absolute zero risk of crashing.
 */

void process_transaction_observable(uint64_t tx_id, double amount) {
    // Probe point: costs 0 cycles when inactive
    DTRACE_PROBE2(my_app, transaction__start, tx_id, (uintptr_t)&amount);

    // Core transaction execution runs at raw hardware speed...
    execute_transaction(tx_id, amount);

    // End probe
    DTRACE_PROBE1(my_app, transaction__done, tx_id);
}
```
