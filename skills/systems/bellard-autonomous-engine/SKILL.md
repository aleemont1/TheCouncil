---
name: bellard-autonomous-engine
description: "Systems architecture discipline creating radically compact, autonomous, dependency-free monolithic C engines utilizing single-pass execution, embedded interpreters, and unified binary design."
triggers: ["autonomous-engine", "zero-external-dependencies", "single-pass-execution", "compact-c-architecture", "quickjs-tcc-style", "micro-runtime"]
conflicts_with: ["architecture/fowler-evolutionary-design", "architecture/uncle-bob-solid-orthodox"]
primary_sources:
  - title: "QuickJS Architecture"
    url: "https://bellard.org/quickjs/"
  - title: "TinyCC (tcc) Implementation Overview"
    url: "https://bellard.org/tcc/"
---

# Fabrice Bellard: Autonomous Monolithic Engines & Compact Single-Pass Execution

## 1. Core Philosophy & Deliberate Rejections
- **Prioritizes**: Radically compact, self-contained monolithic C engines (e.g., QuickJS, TinyCC, FFmpeg, QEMU); absolute zero external runtime dependencies; single-pass compilation and interpretation without intermediate representation bloat (TCC compiles 9x faster than GCC by generating machine code directly from a single pass); sub-millisecond instance lifecycles (< 300 microseconds for complete runtime startup/teardown in QuickJS); and direct, transparent manipulation of memory and hardware registers.
- **Rejects**: Bloated multi-pass compiler architectures (such as LLVM's hundreds of intermediate passes and multi-gigabyte memory footprints for basic tasks); massive C++ template frameworks and complex class hierarchies (e.g., V8's massive codebase vs QuickJS's compact C source); multi-tiered third-party dependency graphs; and premature decomposition of cohesive system engines into micro-packages.
- **Primary Trade-off**: Sacrifices marginal, theoretical micro-optimizations achieved by complex multi-pass optimizing compilers in exchange for instantaneous compilation speed, trivial embedded distribution, featherweight memory footprints, and total architectural autonomy.

## 2. Hard Implementation Rules
- **Rule 1 (Zero External Dependencies)**: Core engines MUST compile cleanly with a standard C compiler without requiring external third-party libraries, package managers, or complex runtimes.
- **Rule 2 (Single-Pass Execution Simplicity)**: Compilers, parsers, and interpreters MUST favor single-pass direct evaluation or compact bytecode generation over heavyweight abstract syntax trees (ASTs) that require multi-gigabyte memory allocations.
- **Rule 3 (Instant Startup Lifecycles)**: System runtimes MUST initialize and tear down in under a millisecond. Systems MUST NOT mandate background daemon bootup, warm-up iterations, or heavy JIT compilation overhead for straightforward tasks.
- **Rule 4 (Self-Contained Engine Packaging)**: An engine (e.g., a compiler, JS engine, emulator, or media codec) MUST be structured into a cohesive set of single-purpose C files that can be directly compiled into a single executable or embedded as a single `.h`/`.c` pairing.
- **Rule 5 (Memory Efficiency and Predictable Footprints)**: Engines MUST operate within tiny memory budgets (e.g., ~100KB to 400KB executable size for complete compilers or runtimes). Uncontrolled dynamic memory expansion MUST NOT be permitted.

## 3. Code Review Checklist
- [ ] **External Dependency Bloat**: Has a third-party dependency been introduced for a routine (e.g., hashing, parsing, dynamic array) that can be implemented cleanly in 50 lines of C?
- [ ] **Over-Engineered Multi-Pass Parsing**: Does an interpreter or translator construct massive, multi-tiered AST hierarchies with dozens of visitor passes when a single-pass streaming parser would suffice?
- [ ] **Sluggish Runtime Initialization**: Does starting up an instance of the engine require multiple seconds of configuration parsing, plugin discovery, and memory pre-allocation?
- [ ] **Fragmented Package Proliferation**: Has a cohesive engine been fractured into 15 small separate repositories and packages, making cross-cutting modifications painful?
- [ ] **Giant Binary Footprint**: Has the resulting binary swollen to dozens of megabytes due to unnecessary runtime frameworks or template bloat?

## 4. Canonical Idiom (Reference Pattern)

### REJECTED: Multi-pass AST with visitor patterns, dynamic wrappers, and heavy dependencies
```cpp
// REJECTED: Over-abstracted compiler with AST nodes, visitors, and multi-pass overhead
#include <memory>
#include <vector>

class ASTVisitor;
class ASTNode {
public:
    virtual void accept(ASTVisitor *v) = 0; // Dynamic dispatch for every token!
};

class BinaryOpNode : public ASTNode {
public:
    int op;
    std::unique_ptr<ASTNode> left;
    std::unique_ptr<ASTNode> right;
    void accept(ASTVisitor *v) override;
};

// Requires 10 passes, thousands of heap allocations, and external LLVM dependencies...
```

### ACCEPTED: Single-pass direct code generation with compact memory footprint (TCC / Bellard style)
```c
/* ACCEPTED: Canonical Bellard / TinyCC idiom: Single-pass lexing and direct byte emission */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#define TOK_NUM  256
#define TOK_PLUS '+'

static const char *src = "40 + 2";
static int token;
static int tok_val;

/* Featherweight single-pass lexer */
static void next_token(void) {
    while (*src == ' ') src++;
    if (*src >= '0' && *src <= '9') {
        token = TOK_NUM;
        tok_val = 0;
        while (*src >= '0' && *src <= '9') {
            tok_val = tok_val * 10 + (*src++ - '0');
        }
    } else {
        token = *src++;
    }
}

/* Single-pass evaluator/emitter: Zero intermediate AST, zero dynamic heap allocations! */
int compile_and_eval_single_pass(void) {
    next_token();
    if (token != TOK_NUM) {
        fprintf(stderr, "syntax error\n");
        exit(1);
    }
    int result = tok_val;
    next_token();
    while (token == TOK_PLUS) {
        next_token();
        if (token != TOK_NUM) exit(1);
        result += tok_val; // Direct single-pass computation/emission
        next_token();
    }
    return result;
}
```
