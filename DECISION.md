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
Context: The handout assumes groups of 3–4; we are 2.
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

---

## Open questions

- **Q-1: Deadlock detection method.** Wait-for graph (simpler, one instance
  per resource; enough for `deadlock.txt`) or the multi-instance algorithm of
  Sec. 8.6.2 (more general; needed if we pick theme 7 or 8). Owner: B.
- **Q-2: Recovery after detection.** Only report (print once per deadlock),
  or kill a victim with `kernel_abort()`? Optional for checkpoint 1.
- **Q-3: Tie-breaking in SJF/SRTF/PRIO.** Equal keys: FIFO order of entering
  the ready queue, or lower pid? Must match the hand checks. Owner: A.
- **Q-4: Generator language.** Python is the obvious choice (no build step).
- **Q-5: Theme.** Choose by Week 12, can change until Week 13.
- **Q-6: Checkpoint 1 week.** Handouts say Week 7 and Week 8. Confirm on Canvas.
- **Q-7: Group size.** Confirm with the instructor that a group of 2 is OK.
- **Q-8: PRIO details.** Fresh quantum after being preempted by a higher
  priority? Equal-priority arrival waits for the quantum to end? Owner: A.
- **Q-9: MLFQ details.** Boost at t = 20, 40, …; demote even if nobody else
  is ready; higher-level arrival preempts right away. Owner: B.
- **Q-10: Clock.** A newly installed page has `referenced = true` (set by
  `mem_install`); the hand moves past the victim. Owner: A.
- **Q-11: SSTF ties.** Equal distance: lower index (older request) wins. Owner: B.
