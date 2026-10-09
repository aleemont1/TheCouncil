---
name: "security/djb-isolated-privilege"
description: "Security architecture discipline enforcing elimination of trusted code, radical multi-process privilege separation, tiny single-purpose micro-binaries, supervised foreground execution, and replacing library complexity with simple OS process boundaries."
triggers: ["radical-privilege-separation", "micro-binaries", "bug-elimination", "daemontools", "qmail-architecture", "zero-root-daemons"]
conflicts_with: ["systems/stenberg-defensive-c", "architecture/dhh-majestic-monolith"]
primary_sources:
  - title: "Thoughts on Security After Ten Years of qmail"
    url: "https://cr.yp.to/qmail/qmail-sec-20071101.pdf"
  - title: "Some Thoughts on Systems and Daemons"
    url: "https://cr.yp.to/daemontools.html"
---

# Daniel J. Bernstein: Radical Privilege Isolation & Bug Elimination

## 1. Core Philosophy & Deliberate Rejections
- **Prioritizes**: Eliminating trusted code ("Eliminating bugs, eliminating code, eliminating trusted code"); radical multi-process privilege separation into distinct, tiny single-purpose micro-binaries; distinct UNIX UIDs/GIDs for each system responsibility; non-forking foreground execution supervised by tools like `daemontools` (`supervise` / `svscan`); fixed-size buffers and static limits; and strict data flow pipes over complex shared-memory abstractions.
- **Rejects**: Monolithic multi-function daemons running as `root` (exemplified by Sendmail's history of critical remote exploits); relying on "least privilege" within a single bloated binary as an excuse for buggy code; double-forking self-daemonizing processes that disconnect from their supervisors; kitchen-sink feature creep; and parsing untrusted network protocols in privileged address spaces.
- **Primary Trade-off**: Sacrifices in-process function-call convenience and monolithic rapid feature accretion in exchange for provable invulnerability, zero remote code execution vulnerabilities, and operational simplicity.

## 2. Hard Implementation Rules
- **Rule 1 (Radical Multi-Binary Privilege Drop)**: Programs listening on network ports MUST drop `root` privileges immediately after binding or delegate network handling to an unprivileged child process (e.g., `qmail-smtpd` running under an unprivileged UID with zero access to the local filesystem).
- **Rule 2 (No Monolithic Daemons)**: Systems MUST be structured as discrete, single-purpose executable binaries communicating via standard UNIX pipes or bounded files. Complex subsystem communication MUST NOT be handled by multi-threaded monolithic processes.
- **Rule 3 (Foreground Execution Under Supervision)**: Services MUST run in the foreground and log to `stdout`/`stderr`. Programs MUST NOT self-daemonize, double-fork, create `.pid` files, or manipulate terminal sessions; process lifecycles MUST be managed by an external supervisor (`daemontools`, `runit`, `systemd`).
- **Rule 4 (Bounded Memory Allocation)**: Parsers handling untrusted network input MUST operate within statically bounded memory limits or strict streaming buffers. Code MUST NOT use uncontrolled recursive allocation or dynamic memory resizing based on remote input headers.
- **Rule 5 (Code Elimination Mandate)**: Features that cannot be proven secure or that expand the trusted code footprint MUST NOT be merged. Programmers MUST minimize the code-to-job ratio to minimize the bug rate.

## 3. Code Review Checklist
- [ ] **Persistent Root Privileges**: Does a daemon continue running as `root` after binding its listening socket instead of invoking `setuidgid`?
- [ ] **Self-Daemonizing Backgrounding**: Does a service call `daemon()` or perform a double-fork to detach into the background instead of remaining in the foreground?
- [ ] **Monolithic Process Responsibility**: Does a single binary handle untrusted public network requests, local filesystem writes, and user authentication simultaneously?
- [ ] **Fragile PID File Management**: Does a program manage its own PID files and signal dispatch rather than delegating process lifecycle to a supervisor?
- [ ] **Unbounded String Allocations**: Does an untrusted input parser allocate memory based on a remote client's advertised payload length without strict static limits?

## 4. Canonical Idiom (Reference Pattern)

### REJECTED: Monolithic daemon running as root, self-backgrounding with PID file
```c
/* REJECTED: Anti-pattern of monolithic self-daemonizing daemon running as root */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>

void daemonize_and_listen(void) {
    pid_t pid = fork();
    if (pid > 0) exit(0); // Double-fork anti-pattern: breaks supervisor tracking!
    setsid();
    umask(0);
    
    // Writes PID file: fragile and subject to symlink races
    FILE *f = fopen("/var/run/my_daemon.pid", "w");
    fprintf(f, "%d\n", getpid());
    fclose(f);

    // CRITICAL FLAW: Retains ROOT privileges while parsing untrusted network inputs!
    while (1) {
        // Accepts socket, reads payload, parses files as root...
    }
}
```

### ACCEPTED: DJB micro-binary pattern: privilege drop, pipe IPC, and supervised foreground execution
```c
/* ACCEPTED: Canonical DJB architecture pattern */
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>
#include <pwd.h>

void drop_privileges(const char *username) {
    struct passwd *pw = getpwnam(username);
    if (!pw) {
        perror("unknown user");
        exit(111);
    }
    // Drop all supplementary groups and permanently change UID/GID
    if (setgid(pw->pw_gid) != 0 || setuid(pw->pw_uid) != 0) {
        perror("unable to drop privileges");
        exit(111);
    }
}

int main(int argc, char **argv) {
    /* 
     * Rule 3: Runs strictly in the FOREGROUND.
     * daemontools/supervise monitors this process directly via waitpid().
     * Rule 1: Drops privileges immediately to unprivileged account.
     */
    drop_privileges("qmaild");

    /* 
     * Rule 2 & 4: Reads strictly from stdin, processes bounded input,
     * writes output directly to stdout pipe connected to multilog or queue binary.
     */
    char buf[1024];
    ssize_t n;
    while ((n = read(0, buf, sizeof(buf))) > 0) {
        // Parse bounded chunk with zero dynamic allocation
        if (write(1, buf, n) != n) {
            exit(111); // Temporary failure code for supervisor
        }
    }
    return 0;
}
```
