# Person A: task guide

You own: **SJF, SRTF, PRIO** (checkpoint 1), **LRU, Clock and the workload
generator** (checkpoint 2), and **experiment 1** (final). You review all of
Person B's work: MLFQ, deadlock detection, the disk schedulers and the
experiment runner.

This guide gives you the approach and the traps, not the code. You write it,
so you can explain it at the demo.

Before you start, read:
- `src/kernel.c`: in particular `kernel_run()`, `dispatch()`,
  `execute_tick()` and the `continuing` logic in `kernel_advance()`
- `include/sched.h`, `include/queue.h`, `include/mem.h`
- FCFS and RR in `src/sched.c`, FIFO in `src/mem.c`: copy their shape

---

## Checkpoint 1

### 1.1 SJF (non-preemptive): branch `sched/sjf`

**Idea:** a ready queue. `pick()` takes the process with the shortest
*next CPU burst*.

**Steps**
1. Copy the FCFS block and rename the functions to `sjf_*`.
2. Write a key function that returns `proc_burst_remaining(p)`.
3. `pick()` uses `q_pop_min(&q, key)`. `should_preempt()` always returns false.
4. Delete the `die()` stub and keep the struct in `all[]`.

**Things to know**
- The key is the current burst, not the whole process
  (`proc_total_remaining`). `arrivals.txt` has processes with two bursts, so
  this changes the result.
- Ties: `q_pop_min` takes the one nearer the head, which is the one that
  became READY first. Say so in your hand check.
- When a burst ends and the next op is `cpu`, the process **keeps the CPU**
  without going through `pick()`. See `continuing` in `kernel_advance()`.
  This affects your Gantt chart.

**Check:** `arrivals.txt --sched sjf --no-paging`. Compute avg_waiting and
avg_response by hand, then add both to `tests/run.sh`.

### 1.2 SRTF: branch `sched/srtf`

**Idea:** SJF plus preemption when a READY process has less left of its burst
than the running one.

**Steps**
1. Same queue and key as SJF (you can share the key function).
2. `should_preempt(r)`: true when `q_min_key(&q, key) < key(r)`.

**Things to know**
- Use `<`, not `<=`. If you preempt on a tie, two equal processes swap
  every tick and the context switches explode.
- `should_preempt` runs *after* the events of the tick, so a process that
  arrives at tick t can preempt at tick t.
- A preempted process goes back through `enqueue` (`kernel_make_ready`).
  That's fine because `pick()` looks at keys, not at order.
- Context switches are counted on every dispatch of a *different* pid.

**Check:** `arrivals.txt --sched srtf --no-paging`: avg_waiting,
avg_response and context_switches by hand.

### 1.3 PRIO: branch `sched/prio`

**Idea:** a smaller `p->priority` runs first. A strictly higher-priority
arrival preempts right away. Processes with the same priority share the CPU
with RR, using `cfg.quantum`.

**Steps**
1. Key = `p->priority`. `pick()` uses `q_pop_min`. Because ties go to the
   head and preempted processes go to the tail, this already gives RR order
   among equal priorities.
2. `on_dispatch` resets `quantum_used`, and `on_tick` increments it (like RR).
3. `should_preempt(r)` is true when
   - a ready process has a **strictly smaller** priority number than `r`, or
   - `r` used its whole quantum **and** a ready process has the **same**
     priority. If nobody of equal or higher priority is ready, reset the
     quantum and let `r` go on (same rule as `rr_should_preempt`).

**Decisions to write in DECISION.md (Q-8)**
- When `r` is preempted by a higher priority, does it get a fresh quantum
  next time? With `on_dispatch` resetting it, yes. Write that down.
- When an equal-priority process arrives, it does **not** preempt. It
  waits for the quantum to end.

**Check:** `arrivals.txt --sched prio --quantum 2 --no-paging` (J1/J4 and
J2/J6 have equal priorities, so the RR part is tested). Draw the Gantt chart.

### 1.6 Hand checks and producer/consumer
- Follow [HAND_CHECKS.md](HAND_CHECKS.md). Save the working in
  `docs/checks/sjf.md`, `srtf.md`, `prio.md`.
- `make test` must show "Producer/consumer completes under sjf/srtf/prio".
- Run `basic.txt` too: SJF on the textbook case should give the textbook
  waiting time (Sec. 5.3.2).

