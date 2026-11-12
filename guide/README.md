# Team guide

How the two of us work on ossim. Read this once, then use it as a reference.

| File | What is in it |
|---|---|
| [WORKING_RULES.md](WORKING_RULES.md) | The rules we agreed on: ownership, reviews, AI use, definition of done |
| [GIT_WORKFLOW.md](GIT_WORKFLOW.md) | Branches, commits, pull requests, merging, first-time setup |
| [TASKS.md](TASKS.md) | Who does what, per checkpoint, with deadlines |
| [PERSON_A.md](PERSON_A.md) | Step-by-step guide for A: SJF, SRTF, PRIO, LRU, Clock, generator |
| [PERSON_B.md](PERSON_B.md) | Step-by-step guide for B: MLFQ, deadlock, SSTF, SCAN, C-LOOK, runner |
| [HAND_CHECKS.md](HAND_CHECKS.md) | How to compute a result by hand and turn it into a test |
| [../DECISION.md](../DECISION.md) | Every design decision we made and why |

The project handout is in [../docs/](../docs/), the code overview in
[../README.md](../README.md).

## Quick start

```
git clone https://github.com/TheNameisSea/COMP2040_Project.git
cd COMP2040_Project
make && make test          # 9 PASS, 9 SKIP at the start
./ossim --help
```

Then read `src/kernel.c` (the tick loop) and the header of the file you are
going to work in. The headers in `include/` explain each interface.

## The three things that matter most

1. **Nobody pushes to `main`.** Everything goes through a pull request that
   the other person reviews.
2. **Both of us must be able to explain every line.** At the demo, any of
   us can be asked about any part. Reviews are how we learn the other half.
3. **Commit your own work from your own account, often.** The commit history
   is part of the mark (±20% per person).
