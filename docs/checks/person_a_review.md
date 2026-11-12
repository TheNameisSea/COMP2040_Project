# Checkpoint 1: Person A review notes

These are Codex-assisted technical checks, not a substitute for the
teammate's PR approval required by the team workflow.

## Person A deliverables

- SJF, SRTF and PRIO are implemented in `src/sched.c`.
- Each has hand-derived Gantt charts and per-process results in this
  directory, with matching waiting, response, turnaround and switch checks
  in `tests/run.sh`.
- SJF's textbook case and producer/consumer under each new scheduler pass.
- Regression workloads cover FIFO ties, consecutive CPU operations and
  the fresh PRIO quantum after higher-priority preemption.
- `../report1_person_a.md` explains each queue/key, O(n) selection,
  exponential averaging, validation, limitations and contributions.
- D-7/D-8 record tie and quantum choices; D-9 records shell-test changes.

## Review of available Person B work

For `deadlock.txt` with RR quantum 2, the CPU order is A `[0,2)`,
C `[2,4)`, B `[4,6)`, A `[6,8)`, C `[8,10)`, B `[10,12)`,
A `[12,13)`, C `[13,15)`. B requests R1 at the end of tick 11 and A
requests R2 at the end of tick 12. At checks 5 and 10 there is no cycle;
the first five-tick check after both block is 15. The expected report is
`DEADLOCK t=15 pids: 1 2`.

For `deadlock_multi.txt` at the end of tick 4, Available is 0. A holds 1
and requests 1; B holds 1 and currently requests 0. The reduction can mark
B finished, add its allocation to Work (now 1), then satisfy A and mark
it finished (Work becomes 2). Thus A being blocked is not enough to report
a deadlock. This is a hypothetical reduction: B actually makes a further
request at the end of tick 5, and both processes are reported at tick 6.

Semaphore waits do not populate resource requests. A semaphore-blocked
process is therefore considered able to finish by this resource-only
detector. It does not detect semaphore-only or all mixed deadlocks; the
limitation is documented in the implementation and Person B guide.

The review found that `check_no` discarded command failures with
`|| true`, allowing an invalid workload or a crashed simulator to pass a
negative test. It now requires exit status zero, retains unimplemented
policy SKIPs, and matches literal text. A positive `finished=2/2` check
also verifies completion of the non-deadlocking multi-instance workload.
The helper was checked against a missing workload, forbidden output, a
successful negative case, and an unimplemented policy. All four outcomes
matched the expected FAIL/FAIL/PASS/SKIP behavior. The full suite now
reports 54 PASS, 5 SKIP and 0 FAIL, with 30 additional completion checks.

## Remaining work before the joint submission

- Person B reviews the three schedulers and redoes part of their hand
  calculations, then the PR can be merged according to the team workflow.
- Review Person B's MLFQ demotion, per-level RR and idle-time boost when
  that implementation is available; it is still a stub in this checkout.
- Combine both report contributions into the final report of at most two
  pages, with the terminal evidence, member contributions and limitations.
- Verify the Clang build where Clang is installed. The local WSL
  environment currently provides GCC only.
- Before submission, both members run the clean-clone check described in
  `guide/WORKING_RULES.md` and can explain each submitted change.
