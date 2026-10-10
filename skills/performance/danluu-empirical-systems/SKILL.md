---
name: danluu-empirical-systems
description: "Empirical software engineering methodology relying on real-world measurements, crash-consistency verification, latency distribution analysis, off-CPU tracing, and skepticism toward POSIX and vendor abstractions."
triggers: ["empirical-systems", "crash-consistency", "tail-latency", "tracing-vs-sampling", "hardware-reality", "fsync-durability"]
conflicts_with: ["architecture/fowler-evolutionary-design"]
primary_sources:
  - title: "Filesystem Crash Consistency"
    url: "https://danluu.com/file-consistency/"
  - title: "Terminal Latency Across Generations"
    url: "https://danluu.com/term-latency/"
  - title: "Performance Tracing & Profiling"
    url: "https://danluu.com/perf-tracing/"
---

# Dan Luu: Empirical Systems Analysis & Hardware Reality

## 1. Core Philosophy & Deliberate Rejections
- **Prioritizes**: Rigorous empirical measurement over specification promises or theoretical claims; end-to-end pipeline observation; crash consistency verification across sudden power losses; full latency distribution auditing (p95, p99, p99.9, max); and tracing off-CPU blocking states (lock contention, context switches, disk I/O).
- **Rejects**: Blind faith in POSIX filesystem semantics (e.g., assuming `rename` is durable or atomic without flushing file data and directory metadata); software-only microbenchmarks that ignore display compositors and hardware pipeline queues (as demonstrated by modern 4GHz computers exhibiting worse typing latency than a 1977 Apple II); relying solely on on-CPU sampling profilers (which are blind to off-CPU waiting and latency outliers); and engineering optimizations grounded in intuition rather than empirical tracing data.
- **Primary Trade-off**: Sacrifices optimistic, high-throughput asynchronous writes and easy code shortcuts to guarantee real-world crash safety, verifiable durability under hardware power loss, and elimination of catastrophic tail-latency outliers.

## 2. Hard Implementation Rules
- **Rule 1 (The Durable Write Invariant)**: File mutations requiring persistence across sudden power failure MUST follow the strict sequence: write data $\rightarrow$ `fsync(file_fd)` $\rightarrow$ `close(file_fd)` $\rightarrow$ `rename(temp_path, dest_path)` $\rightarrow$ `fsync(parent_dir_fd)`. Applications MUST NOT assume `rename()` alone guarantees data on disk.
- **Rule 2 (Checksummed Log Records)**: Write-ahead logs and journals MUST append verification checksums (CRC32, XXH64) with each record. Crash recovery routines MUST NOT trust file length or assume partial sector writes do not occur during sudden shutdown.
- **Rule 3 (Percentiles Over Averages)**: System latency reports MUST state high-percentile distributions (p50, p95, p99, p99.9). Engineering decisions and service-level objectives MUST NOT be judged by arithmetic mean (average) latency.
- **Rule 4 (Off-CPU Trace Auditing)**: Performance investigations for slow operations MUST record off-CPU blocking time (sleeps, lock waits, I/O wait, scheduler delays) using tracing instruments (e.g., eBPF / `perf_events`). Developers MUST NOT diagnose tail latency solely using statistical on-CPU profilers.
- **Rule 5 (End-to-End Measurement)**: Interactive systems and networking layers MUST measure latency from real input receipt to final perceived output. Systems MUST NOT claim low latency based only on internal computational timestamps that omit message queueing or display pipelines.

## 3. Code Review Checklist
- [ ] **Unsynced Directory Rename**: Does the code save a file by writing to a temporary file and calling `rename()` without calling `fsync()` on the parent directory handle?
- [ ] **Missing Write Flushes**: Are file writes assumed to be persistent without an explicit `fsync()` call on the file descriptor before proceeding?
- [ ] **Average Latency Fallacy**: Are latency benchmarks presented as a single average number, hiding multi-second p99 tail spikes?
- [ ] **Sampling Bias in Profiling**: Is a performance bug deemed "absent" because an on-CPU sampling profiler showed idle CPU, failing to trace off-CPU lock waits?
- [ ] **Unchecksummed Storage Journal**: Does a crash recovery system read past log entries without verifying a cryptographic or polynomial checksum on each record?

## 4. Canonical Idiom (Reference Pattern)

### REJECTED: Naive file overwrite or unsynced rename risking corrupted or zero-filled blocks
```python
# REJECTED: Vulnerable to silent corruption, zero-byte truncation, and lost writes on crash
import os

def save_critical_config(config_data, target_path):
    temp_path = target_path + ".tmp"
    with open(temp_path, "w") as f:
        f.write(config_data)
        # BUG: No f.flush() or os.fsync(f.fileno())! Data sits in OS dirty page buffer
    
    # BUG: rename() executes before data is on disk. On power cut, target becomes 0 bytes!
    os.replace(temp_path, target_path)
    # BUG: Parent directory is never synced, so directory entry may point to invalid inode
```

### ACCEPTED: Dan Luu crash-consistent durability pattern with checksum, sync, and directory sync
```python
# ACCEPTED: Canonical Dan Luu crash-consistent persistence pattern
import os
import zlib

def save_critical_config_durable(config_data: bytes, target_path: str):
    dir_name = os.path.dirname(os.path.abspath(target_path))
    temp_path = f"{target_path}.tmp.{os.getpid()}"
    
    # 1. Compute checksum to detect partial sector writes
    checksum = zlib.crc32(config_data).to_bytes(4, byteorder='big')
    payload = checksum + config_data

    # 2. Write payload to temporary file
    fd = os.open(temp_path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o644)
    try:
        os.write(fd, payload)
        # Flush data to drive cache and force disk platter/flash commit
        os.fsync(fd)
    finally:
        os.close(fd)

    # 3. Atomically replace target path
    os.replace(temp_path, target_path)

    # 4. CRITICAL: fsync the parent directory to persist the directory entry update
    dir_fd = os.open(dir_name, os.O_RDONLY | os.O_DIRECTORY)
    try:
        os.fsync(dir_fd)
    finally:
        os.close(dir_fd)
```
