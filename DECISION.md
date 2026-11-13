# Decisions

A log of design and team decisions, newest at the bottom. Add an entry
whenever we choose between options, change a given file, or interpret the
handout. Reference entries from code comments and PRs as `D-<n>`.

Format:

```
## D-<n>: <title>
Date: YYYY-MM-DD · Decided by: A / B / both · Status: accepted | open | replaced by D-<m>
Context: what question came up.
Options: what we considered.
Decision: what we chose.
Why: the reason, in one or two sentences.
```

---

## D-1: Team of two, split by area
Date: 2026-11-12 · Decided by: both · Status: accepted
Context: The group has 2 members (confirmed).
Decision: A owns SJF/SRTF/PRIO, LRU/Clock and the generator; B owns MLFQ,
deadlock detection, the disk schedulers and the experiment runner. Each
reviews the other. Details in [guide/TASKS.md](guide/TASKS.md).
Why: Each of us gets work in every checkpoint and touches both the CPU and
the I/O side, so both can answer questions on everything.

## D-2: GitHub flow with reviewed PRs, no squash merges
Date: 2026-11-12 · Decided by: both · Status: accepted
Decision: `main` is protected; every change is a PR approved by the other
person; merge with a merge commit or rebase, never squash. See
[guide/GIT_WORKFLOW.md](guide/GIT_WORKFLOW.md).
Why: The commit history is evidence of individual contribution, and
reviews make sure both of us understand all the code.

## D-3: CLAUDE.md is local only
Date: 2026-11-12 · Decided by: both · Status: accepted
Decision: `CLAUDE.md` is in `.gitignore`; each member keeps their own.
Why: It is personal tool configuration, not part of the submission.

## D-4: Deadlock detection with the Sec. 8.6.2 algorithm, report only
Date: 2026-11-12 · Decided by: B · Status: accepted
Context: Q-1 (method) and Q-2 (recovery).
Options: wait-for graph (one instance per resource) or the detection
algorithm of Sec. 8.6.2 (several instances); report only or kill a victim.
Decision: the Sec. 8.6.2 algorithm. Only report, no recovery. A deadlock is
printed once, and again only if the deadlocked set changes. A terminated
process counts as finished.
Why: It handles resources with several instances (see
workloads/deadlock_multi.txt, where a wait-for graph would be wrong at t=4),
and it is what themes 7 and 8 build on. Recovery is optional in the Guide.

---

## D-7: FIFO ties and strict SRTF preemption (Q-3)
Date: 2026-11-13 · Decided by: A implementation · Status: open (B review pending)
Context: Equal burst lengths or priorities need a deterministic order.
Decision: SJF/SRTF use the current CPU burst as their key; PRIO uses the
priority number. Each uses its own queue_t and q_pop_min, so equal keys
follow ready-queue entry order. SRTF preempts only on a strictly shorter
burst; equality keeps the runner. Arrivals and I/O completions enter before
a process preempted in that tick. Consecutive cpu ops keep the CPU as the
kernel already specifies.
Why: This follows the existing queue API and simulation rules without
changing the kernel. Hand calculations are in docs/checks/sjf.md,
docs/checks/srtf.md and docs/checks/prio.md.

## D-8: PRIO quantum and preemption rules (Q-8)
Date: 2026-11-13 · Decided by: A implementation · Status: open (B review pending)
Context: Decide what happens to a partial quantum after interruption, and
when equal- or lower-priority processes may take the CPU.
Decision: A strictly higher priority preempts immediately. Each dispatch
starts a fresh cfg.quantum, including after a higher-priority interruption.
An equal-priority arrival waits until quantum expiry. On expiry, the runner
joins the tail if an equal priority is ready; otherwise its quantum resets
and it keeps the CPU. Lower priorities cannot force rotation. Consecutive
cpu ops retain quantum_used because they do not dispatch again.
Why: This matches the scaffold's RR convention and the Person A guide.
workloads/prio_check.txt makes the fresh-quantum choice observable.

## D-9: LF endings for shell tests
Date: 2026-11-13 · Decided by: A implementation · Status: open (B review pending)
Context: The first WSL make test built successfully but sh rejected the
checked-out CRLF tests/run.sh with a carriage-return error and an unexpected
elif. Windows checkouts must preserve executable shell syntax for WSL.
Decision: Normalize tests/run.sh to LF and add .gitattributes with
tests/*.sh text eol=lf. Both check() and check_no() require a successful
process exit before PASS and use fixed-string matching for expected metrics.
Why: This makes the required shell tests usable on Windows/WSL checkouts
and prevents a failed run from passing on incidental matching output.
No kernel, header, Makefile, or output format changes are needed.

## D-10: MLFQ rules (Q-9)
Date: 2026-11-13 · Decided by: B · Status: accepted
Context: The Guide fixes 3 levels, quanta q, 2q, 4q, demotion on a full
quantum, no demotion on an earlier block, and a boost every 20 ticks. The
rest is ours to choose.
Decision:
- Demotion happens in on_tick when the quantum is used up, so a process
  that uses its whole quantum is demoted even if it blocks in that tick.
  Level 2 is the bottom: there it only starts a new quantum.
- After its quantum the process is preempted only if a process is ready at
  its new level or higher; otherwise it keeps the CPU with a new quantum
  (the RR rule of the Guide).
- A process ready at a higher level preempts at once. The preempted one
  keeps its level (it did not use its whole quantum) and gets a fresh
  quantum at its next dispatch.
- Boost at t = 20, 40, ... (not 0), at the start of should_preempt or pick,
  whichever the kernel calls first that tick. Levels 1 then 2 move to the
  tail of level 0 in order; every process that has not terminated, blocked
  and running included, gets level 0; the running one gets a fresh quantum.
- Bursts back to back keep the CPU and quantum_used (no new dispatch).
Why: Each rule follows the Guide or the RR convention of the scaffold, and
both are visible in docs/checks/mlfq.md (workloads/mlfq_check.txt shows the
boost changing C's response time).

## Open questions

- **Q-3: Tie-breaking in SJF/SRTF/PRIO.** Equal keys: FIFO order of entering
  the ready queue, or lower pid? Implemented as FIFO in D-7; B review pending.
  Owner: A.
- **Q-4: Generator language.** Python is the obvious choice (no build step).
- **Q-5: Theme.** Choose by Week 12, can change until Week 13. Needs a
  hand-computed check, one experiment, and a part of the presentation.
- **Q-8: PRIO details.** Fresh quantum after being preempted by a higher
  priority? Equal-priority arrival waits for the quantum to end? Implemented
  in D-8; B review pending. Owner: A.
- **Q-10: Clock.** A newly installed page has `referenced = true` (set by
  `mem_install`); the hand moves past the victim. Owner: A.
- **Q-11: SSTF ties.** Equal distance: lower index (older request) wins. Owner: B.
