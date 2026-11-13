# Tasks and split

| | Name | GitHub |
|---|---|---|
| **A** | | garan1610 |
| **B** | | TheNameisSea |

Split accepted (DECISION.md D-1). Detailed guides:
[PERSON_A.md](PERSON_A.md) and [PERSON_B.md](PERSON_B.md).

The split gives each of us code in every checkpoint and both halves of the
simulator (CPU side and I/O side), so both of us can answer questions on
everything. Each task is owned by one person and reviewed by the other.

Source: `docs/GroupProject_Guide.pdf` only. Marks: Checkpoint 1 10%,
Checkpoint 2 20%, Final 70% (report, code, presentation and theme).
Fill in the real dates.

## Checkpoint 1: scheduling and deadlock (Week 8, date: ____)

| # | Task | Owner | Reviewer | Branch | Status |
|---|---|---|---|---|---|
| 1.1 | SJF (non-preemptive) in `src/sched.c` | A | B | `MinhBranch` | Implemented and tested; B review pending |
| 1.2 | SRTF in `src/sched.c` | A | B | `MinhBranch` | Implemented and tested; B review pending |
| 1.3 | PRIO: preemptive, RR between equal priorities | A | B | `MinhBranch` | Implemented and tested; B review pending |
| 1.4 | MLFQ: 3 levels, q/2q/4q, demotion, boost every 20 ticks | B | A | `sched/mlfq` | Implemented and tested; A review pending |
| 1.5 | `deadlock_check()` in `src/sync.c` | B | A | `sync/deadlock` | Merged into MinhBranch; A review pending |
| 1.6 | Hand checks on `arrivals.txt` for 1.1–1.3 (+ Gantt) | A | B | `MinhBranch` | Calculations, Gantt charts and tests ready; B review pending |
| 1.7 | Hand checks for MLFQ and deadlock | B | A | with each task | docs/checks/mlfq.md, docs/checks/deadlock.md |
| 1.8 | Progress report 1 (max 2 pages): data structures of the schedulers, how we checked them, who did what | A+B | | `docs/report1` | Person A contribution ready in docs/report1_person_a.md; joint report pending |

Done when: all checkpoint-1 SKIPs in `make test` are PASS, deadlock
detection finds A and B in `deadlock.txt`, and `producer_consumer.txt`
finishes under all six schedulers.

## Checkpoint 2: memory, disk, generator (Week 12, date: ____)

| # | Task | Owner | Reviewer | Branch | Status |
|---|---|---|---|---|---|
| 2.1 | LRU in `src/mem.c` (12 faults on `paging_p1.txt`, 3 frames) | A | B | `mem/lru` | |
| 2.2 | Clock in `src/mem.c` + our own hand-computed Clock case | A | B | `mem/clock` | |
| 2.3 | SSTF in `src/disk.c` (236) | B | A | `disk/sstf` | |
| 2.4 | SCAN with `via[]` (236, `--direction down`) | B | A | `disk/scan` | |
| 2.5 | C-LOOK (322, `--direction up`) | B | A | `disk/clook` | |
| 2.6 | Workload generator: processes, bursts, I/O, page locality, disk patterns | A | B | `gen/*` | |
| 2.7 | Choose theme, write plan (record in DECISION.md) | A+B | | | |
| 2.8 | Progress report 2: the new parts, how we checked them, who did what, the theme and a few lines of plan | A+B | | `docs/report2` | |

Done when: LRU 12 faults, our own Clock case, and disk 640 / 236 / 236 / 322
all PASS. Theme can still change until **Week 13**. A theme of our own must
be agreed with the instructors **before Week 12**.

## Final (Week 15, date: ____)

| # | Task | Owner | Reviewer | Status |
|---|---|---|---|---|
| 3.1 | Experiment runner: sweep options, collect key=value / CSV, plot | B | A | |
| 3.2 | Theme: code behind a command-line option (a run without it behaves as before) | A+B (split when chosen) | | |
| 3.3 | Theme: hand-computed check in `tests/run.sh` | | | |
| 3.4 | Experiment 1 (core): waiting and response time of the six schedulers vs amount of I/O | A | B | |
| 3.5 | Experiment 2 (core): thrashing as frames go down for FIFO, LRU, Clock; Belady for FIFO but not LRU | B | A | |
| 3.6 | Experiment 3 (theme) | A+B | | |
| 3.7 | Report, 8–10 pages: design, checks against hand-computed cases, the 3 experiments | A+B | | |
| 3.8 | 10-minute presentation with a demo (theme included), questions to each member | A+B | | |
| 3.9 | Confidential peer assessment (each) | A, B | | |

Each experiment needs: a question, a method, a plot or table, a discussion.
Other core questions from the Guide, if we have time for a fourth: quantum
vs context switches, response time and page faults; disk schedulers on
random vs local requests and the effect on `avg_fault_service`.

## Weekly notes

<!-- Newest first. Date, what got merged, what is blocked, next steps. -->

