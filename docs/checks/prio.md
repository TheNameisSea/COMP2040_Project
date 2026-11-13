# PRIO hand check

Expected values were derived before running the implementation. Intervals
are half-open `[start, end)`; terminal Gantt endpoints are inclusive.

## Rules and data structure

One `queue_t` holds ready processes. `q_pop_min` selects the smallest
priority number and uses queue order to break ties. A higher-priority
ready process preempts immediately. Equal-priority arrivals wait for the
runner's quantum to end. On expiry, rotate only if an equal-priority
process is ready; otherwise reset the quantum and keep running. A lower
priority never wins merely because a quantum expired. Each dispatch resets
`quantum_used`, including after higher-priority interruption (D-8).
Queue selection/removal and the preemption scan are O(n), with n <= 64.

## arrivals.txt, quantum 2

Command: `./ossim workloads/arrivals.txt --sched prio --quantum 2 --no-paging --gantt`

```text
J1 [0,2)   | J2 [2,11)  | J1 [11,12) | J6 [12,18)
J4 [18,20) | J1 [20,24) | J3 [24,26) | J5 [26,27)
J1 [27,31) | J3 [31,32) | J5 [32,36) | idle [36,37)
J3 [37,40)
```

J2 interrupts J1 at 2. Its quantum resets while only lower priorities are
ready, so it keeps the CPU until finishing at 11. J6 interrupts J1 at 12.
J1 re-enters behind J4, which therefore runs at 18. J1's first burst ends
at 24 and its I/O completes at 27. J3 and J5 share priority 3: J3 runs for
two ticks at 24 and rotates to J5 at 26. J1's I/O completion interrupts
J5 at 27. J3's first burst ends at 32; its I/O completes at 37, leaving
one idle tick after J5 finishes at 36.

Turnaround = finish - arrival; response = first - arrival. With paging
disabled, waiting = turnaround - CPU - I/O for this workload.

| Process | Arrival | Priority | CPU | I/O | First | Finish | Turnaround | Waiting | Response |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| J1 | 0 | 2 | 11 | 3 | 0 | 31 | 31 | 17 | 0 |
| J2 | 2 | 1 | 9 | 0 | 2 | 11 | 9 | 0 | 0 |
| J3 | 4 | 3 | 6 | 5 | 24 | 40 | 36 | 25 | 20 |
| J4 | 6 | 2 | 2 | 0 | 18 | 20 | 14 | 12 | 12 |
| J5 | 8 | 3 | 5 | 0 | 26 | 36 | 28 | 23 | 18 |
| J6 | 12 | 1 | 6 | 0 | 12 | 18 | 6 | 0 | 0 |
| Sum | | | | | | | 124 | 77 | 50 |

Expected: `avg_turnaround=20.67`, `avg_waiting=12.83`,
`avg_response=8.33`, `context_switches=12`, `finished=6/6`.
The initial dispatch counts; the idle interval does not count as a dispatch.

## prio_check.txt, quantum 3

Command: `./ossim workloads/prio_check.txt --sched prio --quantum 3 --no-paging --gantt`

A and B have priority 2, H priority 1, L priority 3. B's arrival at 1
does not interrupt A. H interrupts at 2 before A's quantum is exhausted.
After H finishes, B is ahead of A in the ready queue. B uses a full
quantum, then A receives a fresh three ticks at 6 rather than the unused
one tick from its initial dispatch. L waits until both A and B finish.

```text
A [0,2) | H [2,3) | B [3,6) | A [6,9) | B [9,11) | A [11,13) | L [13,14)
```

| Process | Arrival | CPU | First | Finish | Turnaround | Waiting | Response |
|---|---:|---:|---:|---:|---:|---:|---:|
| A | 0 | 7 | 0 | 13 | 13 | 6 | 0 |
| B | 1 | 5 | 3 | 11 | 10 | 5 | 2 |
| H | 2 | 1 | 2 | 3 | 1 | 0 | 0 |
| L | 0 | 1 | 13 | 14 | 14 | 13 | 13 |
| Sum | | | | | 38 | 24 | 15 |

Expected averages: turnaround 9.50, waiting 6.00, response 3.75; 7 context
switches. Preserving A's old partial quantum would let B finish at 9
instead of 11, changing the expected waiting average.

## sched_edges.txt, quantum 2

Command: `./ossim workloads/sched_edges.txt --sched prio --quantum 2 --no-paging --gantt`

All priorities are equal. P2's consecutive CPU operations keep its quantum,
so its first time slice ends at 2, not 3. At 1, P3 arrives before P4's I/O
completion. At 2, P1 arrives before P2 is preempted. The queue order then
is P3, P4, P1, P2.

```text
P2 [0,2) | P3 [2,4) | P4 [4,6) | P1 [6,8) | P2 [8,10)
```

| Process | Arrival | CPU | I/O | First | Finish | Turnaround | Waiting | Response |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| P1 | 2 | 2 | 0 | 6 | 8 | 6 | 4 | 4 |
| P2 | 0 | 4 | 0 | 0 | 10 | 10 | 6 | 0 |
| P3 | 1 | 2 | 0 | 2 | 4 | 3 | 1 | 1 |
| P4 | 0 | 2 | 1 | 4 | 6 | 6 | 3 | 4 |
| Sum | | | | | | 25 | 14 | 9 |

Expected averages: turnaround 6.25, waiting 3.50, response 2.25; 5 context
switches. PRIO has no aging, so an unbounded stream of higher-priority
work could starve lower-priority processes.
