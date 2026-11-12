# SRTF hand check

Expected values were derived before running the implementation. Intervals
are half-open `[start, end)`; terminal Gantt endpoints are inclusive.

## Rules and data structure

One `queue_t` holds ready processes, with the same current-burst key as
SJF. Pick the minimum using FIFO ties. Preempt only if a ready process has
strictly less remaining burst time than the runner. Events are delivered
before that decision, so arrivals and I/O completions can preempt in their
own tick. Preempted processes join the queue tail (DECISION.md D-7).
Selection, removal and the preemption scan are O(n), with n <= 64.

## arrivals.txt

Command: `./ossim workloads/arrivals.txt --sched srtf --no-paging --gantt`

```text
| J1  | J4 | J3 | J1 | J5 | J3 | J5 | J6 | J2 |
0     7    9    12   16   17   20   24   30   39
```

At 2, J2's 9 is longer than J1's remaining 5. At 4, J3's 3 equals J1's
remaining 3, so J1 keeps running. At 6, J4's 2 is longer than J1's
remaining 1. At 10, J1 returns with a burst of 4 while J3 has only 2 left.
At 17, J3 returns with 3 left while J5 has 4 left: this is the preemption
that distinguishes the SRTF trace from SJF. J3 finishes at 20 and J5
resumes until 24.

Turnaround = finish - arrival; response = first - arrival. With paging
disabled, waiting = turnaround - CPU - I/O for this workload.

| Process | Arrival | CPU | I/O | First | Finish | Turnaround | Waiting | Response |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| J1 | 0 | 11 | 3 | 0 | 16 | 16 | 2 | 0 |
| J2 | 2 | 9 | 0 | 30 | 39 | 37 | 28 | 28 |
| J3 | 4 | 6 | 5 | 9 | 20 | 16 | 5 | 5 |
| J4 | 6 | 2 | 0 | 7 | 9 | 3 | 1 | 1 |
| J5 | 8 | 5 | 0 | 16 | 24 | 16 | 11 | 8 |
| J6 | 12 | 6 | 0 | 24 | 30 | 18 | 12 | 12 |
| Sum | | | | | | 106 | 59 | 54 |

Expected: `avg_turnaround=17.67`, `avg_waiting=9.83`,
`avg_response=9.00`, `context_switches=9`, `finished=6/6`.

## sched_edges.txt

Command: `./ossim workloads/sched_edges.txt --sched srtf --no-paging --gantt`

At 1, P2 has continued into its second CPU burst and has 3 ticks left.
P3's arrival and P4's I/O completion both offer bursts of 2. P3 enters
the queue first and preempts P2. P1's arrival at 2 cannot preempt P3,
which has only 1 tick left. P4 was ready before P1, so it wins their tie
at 3. This checks current-burst selection, continuation, and FIFO ties.

```text
P2 [0,1) | P3 [1,3) | P4 [3,5) | P1 [5,7) | P2 [7,10)
```

| Process | Arrival | CPU | I/O | First | Finish | Turnaround | Waiting | Response |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| P1 | 2 | 2 | 0 | 5 | 7 | 5 | 3 | 3 |
| P2 | 0 | 4 | 0 | 0 | 10 | 10 | 6 | 0 |
| P3 | 1 | 2 | 0 | 1 | 3 | 2 | 0 | 0 |
| P4 | 0 | 2 | 1 | 3 | 5 | 5 | 2 | 3 |
| Sum | | | | | | 22 | 11 | 6 |

Expected averages: turnaround 5.50, waiting 2.75, response 1.50; 5 context
switches. The separate equality case at tick 4 in `arrivals.txt` must not
introduce an extra switch.
