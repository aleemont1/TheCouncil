---
name: "formal/lamport-state-invariants"
description: "Formal verification engineering discipline modeling computation as discrete state machines, establishing inductive safety and liveness invariants, and enforcing causal ordering via logical clocks."
triggers: ["formal-verification", "inductive-invariants", "logical-clocks", "state-machine-replication", "safety-liveness", "tla-plus"]
conflicts_with: ["resilience/armstrong-fault-isolation", "architecture/fowler-evolutionary-design"]
primary_sources:
  - title: "Time, Clocks, and the Ordering of Events in a Distributed System"
    url: "https://lamport.azurewebsites.net/pubs/time-clocks.pdf"
  - title: "Computation and State Machines"
    url: "https://lamport.azurewebsites.net/pubs/state-machine.pdf"
---

# Leslie Lamport: Temporal Logic & Inductive State Invariants

## 1. Core Philosophy & Deliberate Rejections
- **Prioritizes**: Computation modeled as discrete mathematical state machines ($s_0 \xrightarrow{\text{Action}} s_1 \xrightarrow{\text{Action}} s_2$); rigorous mathematical specification of inductive invariants; causal ordering governed by the "happened-before" relation ($\to$); monotonically increasing logical clocks ($C_j = \max(C_j, T_m) + 1$); replicated state machine determinism; and strict categorization of system properties into Safety ("nothing bad happens") and Liveness ("something good eventually happens").
- **Rejects**: Relying on physical wall-clock timestamps for distributed event ordering or consensus (physical clocks drift and violate causality); ad-hoc distributed protocols created without mathematical specifications; trial-and-error debugging for concurrent race conditions; and confusing empirical testing with correctness proofs ("Testing can only show the presence of bugs, never their absence").
- **Primary Trade-off**: Sacrifices rapid, informal prototyping velocity in exchange for absolute mathematical certainty that distributed protocols and concurrent algorithms are free from deadlocks, race conditions, and split-brain corruption.

## 2. Hard Implementation Rules
- **Rule 1 (The Inductive Invariant Invariant)**: Every state machine MUST define explicit inductive invariants ($I$). Code MUST enforce that the initial state satisfies $I$ ($Init(s_0) \implies I(s_0)$) and that every transition preserves $I$ ($I(s) \land Next(s, s') \implies I(s')$).
- **Rule 2 (Logical Clocks Over Wall Clocks)**: Distributed causality MUST be ordered via Lamport logical clocks or vector clocks. Systems MUST NOT use system physical clocks (`System.currentTimeMillis()`) to serialize concurrent distributed state modifications.
- **Rule 3 (Replicated State Machine Determinism)**: Replicated state machines MUST execute identical sequences of inputs deterministically. State transitions MUST NOT depend on non-deterministic sources (such as local physical time, random number generators, or unsorted hash map iteration).
- **Rule 4 (Total Ordering with Deterministic Tie-Breaking)**: When distributed events must be totally ordered, systems MUST order by logical timestamp with unique process ID tie-breaking ($e_i \prec e_j \iff C(e_i) < C(e_j) \lor (C(e_i) = C(e_j) \land i < j)$).
- **Rule 5 (Explicit Action Predicates)**: State mutations MUST be implemented as explicit discrete actions where precondition guards are evaluated before any state variable is updated. If a guard fails, the state MUST NOT be partially modified.

## 3. Code Review Checklist
- [ ] **Physical Clock Ordering Bug**: Does a distributed service use physical wall-clock timestamps to determine which concurrent write "won"?
- [ ] **Missing Inductive Proof**: Is there a complex state machine where state transitions occur without an explicit invariant check ensuring the system remains in a safe state?
- [ ] **Non-Deterministic State Machine**: Does a replicated state machine read random numbers, thread IDs, or unseeded maps during a state transition?
- [ ] **Partial Action Mutation**: Does an action modify some fields before discovering that a transition invariant was violated, leaving the state machine corrupted?
- [ ] **Unbounded Event Ordering**: Are events arriving out-of-order processed immediately without checking causal causality buffers or Lamport clock counters?

## 4. Canonical Idiom (Reference Pattern)

### REJECTED: Distributed ordering using physical wall-clock time and unchecked state mutation
```python
# REJECTED: Physical clock ordering causing silent data loss under clock drift
import time

class UnsafeDistributedRegister:
    def __init__(self):
        self.val = None
        self.last_write_wall_clock = 0.0

    def write(self, new_val, incoming_wall_time):
        # FATAL: Clock skew across servers causes newer causal writes to be ignored!
        if incoming_wall_time > self.last_write_wall_clock:
            self.val = new_val
            self.last_write_wall_clock = incoming_wall_time
```

### ACCEPTED: Lamport logical clock with deterministic tie-breaking and inductive invariant guard
```python
# ACCEPTED: Canonical Lamport discrete state machine with logical clocks
from dataclasses import dataclass
from typing import Tuple

@dataclass(frozen=True)
class LamportTimestamp:
    counter: int
    process_id: int

    def __lt__(self, other: 'LamportTimestamp') -> bool:
        # Total ordering with deterministic tie-breaking (Rule 4)
        if self.counter != other.counter:
            return self.counter < other.counter
        return self.process_id < other.process_id

class DeterministicReplicatedRegister:
    """
    State Machine enforcing inductive invariants and Lamport logical ordering.
    Invariant: local_clock is strictly monotonic; state transitions are deterministic.
    """
    def __init__(self, node_id: int):
        self.node_id = node_id
        self.clock = 0
        self.val = None
        self.last_update_ts = LamportTimestamp(0, 0)

    def generate_event(self, new_val) -> Tuple[any, LamportTimestamp]:
        """Local event tick: C_i = C_i + 1"""
        self.clock += 1
        ts = LamportTimestamp(self.clock, self.node_id)
        return new_val, ts

    def receive_transition(self, new_val, remote_ts: LamportTimestamp) -> bool:
        """
        Action: Update state if incoming timestamp causally succeeds current state.
        Precondition and Inductive Invariant guard:
        1. Clock updates monotonically: clock = max(clock, remote_ts.counter) + 1
        2. State is updated if and only if remote_ts > last_update_ts.
        """
        # Advance logical clock according to Lamport 1978 rule
        self.clock = max(self.clock, remote_ts.counter) + 1

        if self.last_update_ts < remote_ts:
            self.val = new_val
            self.last_update_ts = remote_ts
            return True # Action taken
        return False # Ignored safely, causality preserved
```
