# Hand checks

Every policy needs a test whose expected value we computed by hand, not
copied from the simulator. The report has a validation section built from
these.

## Steps

1. **Pick a small workload.** `workloads/arrivals.txt` for schedulers, or a
   new file in `workloads/` with 3–5 processes. Small enough to do on paper.
2. **Compute it by hand** using the rules on page 1–2 of the guide
   (`docs/GroupProject_Guide.pdf`). The ones that trip people up:
   - A burst of N ticks starting at tick t finishes at t + N.
   - Waiting = ticks spent READY. Response = first dispatch − arrival.
   - Events in the same tick are handled in creation order; arrivals first.
     So a new arrival enters the ready queue *before* a process that is
     preempted in that tick.
   - `signal`, `release` and a non-blocking `wait`/`acquire` take no time.
   - RR: if the quantum ends and nobody else is ready, the process keeps
     the CPU. A context switch is counted on every dispatch of a different
     process, including the first.
   - Disk: a request takes ⌈moved/10⌉ + 1 ticks. Page-in cylinder is
     (pid·31 + page·17) mod 200.
   - Use `--no-paging` for scheduler checks.
3. **Write it down** in `docs/checks/<policy>.md`: the workload, the Gantt
   chart or frame table, and the final numbers. This goes into the report.
4. **Ask the other person to redo it** (or at least part of it) before
   looking at the simulator output.
5. **Run the simulator** and compare:
   ```
   ./ossim workloads/arrivals.txt --sched sjf --no-paging --gantt
   ./ossim workloads/arrivals.txt --sched sjf --no-paging --trace | less
   ```
   If they differ, find out which one is wrong. Don't just change the
   expected value to match the output.
6. **Add the check** to the right section of `tests/run.sh`:
   ```
   check "SJF on arrivals.txt: avg waiting X.XX (hand-computed)" \
         "$BIN workloads/arrivals.txt --sched sjf --no-paging" "avg_waiting=X.XX"
   ```
   One `check` per number. Good ones to check: `avg_waiting`,
   `avg_response`, `context_switches`, `page_faults`, `head_movement`.

## Gantt chart format for docs/checks

```
| J1 | J2      | J4 | J1   | ...
0    3         7    9     12
```
