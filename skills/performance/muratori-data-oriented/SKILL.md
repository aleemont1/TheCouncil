---
name: muratori-data-oriented
description: "Mechanical sympathy and data-oriented design discipline rejecting 'Clean Code' abstractions, virtual method tables, and defensive caching in favor of contiguous cache locality, table-driven switch dispatch, SIMD vectorization, and on-demand recomputation."
triggers: ["data-oriented-design", "clean-code-critique", "recompute-everything", "cache-locality", "simd-vectorization", "hot-path"]
conflicts_with: ["architecture/fowler-evolutionary-design", "systems/stenberg-defensive-c"]
primary_sources:
  - title: "Clean Code, Horrible Performance"
    url: "https://www.computerenhance.com/p/clean-code-horrible-performance"
  - title: "Recompute Everything (Alternative to Caching)"
    url: "https://www.computerenhance.com/p/recompute-everything-or-how-to-go"
---

# Casey Muratori: Data-Oriented Design & Hardware-Sympathetic Performance

## 1. Core Philosophy & Deliberate Rejections
- **Prioritizes**: Mechanical sympathy with CPU hardware (L1/L2/L3 cache lines, prefetchers, branch predictors, SIMD/AVX vector units), contiguous memory layouts (flat buffers, Struct-of-Arrays), recomputing values on the fly over complex invalidating caches, and optimizing for the transformational center of the loop.
- **Rejects**: Robert C. Martin "Clean Code" dogmas; polymorphism via virtual method tables (`VTBL`) in hot loops (which causes pointer chasing, disables compiler inlining, and prevents SIMD vectorization, inducing 15x–25x slowdowns); granular micro-functions that destroy loop locality; arrays of pointers to individual heap allocations (`BaseClass**`); and defensive caching of simple derived values that causes synchronization bugs and DRAM latency bottlenecks.
- **Primary Trade-off**: Sacrifices traditional object-oriented "Open-Closed" extensibility and textbook subclass hierarchies in exchange for hardware-saturating performance, predictable execution times, and eradication of memory latency stalls.

## 2. Hard Implementation Rules
- **Rule 1 (Contiguous Memory Layout)**: Collections processed in loops MUST be laid out contiguously in memory as flat arrays of structs or struct-of-arrays. Code MUST NOT process collections via arrays of pointers (`Entity**`) that force pointer dereferencing on every element.
- **Rule 2 (Table/Switch Over Virtual Functions)**: Inner loops MUST use concrete types with enum discrimination, table-driven coefficients, or switch statements instead of virtual functions or interface dynamic dispatch.
- **Rule 3 (Recompute Over Caching)**: Developers MUST prefer recomputing derived values from base parameters inside the loop over creating cached fields, dirty flags, and invalidation schemes, unless the computation is empirically proven to be heavier than a DRAM cache miss (~200 cycles).
- **Rule 4 (SIMD Vectorization Alignment)**: Loops performing numerical accumulation or filtering MUST be structured without loop-carried dependencies or opaque function call boundaries, enabling auto-vectorization into AVX2/AVX-512 instructions.
- **Rule 5 (Cache Line Density)**: Fields in structures MUST be packed so that variables read together reside on the same 64-byte cache line. Infrequently read metadata MUST NOT be co-located with high-frequency hot data.

## 3. Code Review Checklist
- [ ] **Pointer-Chasing Loops**: Does a loop iterate through an array of pointers (`Shape**`, `vector<unique_ptr<T>>`), causing a cache miss per item?
- [ ] **Dynamic Dispatch in Hot Path**: Is a virtual method call (`->Area()`) invoked inside a loop over hundreds or thousands of elements?
- [ ] **Premature Caching Bloat**: Are boolean flags, cached bounding boxes, or memoized values stored in structs when they could be calculated in 2 ALU cycles?
- [ ] **Fragmented Micro-Methods**: Has a single continuous computational loop been chopped up into 5 private helper methods, inhibiting compiler inlining and vectorization?
- [ ] **Polymorphic Data Inefficiency**: Are heterogeneous objects given independent heap allocations rather than grouped into a tagged union or distinct contiguous type buffers?

## 4. Canonical Idiom (Reference Pattern)

### REJECTED: "Clean Code" class hierarchy with virtual functions and array of pointers
```cpp
// REJECTED: Clean Code style causing 15x-25x performance degradation
class Shape {
public:
    virtual float Area() = 0; // Virtual dispatch inhibits inlining and SIMD
};

class Square : public Shape {
    float Side;
public:
    Square(float s) : Side(s) {}
    float Area() override { return Side * Side; }
};

class Circle : public Shape {
    float Radius;
public:
    Circle(float r) : Radius(r) {}
    float Area() override { return 3.14159f * Radius * Radius; }
};

// Processing requires array of POINTERS: cache misses on every dereference
float TotalAreaVTBL(uint32_t count, Shape **shapes) {
    float accum = 0.0f;
    for (uint32_t i = 0; i < count; ++i) {
        accum += shapes[i]->Area(); // Pointer chasing + vtable jump
    }
    return accum;
}
```

### ACCEPTED: Data-oriented flat tagged array with coefficient table and contiguous layout
```cpp
// ACCEPTED: Casey Muratori canonical data-oriented pattern
#include <stdint.h>

enum ShapeType : uint32_t {
    Shape_Square,
    Shape_Rectangle,
    Shape_Triangle,
    Shape_Circle,
    Shape_Count
};

struct ShapeUnion {
    ShapeType Type;
    float Width;
    float Height;
};

// Coefficient table eliminates branching entirely
static const float CTable[Shape_Count] = {
    1.0f,       // Square: Width * Width
    1.0f,       // Rectangle: Width * Height
    0.5f,       // Triangle: 0.5 * Width * Height
    3.14159265f // Circle: Pi * Radius * Radius
};

// Contiguous memory pass: 100% cache-line friendly, vectorizable by compiler
float TotalAreaDOD(uint32_t count, const ShapeUnion *shapes) {
    float accum = 0.0f;
    for (uint32_t i = 0; i < count; ++i) {
        accum += CTable[shapes[i].Type] * shapes[i].Width * shapes[i].Height;
    }
    return accum;
}
```
