---
name: "distributed/kleppmann-data-contracts"
description: "Distributed data systems engineering centering on immutable append-only commit logs, unbundled derived data views, Conflict-Free Replicated Data Types (CRDTs), and backward/forward compatible schema evolution."
triggers: ["append-only-log", "crdt-convergence", "unbundled-databases", "schema-evolution", "derived-views", "event-driven-contracts"]
conflicts_with: ["architecture/dhh-majestic-monolith", "state/hickey-simple-values"]
primary_sources:
  - title: "Designing Data-Intensive Applications (Summary & Core Invariants)"
    url: "https://dataintensive.net/"
  - title: "Conflict-Free Replicated Data Types (CRDTs)"
    url: "https://arxiv.org/abs/1907.03960"
---

# Martin Kleppmann: Immutable Logs & Convergence Contracts

## 1. Core Philosophy & Deliberate Rejections
- **Prioritizes**: The append-only log as the fundamental source of truth ("Turning the database inside out"); unbundling databases into immutable streams and derived read views; coordination-free replication via Conflict-Free Replicated Data Types (CRDTs) where merges are commutative, associative, and idempotent; explicit data contracts with strict backward and forward schema compatibility; and transparent trade-offs between consistency models (Linearizability, Causal Consistency, Eventual Consistency).
- **Rejects**: Destructive in-place overwriting of relational state as the sole system record; distributed locking and Two-Phase Commit (2PC) across service boundaries (which destroys availability under network partitions); unversioned data schemas that silently break downstream data consumers; and relying on unreliable network boundaries or unsynchronized wall clocks for ordering.
- **Primary Trade-off**: Sacrifices the immediate synchronous simplicity of single-node ACID transactions in exchange for multi-leader partition tolerance, collaborative offline-first synchronization, reproducible event replay, and unbounded analytical scaling.

## 2. Hard Implementation Rules
- **Rule 1 (The Log as Source of Truth)**: Core domain mutations MUST be persisted as an immutable append-only event or transaction log. Read models, caches, and search indexes MUST be treated as derived views that can be deterministically re-materialized from the log.
- **Rule 2 (CRDT Mathematical Convergence)**: Collaborative and multi-leader state replication MUST use CRDT algorithms whose merge operations form a join-semilattice (commutative: $A \sqcup B = B \sqcup A$; associative: $(A \sqcup B) \sqcup C = A \sqcup (B \sqcup C)$; idempotent: $A \sqcup A = A$).
- **Rule 3 (Strict Schema Compatibility)**: Distributed event contracts (Protobuf, Avro, JSON Schema) MUST maintain backward and forward compatibility. Schema changes MUST NOT delete fields without deprecation cycles or add required fields without defaults.
- **Rule 4 (No Distributed Transactions Across Services)**: Systems spanning distinct networks or storage boundaries MUST NOT utilize blocking Two-Phase Commit (2PC). Coordination MUST be structured through asynchronous log consumption, idempotency keys, and compensating sagas.
- **Rule 5 (Deterministic Derivation)**: Consumer projections that process event streams MUST be deterministic and idempotent. Given the identical sequence of log offsets, a view generator MUST produce an identical materialized state.

## 3. Code Review Checklist
- [ ] **Destructive Mutation in Event Store**: Does an update query overwrite historical row data in an authoritative table instead of appending an event record?
- [ ] **Non-Convergent State Merge**: Is a multi-leader or client-side merge resolution dependent on arrival order (violating commutativity) rather than a mathematical CRDT or Lamport clock tie-breaker?
- [ ] **Breaking Schema Change**: Does an updated event schema remove a field or change a type in a way that breaks existing log replays or older running consumers?
- [ ] **Cross-Service Synchronous Lock**: Does a distributed service hold an in-memory lock or distributed database lock across a remote network HTTP call?
- [ ] **Non-Idempotent Consumer**: Does an event consumer lack deduplication or idempotency keys, causing double-processing on network retries?

## 4. Canonical Idiom (Reference Pattern)

### REJECTED: In-place state overwrite in shared database with non-reproducible history
```python
# REJECTED: Destructive update destroying audit history and causing concurrent update loss
def update_user_email(db, user_id, new_email):
    # Overwrites previous state in place: no history, no event stream, lost updates under concurrency
    db.execute("UPDATE users SET email = %s WHERE id = %s", (new_email, user_id))
    # Downstream search indexes and caches must be updated manually, risking inconsistency!
    search_index.update(user_id, new_email)
```

### ACCEPTED: Append-only log with derived view and deterministic CRDT Observed-Remove Set
```python
# ACCEPTED: Canonical Kleppmann idiom: Append-only log with CRDT convergence
from dataclasses import dataclass
from typing import Set, Tuple, Any

@dataclass(frozen=True)
class LogEvent:
    offset: int
    entity_id: str
    op_type: str  # "ADD" or "REMOVE"
    value: Any
    tag: str      # Unique UUID/Lamport timestamp for element identity

class ORSetCRDT:
    """
    Observed-Remove Set (OR-Set) CRDT.
    Guarantees conflict-free convergence across replicas without central coordination.
    Merge operation is commutative, associative, and idempotent.
    """
    def __init__(self):
        self.entries: Set[Tuple[Any, str]] = set()  # Set of (value, unique_tag)

    def add(self, value: Any, tag: str) -> None:
        self.entries.add((value, tag))

    def remove(self, value: Any) -> None:
        # Removes all currently observed tags for this value
        self.entries = {(v, t) for (v, t) in self.entries if v != value}

    def merge(self, other: 'ORSetCRDT') -> 'ORSetCRDT':
        """Join operation: Set Union. Commutative, Associative, Idempotent."""
        result = ORSetCRDT()
        result.entries = self.entries.union(other.entries)
        return result

    def read(self) -> Set[Any]:
        """Derived view projected from the internal CRDT elements."""
        return {v for (v, t) in self.entries}
```
