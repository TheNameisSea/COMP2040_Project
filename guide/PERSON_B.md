# Person B: task guide

You own: **MLFQ and deadlock detection** (checkpoint 1), **SSTF, SCAN,
C-LOOK and the experiment runner** (checkpoint 2), and **experiment 2**
(final). You review all of Person A's work: SJF, SRTF, PRIO, LRU, Clock and
the generator.

This guide gives you the approach and the traps, not the code. You write it,
so you can explain it at the demo.

Before you start, read:
- `src/kernel.c`: in particular `kernel_run()`, `dispatch()`,
  `execute_tick()` and `kernel_abort()`
- `include/sched.h`, `include/queue.h`, `include/sync.h`, `include/disk.h`
- RR in `src/sched.c`, the resource code in `src/sync.c`, FCFS and
  `disk_kick()` in `src/disk.c`

---

## Checkpoint 1

### 1.4 MLFQ: branch `sched/mlfq`

**Idea:** three RR queues. Level 0 has quantum q, level 1 has 2q, level 2
has 4q (q = `cfg.quantum`). Always run from the highest non-empty level.
Use a full quantum → move down one level. Block earlier → stay. Every 20
ticks everyone goes back to level 0.

**Steps**
1. `static queue_t mlfq_q[3];`. `enqueue(p)` pushes to `mlfq_q[p->level]`.
   New processes start at level 0 (`p->level` is 0 at the start).
2. `pick()` pops from the first non-empty level.
3. `on_dispatch` resets `quantum_used`, and `on_tick` increments it.
   The quantum of a level is `cfg.quantum << level`.
4. `should_preempt(r)`:
   - If `r` used its whole quantum: move it down (`level = min(level+1, 2)`)
     and preempt it if anyone is ready. If nobody is ready, it keeps the CPU
     with a new quantum, as in RR.
   - If a process is ready at a **higher** level than `r`, preempt `r`.
5. `ready_count()` = the sum of the three queue sizes.

**The boost (the tricky part)**
- No single hook runs every tick: `should_preempt` runs only when something
  is running, and `pick` only when the CPU is free. But every tick calls
  one of them. So do the boost in a small helper called at the start of
  **both**, and remember the last tick you boosted so it runs once per tick.
- Boost = every process that is not terminated gets `level = 0`, including
  the running one and the blocked ones (go through `procs[]`), and every
  process in levels 1 and 2 moves to the tail of level 0, keeping its order.

**Decisions to write in DECISION.md (Q-9)**
- Boost at t = 20, 40, … (not at t = 0).
- Is a demoted process that keeps the CPU (nobody ready) still demoted? (The
  simple answer is yes.)
- Does a higher-level arrival preempt right away? (The standard MLFQ answer is yes.)
- When a burst ends and the next op is `cpu`, the process keeps the CPU and
  its `quantum_used`. A burst ending is not blocking.

**Check:** `arrivals.txt --sched mlfq --quantum 2 --no-paging`. It runs
past t = 20, so the boost is in the hand computation. Draw the Gantt chart
with the level of every process. Add avg_waiting and context_switches checks.

### 1.5 deadlock_check(): branch `sync/deadlock`

**Recommended method:** the detection algorithm of Sec. 8.6.2. It handles
several instances, it's not harder than the wait-for graph, and themes 7/8
need it. (Close Q-1 in DECISION.md.)

**Data you have** (in `include/sync.h`)
- `resources[i].available`: Available
- `resources[i].allocated[pid]`: Allocation
- `resources[i].requested[pid]`: Request (non-zero only while blocked in `acquire`)

**Steps**
1. `Work = available` for every resource.
2. For every process: `Finish = true` if it is terminated, not yet arrived,
   or holds nothing. Otherwise false.
3. Repeat: find an unfinished process whose `requested` ≤ `Work` for every
   resource. Add its `allocated` to `Work`, mark it finished. Stop when
   nothing changes.
4. The unfinished processes are deadlocked. Go through `procs[]` in order
   (pids are already ascending) and print exactly:
   `DEADLOCK t=<now> pids: 1 2` (`printf("DEADLOCK t=%ld pids:", now)`
   then `" %d"` per pid, then `\n`).
5. Print each deadlock **once**: keep the last reported set in a static
   variable and only print when it changes.

**Things to know**
- A process blocked on a **semaphore** has `requested` = 0 everywhere, so
  this algorithm sees it as able to finish. That's correct for a
  resource-only algorithm. Mention the limitation in the report.
