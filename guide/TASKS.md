# Tasks and split

| | Name | GitHub |
|---|---|---|
| **A** | | TheNameisSea |
| **B** | | |

Split accepted (DECISION.md D-1). Detailed guides:
[PERSON_A.md](PERSON_A.md) and [PERSON_B.md](PERSON_B.md).

The split gives each of us code in every checkpoint and both halves of the
simulator (CPU side and I/O side), so both of us can answer questions on
everything. Each task is owned by one person and reviewed by the other.

Fill in the real dates from Canvas. Note: one handout says Checkpoint 1 is
Week 8, the other says Week 7. Check which one applies.

## Checkpoint 1: scheduling and deadlock (Week 7/8, date: ____)

| # | Task | Owner | Reviewer | Branch | Status |
|---|---|---|---|---|---|
| 1.1 | SJF (non-preemptive) in `src/sched.c` | A | B | `sched/sjf` | |
| 1.2 | SRTF in `src/sched.c` | A | B | `sched/srtf` | |
| 1.3 | PRIO: preemptive, RR between equal priorities | A | B | `sched/prio` | |
| 1.4 | MLFQ: 3 levels, q/2q/4q, demotion, boost every 20 ticks | B | A | `sched/mlfq` | |
| 1.5 | `deadlock_check()` in `src/sync.c` | B | A | `sync/deadlock` | |
| 1.6 | Hand checks on `arrivals.txt` for 1.1–1.3 (+ Gantt) | A | B | with each task | |
| 1.7 | Hand checks for MLFQ and deadlock | B | A | with each task | |
| 1.8 | Progress report 1 (max 2 pages): data structures, checks, who did what | A+B | | `docs/report1` | |

Done when: all checkpoint-1 SKIPs in `make test` are PASS, and
`producer_consumer.txt` finishes under all six schedulers.

## Checkpoint 2: memory, disk, generator (Week 12, date: ____)

| # | Task | Owner | Reviewer | Branch | Status |
|---|---|---|---|---|---|
| 2.1 | LRU in `src/mem.c` (12 faults on `paging_p1.txt`, 3 frames) | A | B | `mem/lru` | |
| 2.2 | Clock in `src/mem.c` + our own hand-computed Clock case | A | B | `mem/clock` | |
| 2.3 | SSTF in `src/disk.c` (236) | B | A | `disk/sstf` | |
| 2.4 | SCAN with `via[]` (236, `--direction down`) | B | A | `disk/scan` | |
| 2.5 | C-LOOK (322, `--direction up`) | B | A | `disk/clook` | |
| 2.6 | Workload generator: processes, bursts, I/O, page locality, disk patterns | A | B | `gen/*` | |
| 2.7 | Experiment runner: sweep options, collect key=value / CSV, plot | B | A | `exp/runner` | |
| 2.8 | Choose theme, write plan (record in DECISION.md) | A+B | | | |
| 2.9 | Progress report 2 | A+B | | `docs/report2` | |

## Final (Week 15, date: ____)

| # | Task | Owner | Reviewer | Status |
|---|---|---|---|---|
| 3.1 | Theme: code behind a command-line option | A+B (split when chosen) | | |
| 3.2 | Theme: hand-computed check in `tests/run.sh` | | | |
| 3.3 | Experiment 1 (core), e.g. schedulers vs amount of I/O | A | B | |
| 3.4 | Experiment 2 (core), e.g. frames vs faults, Belady, thrashing | B | A | |
| 3.5 | Experiment 3 (theme) | A+B | | |
| 3.6 | Report, 8–10 pages: design, validation, 3 experiments | A+B | | |
| 3.7 | 10-minute demo script, rehearsal (each explains the other's half) | A+B | | |
| 3.8 | Peer assessment (each, confidential) | A, B | | |

Each experiment needs: a question, a method, a plot or table, a discussion.

## Weekly notes

<!-- Newest first. Date, what got merged, what is blocked, next steps. -->

