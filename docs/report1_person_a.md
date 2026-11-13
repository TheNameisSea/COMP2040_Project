# Checkpoint 1: Person A's report contribution

This is Person A's contribution to the joint progress report of at most
two pages. Person B's MLFQ/deadlock explanation and the teammate review
still need to be incorporated into the submission.

## Scheduler design

SJF, SRTF and PRIO each keep one `queue_t` of ready PCB pointers and use
the existing scheduler hooks. Enqueue appends to the tail. `q_pop_min`
scans for the minimum key, retaining ready-queue order for equal keys.
The selection and array removal are O(n); at `MAX_PROCS=64`, a simple
linear queue is adequate. SRTF and PRIO also scan for a minimum during
preemption checks. No kernel or header change is needed.

**SJF:** the key is the remaining length of the current CPU burst,
rather than total remaining process work. It does not preempt. Successive
CPU operations retain the CPU through the kernel's `continuing` path.
The simulator knows burst lengths exactly. A real OS could predict them
with exponential averaging, `estimate_next = alpha * actual_last +
(1 - alpha) * estimate_last`. This would need an initial estimate and a
chosen alpha; prediction errors would affect scheduling.

**SRTF:** uses the same key, but preempts when a ready process has
strictly less remaining burst time. Equal lengths leave the runner in
place. The kernel delivers events before making this decision, so an
arrival or I/O completion can preempt in its own tick.

**PRIO:** uses the priority number; a smaller number means higher
priority. A strictly higher priority preempts immediately. Equal
priorities rotate only on quantum expiry. Each dispatch starts a fresh
quantum, including after a higher-priority interruption. With only lower
priorities ready, the runner resets its quantum and continues. Consecutive
CPU operations retain the quantum. Decisions are recorded in
[D-7 and D-8](../DECISION.md).

## Validation

We derived Gantt charts, first-dispatch and completion times from the
workload before running the implementation. Turnaround is finish minus
arrival; response is first dispatch minus arrival; waiting counts READY
ticks. For `arrivals.txt` with paging off, waiting also equals turnaround
minus total CPU and I/O time. The initial dispatch counts as a context
switch. PRIO uses quantum 2.

| Scheduler | Waiting: hand / ossim | Response: hand / ossim | Turnaround: hand / ossim | Switches: hand / ossim |
|---|---|---|---|---|
| SJF | 10.00 / 10.00 | 9.00 / 9.00 | 17.83 / 17.83 | 8 / 8 |
| SRTF | 9.83 / 9.83 | 9.00 / 9.00 | 17.67 / 17.67 | 9 / 9 |
| PRIO | 12.83 / 12.83 | 8.33 / 8.33 | 20.67 / 20.67 | 12 / 12 |

The complete working, Gantt charts and per-process tables are in
[sjf.md](checks/sjf.md), [srtf.md](checks/srtf.md) and
[prio.md](checks/prio.md). Additional hand cases distinguish FIFO ties
from PID ordering, check consecutive CPU operations, same-tick events,
and a fresh PRIO quantum after interruption. SJF also gives waiting 3.00
on the textbook bursts 24, 3, 3. Producer/consumer and mixed workloads
finish under all three new schedulers, including paging with one frame.
Actual commands and terminal output are saved in
[person_a_terminal.txt](checks/person_a_terminal.txt).

Ubuntu WSL with GCC 15.2 builds using the unchanged strict C99 flags.
The full suite reports 54 PASS, 5 SKIP and 0 FAIL; the skips are MLFQ and
Checkpoint 2 policies. Another 30 runs confirm completion of the ten
non-deadlocking workloads under all three new schedulers with paging on.
Clang is not installed in this environment, so its build is not verified.

## Current limits and contributions

PRIO has no aging and can starve a low priority under sustained higher
priority work. The FIFO and quantum interpretations are explicit in the
decision log, with teammate review pending. MLFQ remains Person B's
separate task, so this contribution does not claim all Checkpoint 1 work
is complete. Person B's resource deadlock check is present: independently
tracing RR quantum 2 puts both requests in a cycle by the end of tick 12,
and the first subsequent five-tick check reports at 15. MLFQ review is
pending its implementation.

The review also found and fixed a false-PASS path in `check_no`: simulator
errors now fail the negative check. A separate completion check protects
the non-deadlocking resource case. Review details and the remaining joint
submission work are in [person_a_review.md](checks/person_a_review.md).

- **Person A:** SJF/SRTF/PRIO implementations, hand derivations, regression
  workloads, tests, scheduler documentation, and the WSL test line-ending fix.
- **Person B:** resource deadlock implementation and its hand checks are
  present; MLFQ and the joint report remain separate contributions.

Codex assisted with implementation, calculations and validation. The team
guide requires each submitting member to understand the code; no human
review or approval is claimed here.
