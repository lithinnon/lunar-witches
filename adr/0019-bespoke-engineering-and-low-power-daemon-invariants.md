# ADR 0019: Bespoke Engineering & Low-Power Daemon Invariants

> **Status:** Accepted  
> **Date:** 2026-11-12  
> **Scope:** In-House Tooling (`conduct`), Privilege Orchestration, Power Efficiency & Battery Invariants  

---

## 1. Context & Problem

In autonomous AI agent workflows, background subshells, and headless terminal automation, standard upstream privilege tools fall short in two critical dimensions:

1. **Blind Elevation & Secret Leakage:** Standard askpass helpers (`ksshaskpass`, `ssh-askpass`) present blind prompts (`[sudo] password:`) devoid of caller provenance (PID, binary path, working directory, or ancestry chain). A background agent or script can request root without the operator knowing what command is escalating. Furthermore, dumb askpass scripts easily leak plaintext secrets into subshell log buffers.
2. **Invisible Hardware Token Timeouts:** PAM U2F (`pam_u2f.so`) emits `Please touch the FIDO authenticator.` exclusively to the child process's `stderr`. In headless or subshell harness runners, this output is swallowed, causing hardware presence requests to silently time out before falling back to password prompts.

When building bespoke in-house software to solve these gaps (such as `conduct`), a naive daemon implementation (e.g., using non-blocking loops with `sleep(50ms)` or periodic polling) constantly wakes CPU cores out of deep package C-states (C8/C10). On mobile silicon (e.g. AMD Strix Point / ASUS TUF A14), repeated timer wakeups severely degrade battery life.

---

## 2. Decision

### 1. In-House Engineering Policy
When a required capability does not exist upstream or existing packages fail to provide secure agentic provenance and visibility, `lunar-witches` authorizes engineering custom declarative tools (e.g. `conduct`) managed via independent Flakes under `github:lithinnon/<project>`.

### 2. Mandatory Low-Power Daemon Invariants
Any bespoke daemon running in system or user scope (such as `conduct watch`) must strictly satisfy the following low-power criteria:

* **Zero Periodic Wakeups (0.00 Hz Idle):** Daemons must never employ periodic sleep intervals, polling loops, or recurring timers while idle.
* **Pure Event-Driven Kernel Syscalls:** Daemons must block indefinitely in kernel space using native event mechanisms:
  - Linux `inotify` (blocking `read()` on `inotify_fd` for file events such as `/run/user/$UID/pam-u2f-authpending`).
  - Kernel USB HIDRAW (blocking `read()` on `/dev/hidraw*`, waking solely on hardware interrupt transfers).
  - Inotify device hotplug (watching `IN_CREATE` on `/dev` for dynamic device insertion rather than periodic directory scanning).
* **Deep C-State Preservation:** By sleeping exclusively in `TASK_INTERRUPTIBLE` within kernel syscalls, the CPU package is free to reside in its deepest sleep state (C8/C10), resulting in **0W added power draw**.
* **Minimal Memory Footprint:** Binaries must be compiled natively (Rust/C) with a strictly bounded resident set size (<1MB RSS) and zero garbage collection overhead.
* **Seamless Protocol Plugging:** Bespoke tools must interface natively with established system interfaces (`SUDO_ASKPASS`, `SSH_ASKPASS`, PAM, Freedesktop D-Bus Notifications) rather than forcing imperative wrapper scripts (e.g. requiring no `conduct exec`).
* **Multi-Source Aggregation:** Concurrent authentication requests (e.g. simultaneous `sudo` PAM U2F and SSH `id_ed25519_sk` FIDO touches) must be aggregated into a single dynamic notification updated in-place via D-Bus `replaces_id`, auto-dismissing when all pending operations finish.

---

## 3. Consequences

- **Visibility & Security:** Eliminates blind elevation and silent hardware timeouts across all human and agent workflows without compromising credential safety.
- **Zero Battery Penalty:** Battery consumption on mobile workstations is completely unaffected during idle states.
- **Maintenance Boundary:** In-house crates must maintain hermetic unit tests, GitHub Actions CI, and Flake outputs independent of the main system configuration.