### Report 1 (your part)
For each scheduler: the data structure (one `queue_t`, which key), why
`q_pop_min` is O(n) and whether that matters (MAX_PROCS=64), and how you
checked it. SJF: a short paragraph on exponential averaging (the stub asks
for it).

### What to review in B's work
- **MLFQ:** check that demotion happens only on a *full* quantum, that the
  boost really fires every 20 ticks even when the CPU is idle, and that the
  queue for each level is RR.
- **Deadlock:** redo the `deadlock.txt` detection tick by hand.

---

## Checkpoint 2

### 2.1 LRU: branch `mem/lru`

**Idea:** evict the frame with the smallest `last_used`.

**Steps**
1. Copy FIFO. `victim()` loops over frames with `used && !loading` and
   takes the minimum `last_used`.
2. Read `mem_access()` and `mem_install()` first: they **already** set
   `last_used = now` on every hit and on install. So `on_hit` and
   `on_install` can be empty. Don't update it twice.
3. Remove the `die()` stub and fill in the struct (`&rep_lru` is already
   in `all[]`).

**Check:** `paging_p1.txt --frames 3 --replace lru` → `page_faults=12`
(already in the tests).

### 2.2 Clock (second chance): branch `mem/clock`

**Idea:** a `static int hand` that stays between calls. Look at the frame
under the hand: if `referenced`, clear it and move on; else that's the
victim.

**Steps**
1. `clock_init()` sets `hand = 0`.
2. `victim()`: loop. Skip frames that are `!used || loading`. Stop at the
   first one with `referenced == false`. At most two passes are needed
   (the first clears every bit), and the kernel guarantees at least one
   frame can be evicted.
3. After choosing, move the hand **past** the victim: `(victim + 1) % nframes`.

**Things to know**
- `mem_install()` sets `referenced = true` when a page arrives, and
  `mem_access()` sets it on every hit. So a new page is *not* the next
  victim. Many textbook traces load pages with the bit at 0. Your hand
  computation must follow ossim's rule. Write this in DECISION.md (Q-10).
- Free frames are filled first (`find_free_frame`, lowest index), so the
  victim logic only starts once all frames are full.

**Check (your own, the textbook has none):** write `workloads/clock_check.txt`
with one process and a short `refs=` string (10–12 references, 3 frames)
where Clock gives a **different** count from both FIFO and LRU. That proves
the second chance actually happens. Trace the frames, bits and hand by hand
in `docs/checks/clock.md`, then add the check.

### 2.6 Workload generator: branch `gen/*`

Write `tools/gen.py` (Python 3, standard library only). It prints a
workload file to stdout.

**Options (minimum)**

| Option | Meaning |
|---|---|
| `--procs N` | number of processes |
| `--seed S` | random seed, so every run can be repeated |
| `--arrive-max T` | arrivals spread over 0..T |
| `--burst MIN MAX` | CPU burst length range |
| `--bursts MIN MAX` | number of CPU bursts per process |
| `--io P` | probability that a burst is followed by `io`, and `--io-len MIN MAX` |
| `--pages N` | pages per process |
| `--locality L` | 0..1: chance that the next reference stays in the current small working set |
| `--disk-pattern random\|local` | cylinders for `disk` ops: uniform, or near the previous one |
| `--disk P` | probability of a `disk` op after a burst |

**Limits** (from `include/sim.h`): at most 64 processes, 128 ops per
process, 512 refs per cpu op, 1024 pages. Fail with a clear message instead
of making a file that ossim rejects.

**Checks**
- Same `--seed` gives a byte-identical file.
- The generated file loads and finishes: `./ossim <file> --sched rr`.
- `--locality 1.0` must give far fewer faults than `--locality 0` with the
  same frames. Put that comparison in report 2.

Keep the options stable: B's experiment runner (final) will call it.

### What to review in B's work
- **Disk:** redo SSTF and C-LOOK on the textbook queue (236, 322), and check
  that SCAN's trip to the edge is in `via[]` and counted.

---

## Final

- **Review B's runner:** run it yourself and check one row of its CSV
  against a manual `./ossim` run.
- **Experiment 1:** waiting and response time of the six schedulers as the
  amount of I/O grows. Use your generator (`--io` from 0 to 0.8), B's runner,
  and several seeds per point. Plot avg_waiting and avg_response vs I/O.
- **Theme:** the split will be decided when we choose it (see DECISION.md).
- **Report:** design of the schedulers and memory, validation of your
  checks, experiment 1.
- **Demo rehearsal:** explain MLFQ, deadlock detection and SCAN to B
  without notes.
