---
name: carmack-inlined-execution
description: "Simulation architecture discipline championing linear top-to-bottom inlined code execution, forward-only control flow, single polled main loops, and pragmatic pure functional C++ to eliminate hidden state mutation."
triggers: ["inlined-execution", "polled-simulation-loop", "forward-only-control-flow", "functional-cpp", "state-mutation-elimination", "linear-code-flow"]
conflicts_with: ["architecture/fowler-evolutionary-design", "architecture/uncle-bob-solid-orthodox"]
primary_sources:
  - title: "Inlined Code vs Deep Call Stacks"
    url: "http://number-none.com/blow/blog/programming/2014/09/26/carmack-on-inlined-code.html"
  - title: "Functional Programming in C++"
    url: "https://raw.githubusercontent.com/ESWAT/john-carmack-plan-archive/master/by_year/plan_2013.txt"
---

# John Carmack: Inlined Execution & Polled Simulation Loops

## 1. Core Philosophy & Deliberate Rejections
- **Prioritizes**: Linear top-to-bottom execution flow (Style C: inlining sequential routines directly into the calling pipeline), forward-only control flow inspired by aerospace flight control systems (e.g., Saab Gripen fly-by-wire software with zero backward branches in the main tick), deterministic single-threaded polled loops over preemptive RTOS threads, and pragmatic functional C++ (maximizing pure functions that take values and return values without mutating internal or global state).
- **Rejects**: Splitting sequential, single-call execution code into dozens of tiny "minor" functions (which introduces severe cognitive context-switching, conceals temporal state mutations, causes redundant variable updates, and hides variable lifecycles); deep call stacks in simulation frames; complex preemptive multithreading where a polled frame tick is far more reliable; and object-oriented methods that silently mutate hidden member state.
- **Primary Trade-off**: Sacrifices textbook dogmas of short function length (functions may span hundreds of lines of linear sequential logic) in exchange for total visibility into state transitions, elimination of hidden mutations, and rock-solid simulation repeatability.

## 2. Hard Implementation Rules
- **Rule 1 (Inline Sequential Pipelines)**: Code that executes sequentially once per frame/tick MUST be written in-line top-to-bottom within the primary execution block. Developers MUST NOT extract single-use code blocks into artificial helper methods purely to achieve arbitrary line-count limits.
- **Rule 2 (Forward-Only Control Flow)**: Real-time simulation and control loops MUST minimize backward jumps and call nesting. State transitions MUST flow forward through static or frame-scoped buffers.
- **Rule 3 (Functional Purity When Factoring)**: When code is factored out of a linear block, it MUST be extracted as a pure function (taking explicit input parameters by value or `const&`, returning an immutable result, and causing zero side effects). Functions MUST NOT be factored out if they depend on or mutate implicit member/global variables.
- **Rule 4 (Polled Loop Over Preemption)**: High-frequency simulation and real-time control engines MUST drive execution through a deterministic polled loop. Concurrency MUST NOT use complex preemptive threading or event-driven thread pools when a single polled loop with non-blocking I/O can satisfy latency guarantees.
- **Rule 5 (Explicit State Lifecycles)**: Intermediate variables MUST be scoped locally within the inlined block, making initialization, usage, and deallocation visible in a single screen-scroll. Developers MUST NOT promote temporary pipeline variables into object member variables.

## 3. Code Review Checklist
- [ ] **Single-Call Indirection Smell**: Has a 10-line block of linear logic that is called from exactly one place been extracted into a private method, forcing the reader to jump across files?
- [ ] **Hidden State Mutation**: Does a helper method mutate member variables (`this->m_state`) without requiring the caller to pass them explicitly as parameters?
- [ ] **Redundant State Assignment**: When reading the linear control flow, are variables assigned multiple times or left in indeterminate intermediate states?
- [ ] **Deep Stack in Frame Tick**: Does the primary simulation loop recurse or descend through 15 layers of nested call stacks during a single physics or render frame?
- [ ] **Preemptive Threading Complexity**: Has an RTOS or thread pool with mutex locking been introduced where a polled, non-blocking single-loop design would be deterministic?

## 4. Canonical Idiom (Reference Pattern)

### REJECTED: Fragmented helper methods with hidden state mutations and deep call stack
```cpp
// REJECTED: Style A - Fragmented helpers hiding state mutation and variable lifecycle
class RocketSimulation {
    float m_fuel;
    float m_thrust;
    float m_altitude;
    bool m_valvesOpen;

    void updateValves() {
        // Hidden mutation of member state
        m_valvesOpen = (m_fuel > 0.0f);
    }
    void calculateThrust() {
        // Depends implicitly on state set by updateValves()
        m_thrust = m_valvesOpen ? 5000.0f : 0.0f;
    }
    void updateAltitude(float dt) {
        // Another hidden mutation
        m_altitude += (m_thrust / 1000.0f) * dt;
    }
public:
    void tick(float dt) {
        // Three subroutine jumps; variable lifetimes and dependencies are totally obscured!
        updateValves();
        calculateThrust();
        updateAltitude(dt);
    }
};
```

### ACCEPTED: Top-to-bottom inlined execution with forward-only flow and pure math functions
```cpp
// ACCEPTED: Canonical Carmack inlined execution (Style C) with functional purity
struct SimState {
    float fuel;
    float altitude;
};

// Pure function: takes input, returns result, zero hidden mutations
static inline float computeThrust(float fuelRemaining) {
    return (fuelRemaining > 0.0f) ? 5000.0f : 0.0f;
}

void tickSimulationInlined(SimState &state, float dt) {
    /* 
     * Top-to-bottom sequential flow:
     * All dependencies, variable lifetimes, and state updates are explicitly visible.
     * Forward-only control flow eliminates call-stack overhead and hidden mutations.
     */
    const float fuel = state.fuel;
    const float thrust = computeThrust(fuel);
    
    // Inlined physics integration
    const float burnRate = (thrust > 0.0f) ? 10.0f * dt : 0.0f;
    const float updatedFuel = (fuel > burnRate) ? fuel - burnRate : 0.0f;
    const float updatedAltitude = state.altitude + (thrust / 1000.0f) * dt;

    // Single deterministic state write at end of frame
    state.fuel = updatedFuel;
    state.altitude = updatedAltitude;
}
```
