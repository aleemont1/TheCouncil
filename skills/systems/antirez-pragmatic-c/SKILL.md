---
name: antirez-pragmatic-c
description: "Pragmatic C: single-threaded event loop, mechanical sympathy, zero dependencies, flat in-memory data structures, readable code. Use when designing in-memory servers or network daemons, or weighing threads and locks against one loop."
triggers: ["event-loop", "single-threaded", "in-memory", "pragmatic-c", "zero-dependency", "redis-architecture"]
conflicts_with: ["architecture/fowler-evolutionary-design", "state/hickey-simple-values"]
primary_sources:
  - title: "Redis Architecture"
    url: "http://antirez.com/news/119"
  - title: "Optimization Philosophy ('The code you don't write')"
    url: "http://antirez.com/news/78"
  - title: "Smallchat Reference C Implementation"
    url: "https://raw.githubusercontent.com/antirez/smallchat/master/smallchat.c"
---

# Salvatore Sanfilippo: Pragmatic In-Memory Systems & Single-Threaded Simplicity

**Apply**: write or review the target under Sections 2 and 3. Done when every rule is either satisfied or reported as violated, and every checklist item is marked hit (with `file:line`) or clear. When a rule collides with a stated requirement, name the trade-off from Section 1 rather than bending the rule silently.

## 1. Core Philosophy & Deliberate Rejections
- **Prioritizes**: Single-threaded event-driven execution (`ae.c` event loop multiplexing via `epoll`/`kqueue`/`select`), absolute command atomicity without mutexes, mechanical sympathy with memory hierarchies, predictable sub-millisecond tail latencies, zero-dependency self-contained C codebases, and radical readability.
- **Rejects**: Multi-threaded shared-memory architectures with fine-grained mutexes or read-write locks for core data operations (which introduce lock contention, cache-line bouncing, deadlocks, and nondeterministic races); enterprise object-relational mapping and layered wrappers; bloated third-party dependencies; premature multi-tiered abstractions when a simple flat data structure suffices.
- **Primary Trade-off**: Sacrifices automatic multi-core CPU scaling within a single process (scaling requires running multiple single-threaded processes or cluster sharding) in exchange for zero lock overhead, deterministic execution traces, and bug-free atomic state mutations.

## 2. Hard Implementation Rules
- **Rule 1 (Concurrency Boundary)**: State mutations and client command processing MUST execute within a single-threaded non-blocking event loop. Developers MUST NOT introduce mutexes, condition variables, or shared-memory thread contention into the core state machine.
- **Rule 2 (Flat Indexing Over Indirection)**: Network connection tables MUST prefer flat arrays directly indexed by the OS socket file descriptor (e.g., `state->clients[fd]`) or contiguous tables rather than heap-allocated hash tables or linked lists for active client tracking.
- **Rule 3 (Safe Length-Prefixed Buffers)**: Dynamic byte sequences and protocol frames MUST utilize length-prefixed string buffers (patterned after SDS - Simple Dynamic Strings) storing buffer length and free space in an explicit header. Code MUST NOT use raw unbounded C string functions (`strcpy`, `strcat`, `sprintf`) on incoming network payloads.
- **Rule 4 (Fail-Fast Memory Life Cycle)**: Memory allocations MUST go through explicit wrappers (e.g., `zmalloc` or `chatMalloc`) that enforce accounting and terminate immediately on out-of-memory errors (`OOM`). Code MUST NOT scatter fragile, unrecoverable NULL pointer checks across deep computational call stacks.
- **Rule 5 (Self-Contained Dependencies)**: Core network servers and storage engines MUST vendor or directly implement their minimal protocol parsers and data structures. Third-party runtime dependencies MUST NOT be introduced for functionality achievable in concise, standard POSIX C.

## 3. Code Review Checklist
- [ ] **Thread Contention Smell**: Are POSIX threads and mutexes introduced to parallelize state updates that could execute orders of magnitude faster sequentially in a single-threaded event loop?
- [ ] **Indirect Connection Lookups**: Does the network server search a linked list or hash table on every incoming packet instead of directly indexing the client by socket file descriptor (`clients[fd]`)?
- [ ] **Unbounded String Scanning**: Does string manipulation scan for null terminators ($O(N)$ `strlen`) on hot network paths instead of maintaining explicit length prefixes?
- [ ] **Silent Allocation Failure**: Does an allocation routine return a NULL pointer that is ignored or inconsistently bubbled up rather than caught at the allocation boundary?
- [ ] **Over-Engineered Indirection**: Is a complex object graph or plugin framework being constructed where a plain C `struct` with direct field access would be transparent and mechanically sympathetic?

## 4. Canonical Idiom (Reference Pattern)

### REJECTED: Multi-threaded connection pool with mutex contention and linked-list lookups
```c
/* REJECTED: Thread-per-client or multi-threaded shared state requiring mutex locking */
#include <pthread.h>
#include <stdlib.h>

struct ClientNode {
    int fd;
    char *buffer;
    struct ClientNode *next;
};

struct ServerState {
    pthread_mutex_t lock;
    struct ClientNode *head;
};

void broadcast(struct ServerState *s, const char *msg) {
    pthread_mutex_lock(&s->lock); // Thread contention and lock overhead on every send
    struct ClientNode *curr = s->head;
    while (curr) {
        // Linked-list traversal causes CPU cache misses
        send(curr->fd, msg, strlen(msg), 0); // O(N) strlen scan
        curr = curr->next;
    }
    pthread_mutex_unlock(&s->lock);
}
```

### ACCEPTED: Single-threaded event-driven state with direct descriptor array indexing
```c
/* ACCEPTED: Canonical antirez idiom (smallchat / Redis ae pattern) */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <assert.h>
#include <sys/select.h>

#define MAX_CLIENTS 1024

struct client {
    int fd;
    char *nick;
    size_t nicklen;
};

struct chatState {
    int maxfd;
    int numclients;
    struct client *clients[MAX_CLIENTS]; // Direct FD lookup: O(1) cache-friendly
};

static struct chatState Chat;

void *chatMalloc(size_t size) {
    void *ptr = malloc(size);
    if (!ptr) {
        perror("Out of memory");
        exit(1); // Fail-fast allocation policy
    }
    return ptr;
}

void handleClientWrite(int sender_fd, const char *msg, size_t msglen) {
    /* Executed sequentially in single-threaded event loop: ZERO locks needed */
    for (int fd = 0; fd <= Chat.maxfd; fd++) {
        struct client *c = Chat.clients[fd];
        if (c && c->fd != sender_fd) {
            write(c->fd, msg, msglen); // Explicit buffer length, no O(N) strlen
        }
    }
}
```