- Index arrays by `pid`, not by the index in `procs[]` (`pid = i + 1`).
- Recovery is optional. If you do it, `kernel_abort(p)` on one victim, then
  run the check again.

**Check:** the test for `deadlock.txt` exists already. Also compute by hand
the **first tick** it is detected with `--deadlock-every 5`, and add a check
for `DEADLOCK t=<that tick>`. Make a second workload with a resource of 2
instances that is **not** deadlocked (the algorithm must not report it).

### Report 1 (your part)
MLFQ data structures (three queues, `p->level`, how the boost is found
every tick), deadlock algorithm and its complexity, and how you checked both.

### What to review in A's work
- **SRTF:** check the preemption test uses `<` (ties don't preempt).
- **PRIO:** run `arrivals.txt --sched prio --gantt` and check the RR between
  equal priorities by hand.

---

## Checkpoint 2

All three are `pick()` functions: given `pending[0..n-1]`, the `head` and
`*dir`, return an index. `disk_kick()` adds up the movement
head → via[0] → via[1] → cylinder.

### 2.3 SSTF: branch `disk/sstf`
- Return the index with the smallest `abs(cylinder - h)`.
- Ties: the lower index wins (= the older request). Write it down (Q-11).
- Check: `disk_textbook.txt --head 53 --disk sstf` → 236 (already in the tests).
- Report: SSTF can starve far requests (Sec. 11.2.2). Try to make a small
  workload that shows it.

### 2.4 SCAN: branch `disk/scan`
- Look for the nearest request **in the current direction** (cylinder ≥ h
  going up, ≤ h going down; a request exactly at h counts).
- If there is one, return it.
- If there is none: the head goes to the edge (0 going down,
  `cfg.cylinders - 1` going up). Write the edge into `via[0]`, flip `*dir`,
  then pick the nearest request in the new direction.
- Check: `--head 53 --direction down --disk scan` → 236:
  53→37→14→**0**→65→67→98→122→124→183.
- Trap: don't go to the edge if the head is already there. And `via` only
  goes to the edge when there is nothing left in the current direction.

### 2.5 C-LOOK: branch `disk/clook`
- Going up: the nearest request with cylinder ≥ h. If there is none, jump to
  the **lowest** request and keep going up. `*dir` doesn't change.
- No `via` is needed: the jump goes straight to the lowest request, and the
  textbook number counts it.
- Check: `--head 53 --direction up --disk clook` → 322:
  53→65→67→98→122→124→183 (130), →14 (169), →37 (23).
- Also make it work for `--direction down` (mirror image) and compute one
  case by hand.

### 2.7 Experiment runner: branch `exp/runner`

Write `tools/run_exp.py` (Python 3; matplotlib only for plotting).

1. Takes a grid of parameters (e.g. `--sched` × `--quantum` × seeds, or
   `--frames` from 1 to 20 × `--replace`), runs `./ossim` for each
   combination, and parses the `key=value` lines of the summary
   (`avg_waiting=`, `page_faults=`, `head_movement=`,
   `avg_fault_service=`, `utilization=`…).
2. Writes one CSV row per run into `results/<experiment>.csv` (CSVs are
   gitignored. Commit the script and the plots, not the raw data).
3. A separate plot step: CSV → PNG, mean over seeds, with error bars when
   there are several seeds.
4. Calls A's generator for each point when the experiment needs fresh
   workloads. Agree on its options with A.

Check: one row of the CSV must match a manual `./ossim` run.

### What to review in A's work
- **LRU:** check it doesn't update `last_used` again in `on_hit` (the
  kernel already does).
- **Clock:** redo A's hand-computed Clock case, including the rule that a
  newly installed page has `referenced = true`.
- **Generator:** same seed → same file; files near the limits still load.

---

## Final

- **Experiment 2:** page faults and CPU utilization as the number of frames
  goes down, for FIFO, LRU and Clock. Where does thrashing start? Find a
  reference string where FIFO shows Belady's anomaly (e.g. the textbook
  1,2,3,4,1,2,5,1,2,3,4,5 with 3 vs 4 frames) and show LRU doesn't.
- **Theme:** the split will be decided when we choose it (see DECISION.md).
- **Report:** design of MLFQ, deadlock detection and the disk, validation
  of your checks, experiment 2.
- **Demo rehearsal:** explain SRTF, PRIO, Clock and the generator to A
  without notes.
