# MLFQ: hand checks

Rules: DECISION.md D-10. Three levels, q = 2, so quanta are 2 / 4 / 8.
Notation: `L0:[..]` is the ready queue of level 0. "expire" means the
process used its whole quantum in that tick and is demoted in `on_tick`.

## 1. workloads/arrivals.txt, q = 2

`--sched mlfq --quantum 2 --no-paging`

| Job | arrive | ops |
|---|---|---|
| J1 | 0 | cpu 7, io 3, cpu 4 |
| J2 | 2 | cpu 9 |
| J3 | 4 | cpu 3, io 5, cpu 3 |
| J4 | 6 | cpu 2 |
| J5 | 8 | cpu 5 |
| J6 | 12 | cpu 6 |

| t | event | runs | after the tick |
|---|---|---|---|
| 0–1 | J1 arrives | J1 (L0) | expire, J1 → L1, rem 5 |
| 2–3 | J2 arrives; J1 preempted (J2 ready at L0) → L1:[J1] | J2 (L0) | expire, J2 → L1, rem 7 |
| 4–5 | J3 arrives; L1:[J1,J2] | J3 (L0) | expire, J3 → L1, rem 1 |
| 6–7 | J4 arrives; L1:[J1,J2,J3] | J4 (L0) | J4 done, finish **8** |
| 8–9 | J5 arrives | J5 (L0) | expire, J5 → L1, rem 3 |
| 10–11 | L1:[J1,J2,J3,J5] | J1 (L1, q 4) | rem 3 |
| 12–13 | J6 arrives at L0, preempts J1 (keeps L1) → L1:[J2,J3,J5,J1] | J6 (L0) | expire, J6 → L1, rem 4 |
| 14–17 | L1:[J3,J5,J1,J6] | J2 (L1) | expire, J2 → L2, rem 3 |
| 18 | | J3 (L1) | cpu done, io 5 until 24, stays L1 |
| 19 | | J5 (L1) | rem 2 |
| 20 | **boost**: L0:[J1,J6,J2], every level 0, J5 fresh quantum | J5 (L0) | rem 1 |
| 21 | | J5 | expire and done, finish **22** |
| 22–23 | | J1 (L0) | expire, J1 → L1, rem 1 |
| 24–25 | J3 io done → L0:[J6,J2,J3]; J1 preempted → L1:[J1] | J6 (L0) | expire → L1, rem 2 |
| 26–27 | L1:[J1,J6] | J2 (L0) | expire → L1, rem 1 |
| 28–29 | L1:[J1,J6,J2] | J3 (L0) | expire → L1, rem 1 |
| 30 | L1:[J1,J6,J2,J3] | J1 (L1) | cpu done, io 3 until 34 |
| 31–32 | | J6 | done, finish **33** |
| 33 | | J2 | done, finish **34** |
| 34 | J1 io done → L1:[J3,J1] | J3 | done, finish **35** |
| 35–38 | | J1 | done, finish **39** |

```
|J1 |J2 |J3 |J4 |J5 |J1 |J6 |J2     |J3|J5    |J1 |J6 |J2 |J3 |J1|J6 |J2|J3|J1     |
0   2   4   6   8   10  12  14      18 19     22  24  26  28  30 31  33 34 35      39
```

| Job | finish | turnaround | cpu | io | waiting | response |
|---|---|---|---|---|---|---|
| J1 | 39 | 39 | 11 | 3 | 25 | 0 |
| J2 | 34 | 32 | 9 | 0 | 23 | 0 |
| J3 | 35 | 31 | 6 | 5 | 20 | 0 |
| J4 | 8 | 2 | 2 | 0 | 0 | 0 |
| J5 | 22 | 14 | 5 | 0 | 9 | 0 |
| J6 | 33 | 21 | 6 | 0 | 15 | 0 |

waiting = turnaround − cpu − io.
**avg_turnaround = 139/6 = 23.17, avg_waiting = 92/6 = 15.33,
avg_response = 0.00** (every arrival lands on L0 and gets the CPU at once).
**context_switches = 19** (one per block in the chart).

## 2. workloads/mlfq_check.txt, q = 2

A: arrive 0, cpu 30. B: arrive 3, cpu 2. C: arrive 21, cpu 2.

| t | runs | what happens |
|---|---|---|
| 0–1 | A (L0) | expire → L1 |
| 2 | A (L1) | nobody ready: A keeps the CPU with a new quantum |
| 3–4 | B (L0) | B arrives at L0 and preempts A (L1, keeps L1). B expires and is done, finish **5** |
| 5–8 | A (L1, q 4) | expire → L2 |
| 9–16 | A (L2, q 8) | expire, stays L2 (bottom), keeps the CPU |
| 17–19 | A (L2) | |
| 20 | A | **boost**: A → L0 with a fresh quantum |
| 21 | A (L0) | C arrives at L0: same level, no preemption. A expires → L1 |
| 22–23 | C (L0) | C was ready at L0 ≤ L1, so A is preempted. C done, finish **24** |
| 24–33 | A (L1, then L2) | A done (ran 3 + 17 + 10 = 30), finish **34** |

Without the boost A would still be on L2 at t = 21 and C would start at 21.

| Job | finish | turnaround | waiting | response |
|---|---|---|---|---|
| A | 34 | 34 | 4 | 0 |
| B | 5 | 2 | 0 | 0 |
| C | 24 | 3 | 1 | 1 |

**avg_turnaround = 13.00, avg_waiting = 1.67, avg_response = 0.33,
context_switches = 5** (A, B, A, C, A).
