---
name: stenberg-defensive-c
description: "Defensive systems programming discipline adhering to strict C89 portability, warning-free cross-compilation, explicit error code propagation, state-machine protocol parsing, and disciplined vulnerability lifecycle."
triggers: ["defensive-c", "libcurl-style", "cross-platform-portability", "c89-compliance", "vulnerability-lifecycle", "protocol-state-machine"]
conflicts_with: ["resilience/armstrong-fault-isolation", "performance/muratori-data-oriented"]
primary_sources:
  - title: "HTTP/3 Explained"
    url: "https://http3-explained.haxx.se/"
  - title: "Security Vulnerability Process"
    url: "https://daniel.haxx.se/blog/2021/08/27/the-curl-security-vulnerability-process/"
  - title: "libcurl C Code Guidelines"
    url: "https://curl.se/dev/code-style.html"
---

# Daniel Stenberg: Defensive C & Universal Portability

## 1. Core Philosophy & Deliberate Rejections
- **Prioritizes**: Strict C89 standard compliance, warning-free cross-compilation across hundreds of operating systems and CPU architectures, explicit error propagation via typed return codes (`CURLcode`), defensive cleanup idioms (`Curl_safefree`), non-blocking state machine protocol parsers, and rock-solid library boundaries where no input can ever crash the host process.
- **Rejects**: Non-portable compiler extensions (e.g., Variable-Length Arrays `VLA`, non-standard GCC/Clang built-ins); termination in library routines (`exit()`, `abort()`, unhandled `assert()` in release builds); inlined variable assignments within conditional statements (`if ((p = malloc(n)) == NULL)`); implicit error swallowing; and C99 single-line `//` comments in portable C89 source.
- **Primary Trade-off**: Sacrifices modern syntactic convenience and rapid prototyping speed to guarantee decades-long backward compatibility, zero crash footprint in shared library address spaces, and flawless portability from embedded microcontrollers to supercomputers.

## 2. Hard Implementation Rules
- **Rule 1 (Explicit Return Codes)**: Every function performing I/O, allocation, or parsing MUST return a strongly-typed status enum (e.g., `CURLcode`). Functions MUST NOT convey errors via sentinel payload values or uninspected global state (`errno`).
- **Rule 2 (No Assignments in Conditionals)**: Allocation, initialization, and evaluation MUST be split into distinct statements. Programmers MUST NOT embed assignments inside conditional expressions (`if`, `while`, `switch`).
- **Rule 3 (Defensive Pointer Nullification)**: Deallocated memory MUST be freed using a safe-free pattern that evaluates pointer validity, invokes free, and immediately sets the target pointer to `NULL` to eradicate use-after-free and double-free vulnerabilities.
- **Rule 4 (Never Abort the Host)**: Library routines MUST NOT call `exit()`, `abort()`, or terminal panics. Corrupted network frames, malformed headers, or transient OS failures MUST be converted into descriptive error codes and returned gracefully to the caller.
- **Rule 5 (Non-Blocking Incremental State Machines)**: Protocol parsing (such as HTTP frame decoders or QUIC streams) MUST be structured as bounded state machines consuming variable-length byte chunks. Code MUST NOT assume complete network messages exist in a single contiguous buffer or use blocking recursion.
- **Rule 6 (Feature Checks Over OS Assumptions)**: Platform-dependent logic MUST be guarded by feature flags generated during configuration (e.g., `#ifdef HAVE_SOCKET`) rather than brittle operating system or compiler brand macros (`#ifdef __LINUX__`).

## 3. Code Review Checklist
- [ ] **Embedded Assignment**: Is an assignment contained inside an `if` condition (e.g., `if (result = parse_header())`) instead of evaluating on a dedicated line?
- [ ] **Unchecked Error Return**: Does any function ignore the return code of an allocation, system call, or downstream parser?
- [ ] **Host Process Abort**: Does any code path call `exit()`, `abort()`, or throw an unhandled assertion that terminates the consuming application upon bad network input?
- [ ] **Dangling Pointer Smell**: Is `free(ptr)` invoked without immediately clearing `ptr = NULL`, leaving an exploitable use-after-free surface?
- [ ] **Non-Portable Syntax**: Are C99 variable-length arrays, modern inline syntax, or non-portable compiler attributes used in code required to remain C89-compliant?

## 4. Canonical Idiom (Reference Pattern)

### REJECTED: Mainstream C with assignment in condition, unhandled returns, and termination on failure
```c
/* REJECTED: Non-defensive style violating libcurl guidelines */
#include <stdlib.h>
#include <stdio.h>

int parse_packet(char *data, int len) {
    char *buf;
    // REJECTED: Assignment inside condition
    if ((buf = malloc(len)) == NULL) {
        // REJECTED: Terminating the host process in library code
        perror("Fatal memory allocation failure");
        exit(1); 
    }
    
    // REJECTED: Unchecked parsing and raw free leaving dangling pointer
    process_payload(buf, data, len);
    free(buf); // Dangerous: buf retains freed memory address
    return 1;
}
```

### ACCEPTED: Defensive C with separate allocation, safe-free macro, and explicit error codes
```c
/* ACCEPTED: Canonical Stenberg / libcurl defensive pattern */
#include <stdlib.h>
#include <stddef.h>

typedef enum {
    CURLE_OK = 0,
    CURLE_OUT_OF_MEMORY,
    CURLE_BAD_FUNCTION_ARGUMENT,
    CURLE_RECV_ERROR
} CURLcode;

#define Curl_safefree(ptr) do { \
    if((ptr)) { \
        free((ptr)); \
        (ptr) = NULL; \
    } \
} while(0)

CURLcode Curl_parse_packet(const unsigned char *data, size_t len, unsigned char **out_buf)
{
    unsigned char *buf;

    if(!data || !len || !out_buf)
        return CURLE_BAD_FUNCTION_ARGUMENT;

    /* Allocation isolated from conditional */
    buf = malloc(len);
    if(!buf)
        return CURLE_OUT_OF_MEMORY; /* Graceful error return, no abort */

    /* Copy and validate without crashing host */
    for(size_t i = 0; i < len; i++) {
        buf[i] = data[i];
    }

    *out_buf = buf;
    return CURLE_OK;
}

void Curl_cleanup_packet(unsigned char **buf)
{
    if(buf) {
        Curl_safefree(*buf); /* Pointer cleared to NULL immediately */
    }
}
```
