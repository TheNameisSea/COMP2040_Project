# SJF hand check

The expected values below were derived from the workload and scheduling
rules before running the implementation. Intervals use `[start, end)`, so
`[0, 7)` means ticks 0 through 6. The terminal Gantt chart prints inclusive
endpoints instead. Context switches include the first dispatch.

## Rules and data structure

One `queue_t` holds ready processes. `q_pop_min` selects the smallest
`proc_burst_remaining`, retaining queue order on equal keys (D-7 in
`DECISION.md`). SJF never preempts. Consecutive `cpu` operations keep the
CPU through the kernel's `continuing` path, even if another ready process
has a shorter burst. Picking and removing a process costs O(n); n <= 64.

## arrivals.txt

Command: `./ossim workloads/arrivals.txt --sched sjf --no-paging --gantt`

| Process | Arrival | CPU bursts | I/O between bursts |
|---|---:|---|---:|
| J1 | 0 | 7, 4 | 3 |
| J2 | 2 | 9 | 0 |
| J3 | 4 | 3, 3 | 5 |
| J4 | 6 | 2 | 0 |
| J5 | 8 | 5 | 0 |
| J6 | 12 | 6 | 0 |

Hand-derived Gantt chart:

```text
| J1  | J4 | J3 | J1 | J5 | J3 | J6 | J2 |
0     7    9    12   16   21   24   30   39
```

J1 blocks for I/O at 7 and returns at 10. At 7, J4's burst of 2 is
shorter than J3's 3 and J2's 9. At 9, J3's next burst is 3, so it beats
J5's 5 even though J3 has 6 total CPU ticks remaining. J3 returns from I/O
at 17 but cannot interrupt J5, which has already started at 16.

Turnaround = finish - arrival; response = first dispatch - arrival.
With paging disabled and only CPU/I/O operations, waiting can also be
checked as turnaround - total CPU - total I/O.

| Process | First | Finish | Turnaround | Waiting | Response |
|---|---:|---:|---:|---:|---:|
| J1 | 0 | 16 | 16 | 2 | 0 |
| J2 | 30 | 39 | 37 | 28 | 28 |
| J3 | 9 | 24 | 20 | 9 | 5 |
| J4 | 7 | 9 | 3 | 1 | 1 |
| J5 | 16 | 21 | 13 | 8 | 8 |
| J6 | 24 | 30 | 18 | 12 | 12 |
| Sum | | | 107 | 60 | 54 |

Expected: `avg_turnaround=17.83`, `avg_waiting=10.00`,
`avg_response=9.00`, `context_switches=8`, `finished=6/6`.

## Textbook basic.txt

All three processes arrive at 0 with bursts 24, 3, 3. FIFO ties select P2
before P3: P2 `[0,3)`, P3 `[3,6)`, P1 `[6,30)`. Waiting times in pid order
are 6, 0, 3: average `(6 + 0 + 3) / 3 = 3.00`.

## sched_edges.txt

Command: `./ossim workloads/sched_edges.txt --sched sjf --no-paging --gantt`

P2's `cpu 1` continues immediately into `cpu 3`, so it runs `[0,4)`.
At 1, P3 arrives before P4's I/O completion is delivered. P1 arrives at 2.
All three waiting bursts are 2, so FIFO chooses P3, P4, P1, despite P1's
lower pid.

```text
P2 [0,4) | P3 [4,6) | P4 [6,8) | P1 [8,10)
```

| Process | Arrival | CPU | I/O | First | Finish | Turnaround | Waiting | Response |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| P1 | 2 | 2 | 0 | 8 | 10 | 8 | 6 | 6 |
| P2 | 0 | 4 | 0 | 0 | 4 | 4 | 0 | 0 |
| P3 | 1 | 2 | 0 | 4 | 6 | 5 | 3 | 3 |
| P4 | 0 | 2 | 1 | 6 | 8 | 8 | 5 | 6 |
| Sum | | | | | | 25 | 14 | 15 |

Expected averages: turnaround 6.25, waiting 3.50, response 3.75; 4 context
switches. P4's response includes its initial I/O, but its waiting does not.

## Predicting bursts in a real OS

ossim knows the exact next burst. A real OS could estimate it with
exponential averaging: `estimate_next = alpha * actual_last +
(1 - alpha) * estimate_last`, for `0 <= alpha <= 1`. Keep an estimate per
process, update it at each completed CPU burst, and use the estimate as
the SJF key. This would require a choice of initial estimate and alpha;
prediction errors could change the order. This extension is not implemented.
