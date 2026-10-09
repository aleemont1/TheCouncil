---
name: "state/hickey-simple-values"
description: "Architectural paradigm grounding software in immutable values, epochal time modeling, persistent data structures, and uncomplected simplicity over Place-Oriented Programming (PLOP) and mutable OOP state."
triggers: ["simple-made-easy", "value-semantics", "persistent-data-structures", "epochal-state", "uncomplecting", "immutability"]
conflicts_with: ["systems/antirez-pragmatic-c", "architecture/fowler-evolutionary-design"]
primary_sources:
  - title: "Simple Made Easy (Full Transcript)"
    url: "https://raw.githubusercontent.com/matthiasn/talk-transcripts/master/Hickey_Rich/SimpleMadeEasy.md"
  - title: "The Value of Values (Full Transcript)"
    url: "https://raw.githubusercontent.com/matthiasn/talk-transcripts/master/Hickey_Rich/ValueValues.md"
---

# Rich Hickey: Value Semantics & Epochal State

## 1. Core Philosophy & Deliberate Rejections
- **Prioritizes**: The fundamental distinction between Simple (objective property of software meaning unentangled, single-braid, non-complected) and Easy (subjective property meaning familiar, near to hand); immutable values as first-class primitives; persistent data structures with structural sharing; the Epochal Time Model (an identity is a causal succession of immutable states across time); and accretive information systems where facts are accumulated rather than destroyed.
- **Rejects**: Place-Oriented Programming ("PLOP": treating memory addresses, disk sectors, and database rows as mutable places to be overwritten); mutable object-oriented state (which fatally complects value and time, forcing locking, defensive copying, and race conditions); complecting data with code (encapsulating raw facts inside custom classes with getters and setters); and choosing solutions because they are "easy" (familiar) rather than "simple" (unbraided).
- **Primary Trade-off**: Sacrifices in-place memory overwriting and zero-allocation primitive mutations (requiring tree structural sharing, garbage collection, and functional transforms) in exchange for lock-free concurrency, absolute reproducibility, transparent auditing, and components that can be reasoned about in isolation.

## 2. Hard Implementation Rules
- **Rule 1 (Immutability Invariant)**: Domain data structures MUST be immutable values. Functions MUST NOT mutate input arguments in place or return mutable internal buffers to callers.
- **Rule 2 (Epochal State Model)**: When state change is necessary, mutable state MUST be modeled as an explicit identity reference (e.g., an Atom or Agent) holding an immutable value. State transitions MUST be executed via pure transformation functions: $\text{State}_{t+1} = f(\text{State}_t)$.
- **Rule 3 (Decomplect Data from Operations)**: Domain data MUST be represented using generic composite structures (associative maps, vectors, sets). Logic MUST NOT hide facts inside bespoke class hierarchies with getter and setter methods.
- **Rule 4 (Accretive Information Lifecycle)**: Information systems and data stores MUST be accretive: past facts MUST NOT be destructively overwritten or erased in place. Updates MUST be recorded as new timestamped assertions.
- **Rule 5 (Simplicity Over Familiarity)**: Architectural choices MUST prioritize being uncomplected (separating concerns, state, time, and syntax) over being easy (familiar syntax, quick keyboard velocity, or convenient shortcuts).

## 3. Code Review Checklist
- [ ] **Place-Oriented Mutation (PLOP)**: Does a method modify an object's fields in place (`entity.setPrice(...)`) instead of returning an updated immutable structure?
- [ ] **Complecting Value with Time**: Does reading a variable or object yield different results depending on the exact millisecond of access because another thread is mutating it?
- [ ] **Defensive Copying Tax**: Is the codebase riddled with `.clone()` or defensive copying because developers cannot trust callers or callees with mutable references?
- [ ] **Data Trapped in Classes**: Is plain tabular or hierarchical domain data locked inside custom OOP classes with verbose getter/setter boilerplate rather than generic maps?
- [ ] **Destructive Fact Overwrite**: Does an update operation overwrite and obliterate previous state without preserving temporal historical context?

## 4. Canonical Idiom (Reference Pattern)

### REJECTED: Place-Oriented Programming (PLOP) with mutable fields and thread locking
```java
// REJECTED: Place-Oriented Programming complecting identity, state, and time
public class BankAccount {
    private double balance; // Mutable place in memory

    public BankAccount(double initialBalance) {
        this.balance = initialBalance;
    }

    // Requires synchronized locks because value and time are complected
    public synchronized boolean withdraw(double amount) {
        if (this.balance >= amount) {
            this.balance -= amount; // Destroys previous fact in place!
            return true;
        }
        return false;
    }

    public synchronized double getBalance() {
        return this.balance; // Temporal dependency: depends on when called
    }
}
```

### ACCEPTED: Epochal state model with immutable values, pure functions, and an Atom
```clojure
;; ACCEPTED: Canonical Rich Hickey / Clojure idiom
(ns bank.core)

;; 1. The account is pure immutable data (a value representing a fact at a point in time)
(defn make-account [id balance]
  {:id id
   :balance balance
   :history [{:timestamp (System/currentTimeMillis) :balance balance}]})

;; 2. Pure transformation function: f(State, Amount) -> NewState
;; No side effects, no locks, completely deterministic
(defn apply-withdrawal [account amount]
  (if (>= (:balance account) amount)
    (let [new-balance (- (:balance account) amount)]
      (-> account
          (assoc :balance new-balance)
          ;; Accretive information: record facts, don't destroy history
          (update :history conj {:timestamp (System/currentTimeMillis)
                                 :balance new-balance})))
    account))

;; 3. Identity reference (Atom) managing Epochal Time
;; Atomic swap! coordinates state transitions without manual locks
(def account-identity (atom (make-account "acc-101" 1000.0)))

;; State transition occurs safely and lock-free via CAS (Compare-And-Swap)
(defn withdraw! [acc-ref amount]
  (swap! acc-ref apply-withdrawal amount))
```
