# Deadlock detection: hand checks

Method: the detection algorithm of Sec. 8.6.2 (several instances), see
`deadlock_check()` in `src/sync.c` and DECISION.md D-4.

## 1. workloads/deadlock.txt, RR q=2, check every 5 ticks

`--sched rr --quantum 2 --deadlock-every 5 --max-ticks 60 --no-paging`

A (pid 1) and C (pid 3) arrive at 0, in file order, so the ready queue is
A, C. B (pid 2) arrives at 1. R1 and R2 have one instance each.

| ticks | runs | what happens |
|---|---|---|
| 0–1 | A | end of t1: `cpu 2` done, `acquire R1` granted, next op is cpu so A keeps the CPU |
| 2–3 | C | A used its quantum (2), C was ready |
| 4–5 | B | end of t4: `cpu 1` done, `acquire R2` granted, B keeps the CPU |
| 6–7 | A | |
| 8–9 | C | |
| 10–11 | B | end of t11: `cpu 3` done, `acquire R1` blocks (A holds it) |
| 12 | A | end of t12: `cpu 3` done, `acquire R2` blocks (B holds it) |
| 13–14 | C | C finishes at 15 |

```
| A | C | B | A | C | B |A| C |  idle ...
0   2   4   6   8   10  12 13 15
```

Checks at the end of t = 5, 10, 15, ...

- t=5, t=10: nothing blocked on a resource (Request = 0 for all). No deadlock.
- t=15: Available = (R1 0, R2 0). Allocation A = (1,0), B = (0,1).
  Request A = (0,1), B = (1,0). C is terminated.
  Finish = A false, B false, C true. Neither request fits Work = (0,0).
  **`DEADLOCK t=15 pids: 1 2`**
- t=20, 25, ...: same set, not printed again.

## 2. workloads/deadlock_multi.txt, one resource with 2 instances

`--sched rr --quantum 1 --deadlock-every 2 --max-ticks 20 --no-paging`

Both arrive at 0 and take one instance of R right away (zero-time op),
so Available = 0. Ready queue A, B, quantum 1:

| t | 0 | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|---|
| runs | A | B | A | B | A | B |

End of t4: A's `cpu 3` is done, `acquire R` blocks. End of t5: same for B.

- t=2: nobody waits. No deadlock.
- t=4: Work = 0. A: Allocation 1, Request 1. B: Allocation 1, Request 0.
  B fits (0 <= 0): Work = 1, B finished. Then A fits (1 <= 1). **No
  deadlock**, even though A is blocked. A wait-for graph that assumed one
  instance would wrongly see A waiting on B here.
- t=6: A Request 1, B Request 1, Work 0. Neither fits.
  **`DEADLOCK t=6 pids: 1 2`**

## 3. workloads/no_deadlock_multi.txt, blocked but not deadlocked

`--sched fcfs --deadlock-every 1 --no-paging`

A takes both instances at 0 and runs t0–t5. B arrives at 1 and blocks
asking for 1. At every check from t=1 to t=5: Work = 0, A has Request 0 so
it fits, Work becomes 2, then B fits. **Never a deadlock.** At t=6 A
releases R, B gets it, runs t6–t7. Both finish (`finished=2/2`).
