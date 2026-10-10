---
name: ousterhout-deep-modules
description: "Software design methodology maximizing the ratio of functionality provided to interface complexity, championing deep modules, information hiding, and defining errors out of existence while rejecting shallow classitis and pass-through methods."
triggers: ["deep-modules", "information-hiding", "classitis", "pass-through-methods", "define-errors-out-of-existence", "complexity-reduction"]
conflicts_with: ["architecture/fowler-evolutionary-design", "systems/pike-unix-minimalism", "architecture/uncle-bob-solid-orthodox"]
primary_sources:
  - title: "Deep Modules & Complexity Lectures"
    url: "https://web.stanford.edu/~ouster/cgi-bin/cs190-spring20/lecture.php?topic=modularDesign"
  - title: "Red Flags in Software Design"
    url: "https://web.stanford.edu/~ouster/cgi-bin/cs190-spring20/lecture.php?topic=redFlags"
---

# John Ousterhout: Deep Modules & Complexity Minimization

## 1. Core Philosophy & Deliberate Rejections
- **Prioritizes**: Deep modules (maximizing functionality provided relative to interface complexity), information hiding (Parnas principle: encapsulating design decisions so internal changes do not ripple), strategic programming (investing 10–20% continuously to simplify design rather than tactical hacking), and defining errors out of existence (designing APIs where edge cases become natural normal behavior).
- **Rejects**: Shallow modules and "Classitis" (the disease of fragmenting logic into dozens of tiny classes/methods where the interface cost equals the implementation value, typified by Java I/O streams); pass-through methods (methods that simply forward calls to an underlying object without adding value); information leakage across module boundaries; temporal decomposition (structuring classes based on the execution order of operations rather than information hiding); and defensive exception throwing that punts complexity to the caller.
- **Primary Trade-off**: Sacrifices extreme micro-modularity dogmas (such as dogmatic "classes must be under 30 lines") in exchange for dramatically lower cognitive load, fewer inter-class dependencies, and modules that can be understood in isolation.

## 2. Hard Implementation Rules
- **Rule 1 (Maximize Module Depth)**: Modules MUST be deep: the ratio of $\frac{\text{functionality}}{\text{interface complexity}}$ MUST be as high as possible. If an interface exposes nearly as much mental overhead as its implementation, the module is shallow and MUST be merged with its collaborators or given deeper responsibility.
- **Rule 2 (Strict Information Hiding)**: Design decisions (e.g., serialization formats, file layout, concurrency models, caching policies) MUST be entirely hidden within a single module. Interfaces MUST NOT leak internal implementation details or force callers to understand internal invariants.
- **Rule 3 (Eliminate Pass-Through Methods)**: Classes MUST NOT contain methods whose sole function is to forward arguments to an underlying delegate with the same signature. When pass-through methods appear, the classes MUST be merged or their division of responsibility reorganized.
- **Rule 4 (Define Errors Out of Existence)**: APIs MUST be designed so that abnormal situations and edge cases have natural, valid definitions without throwing exceptions (e.g., string slicing clamping out-of-bounds indices, unsetting an already non-existent key returning cleanly). Developers MUST NOT throw exceptions that force callers to write defensive try/catch clutter.
- **Rule 5 (Strategic Programming Over Tactical Hacks)**: Code changes MUST NOT take short-term tactical shortcuts that accumulate dependencies. Developers MUST allocate time to improve the overarching module seams during everyday development.

## 3. Code Review Checklist
- [ ] **Shallow Classitis**: Is a class so thin that its public method signatures require more code to invoke and document than the actual logic executed inside?
- [ ] **Pass-Through Method Red Flag**: Does a method do nothing except delegate directly to another object with identical arguments and return types?
- [ ] **Information Leakage**: Does changing a private detail (like a cache replacement policy or disk structure) require modifications across multiple external classes?
- [ ] **Temporal Decomposition**: Are classes separated by execution sequence (e.g., `Validator`, then `Extractor`, then `Loader`) instead of encapsulating shared domain knowledge?
- [ ] **Exception Punting**: Does an API method throw exceptions for benign or boundary conditions (e.g., `ElementNotFoundException`, `IndexOutOfBoundsException`) instead of defining an intuitive default behavior?

## 4. Canonical Idiom (Reference Pattern)

### REJECTED: Shallow classitis with pass-through forwarding and exception throwing
```java
// REJECTED: Shallow modules, pass-through methods, and exception throwing
class FileBufferReader {
    private DiskStream diskStream;
    public FileBufferReader(DiskStream ds) { this.diskStream = ds; }
    // Pass-through method: adds zero abstraction depth
    public byte[] readRaw(int bytes) throws IOException {
        return diskStream.readBytes(bytes);
    }
}

class TextSegmenter {
    // Throws exceptions for benign out-of-bounds indexing
    public String extractRange(String text, int start, int end) throws OutOfBoundsException {
        if (start < 0 || end > text.length() || start > end) {
            throw new OutOfBoundsException("Invalid range"); // Forces caller try/catch clutter
        }
        return text.substring(start, end);
    }
}
```

### ACCEPTED: Deep module hiding buffering, disk I/O, and defining errors out of existence
```python
# ACCEPTED: Canonical Ousterhout deep module pattern
import os

class DocumentCache:
    """
    A deep module: simple 2-method interface hiding caching, disk I/O,
    file locking, and memory reclamation. Errors are defined out of existence.
    """
    def __init__(self, base_dir: str):
        self._base_dir = base_dir
        self._memory_cache = {}

    def get_slice(self, filename: str, start: int, length: int) -> str:
        """
        Retrieves text slice.
        Defines errors out of existence:
        - Non-existent file returns empty string (no exception).
        - Out-of-bounds indices are safely clamped.
        """
        if filename not in self._memory_cache:
            path = os.path.join(self._base_dir, filename)
            if not os.path.exists(path):
                return ""  # Error defined out of existence
            with open(path, "r", encoding="utf-8", errors="ignore") as f:
                self._memory_cache[filename] = f.read()

        content = self._memory_cache[filename]
        # Range clamping defines out-of-bounds errors out of existence
        safe_start = max(0, min(start, len(content)))
        safe_end = max(safe_start, min(safe_start + max(0, length), len(content)))
        return content[safe_start:safe_end]

    def delete(self, filename: str) -> None:
        """
        Deletes document. If file does not exist, operation is an idempotent no-op.
        No exception thrown.
        """
        self._memory_cache.pop(filename, None)
        path = os.path.join(self._base_dir, filename)
        try:
            os.remove(path)
        except FileNotFoundError:
            pass  # Already gone, mission accomplished
```
