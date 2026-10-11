---
name: pike-unix-minimalism
description: "Unix minimalism: data-dominant design, small interfaces, standard data structures, clarity over cleverness, CSP concurrency. Use when simplifying a design, choosing data structures, shaping composition boundaries, or picking channels over shared memory."
triggers: ["data-dominates", "unix-minimalism", "go-proverbs", "clear-over-clever", "csp-concurrency", "small-interfaces"]
conflicts_with: ["architecture/ousterhout-deep-modules", "architecture/fowler-evolutionary-design", "types/king-type-driven-design"]
primary_sources:
  - title: "Notes on Programming in C"
    url: "https://www.lysator.liu.se/c/pikestyle.html"
  - title: "Go Proverbs"
    url: "https://go-proverbs.github.io/"
---

# Rob Pike & Ken Thompson: Unix Minimalism & Data-Dominant Simplicity

**Apply**: write or review the target under Sections 2 and 3. Done when every rule is either satisfied or reported as violated, and every checklist item is marked hit (with `file:line`) or clear. When a rule collides with a stated requirement, name the trade-off from Section 1 rather than bending the rule silently.

## 1. Core Philosophy & Deliberate Rejections
- **Prioritizes**: Data-dominant design ("Data dominates. If you've chosen the right data structures and organized things well, the algorithms will almost always be self-evident"), minimal orthogonal language primitives, tiny interfaces ("The bigger the interface, the weaker the abstraction"), CSP concurrency ("Don't communicate by sharing memory, share memory by communicating"), measuring before tuning ("Bottlenecks occur in surprising places"), and terse, context-aware naming.
- **Rejects**: Fancy algorithms with heavy constant factors when $n$ is small (Rules 3 & 4: "Fancy algorithms are buggier than simple ones... binary trees are always faster than splay trees for workaday problems"); speculative generality; giant variable names (`MaximumValueUntilOverflow` vs `maxval`); reflection and meta-programming ("Reflection is never clear", "Clear is better than clever"); exceptions for control flow; and third-party dependency bloat ("A little copying is better than a little dependency").
- **Primary Trade-off**: Sacrifices language-level syntactic sugar, complex type-system abstractions, and theoretical asymptotic micro-optimizations in exchange for radical transparency, predictable performance, sub-second build times, and code that remains effortlessly readable decades later.

## 2. Hard Implementation Rules
- **Rule 1 (The Four Core Data Structures)**: Systems MUST be built from the four fundamental data structures: array, linked list, hash table, and binary tree. Developers MUST NOT implement complex or esoteric structures unless empirical profiling proves that $n$ is persistently huge and the simple structure is the bottleneck.
- **Rule 2 (Communicating Sequential Processes)**: Concurrency MUST be orchestrated by passing data across channels or isolated message queues. Code MUST NOT coordinate worker pipelines through shared mutable variables protected by global mutexes.
- **Rule 3 (Tiny Interfaces)**: Interfaces MUST declare the minimal set of methods required (ideally 1 to 2 methods, exemplified by Go's `io.Reader` and `io.Writer`). Large multi-method interfaces MUST NOT be created as upfront abstract contracts.
- **Rule 4 (Errors as Explicit Values)**: Errors MUST be returned as explicit values and inspected at the point of call. Code MUST NOT use unchecked exceptions, runtime panics across package boundaries, or clever error-swallowing abstractions.
- **Rule 5 (Measure Before Optimizing)**: Speed hacks and algorithmic refactors MUST NOT be merged without repeatable benchmark numbers proving where the bottleneck resides (Rules 1 & 2: "You can't tell where a program is going to spend its time... Don't tune for speed until you've measured").
- **Rule 6 (Dependency Discipline)**: Trivial utilities MUST be copied or implemented directly rather than importing external packages ("A little copying is better than a little dependency").

## 3. Code Review Checklist
- [ ] **Data Structure Bloat**: Has a complex data structure (skip list, red-black tree, lock-free ring buffer) been written where a plain array, slice, or hash map would suffice?
- [ ] **Shared Memory Orchestration**: Are goroutines/threads coordinating state transitions through shared mutable memory and condition variables instead of message channels?
- [ ] **Bloated Interface Contract**: Does an interface require implementers to satisfy dozens of methods instead of splitting into tiny, composable behaviors?
- [ ] **Clever Meta-Programming**: Does the implementation rely on runtime reflection (`reflect`), dynamic code generation, or heavy magic macros rather than explicit static code?
- [ ] **Panic Across Boundaries**: Does a package routine raise an unhandled panic or exception instead of returning `(Result, error)` to the caller?
- [ ] **Gratuitous Dependency**: Has a new external library been added to the build graph for a utility function under 30 lines?

## 4. Canonical Idiom (Reference Pattern)

### REJECTED: Over-abstracted OOP class hierarchy with shared-memory locking and reflection
```go
// REJECTED: Enterprise abstraction with giant interface, mutex orchestration, and panic
package service

import "sync"

type ComplexWorkerService interface {
	InitializeWorkerPool() error
	DispatchTask(taskID string, payload interface{}) (interface{}, error)
	PauseAllWorkers() error
	ResumeAllWorkers() error
	Shutdown() error
}

type ThreadPoolManager struct {
	mu    sync.Mutex
	state map[string]interface{} // Shared mutable state requiring lock
}

func (m *ThreadPoolManager) DispatchTask(taskID string, payload interface{}) (interface{}, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if payload == nil {
		panic("invalid payload") // Panic used for control flow
	}
	m.state[taskID] = payload
	return m.state[taskID], nil
}
```

### ACCEPTED: Minimal single-method interface with CSP channel pipeline and explicit error values
```go
// ACCEPTED: Canonical Pike/Go idiom (Clear is better than clever, errors are values)
package service

import (
	"context"
	"errors"
)

var ErrInvalidPayload = errors.New("worker: payload cannot be nil")

// Tiny, single-method interface (1-2 methods maximum)
type Consumer interface {
	Consume(ctx context.Context, data []byte) error
}

// Channel orchestrates; no shared memory mutex contention
type Pipe struct {
	tasks chan []byte
}

func NewPipe(bufSize int) *Pipe {
	return &Pipe{
		tasks: make(chan []byte, bufSize),
	}
}

func (p *Pipe) Push(ctx context.Context, data []byte) error {
	if len(data) == 0 {
		return ErrInvalidPayload // Errors are values, handled explicitly
	}
	select {
	case p.tasks <- data:
		return nil
	case <-ctx.Done():
		return ctx.Err()
	}
}
```
