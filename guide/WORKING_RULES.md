# Working rules

## 1. Ownership and review

- Every task in [TASKS.md](TASKS.md) has one **owner**. The owner writes
  the code, the hand-computed check and the report section for it.
- The other person is the **reviewer**. A review is not a quick look: the
  reviewer must be able to explain the code at the demo. If you cannot,
  ask questions in the PR until you can.
- Review within **48 hours** of being asked. If you can't, say so in the PR.
- Disagreement: talk it through in the PR. If still stuck, write both options
  in [DECISION.md](../DECISION.md) and ask the TA.

## 2. Definition of done

A task is done when all of these are true:

- [ ] `make` builds with no warnings (`-std=c99 -Wall -Wextra -Werror`)
- [ ] `make test` has no FAIL, and the check for this task is PASS
- [ ] There is a hand-computed check in `tests/run.sh` (see
      [HAND_CHECKS.md](HAND_CHECKS.md)), with the working saved in
      `docs/checks/`
- [ ] Every given workload still finishes (in particular
      `producer_consumer.txt` under every scheduler)
- [ ] The PR is reviewed and merged into `main`
- [ ] Any non-obvious choice is recorded in [DECISION.md](../DECISION.md)

## 3. Code rules

- C99, no external libraries, must build with both `gcc` and `clang`. Do not
  change the flags in the `Makefile`.
- Write in the files listed in the README (`sched.c`, `sync.c`, `mem.c`,
  `disk.c`, `tests/run.sh`, `workloads/`). Changing any other file (e.g.
  `kernel.c`, a header) needs a DECISION.md entry and both of us agreeing
  in the PR.
- Match the style of the given code: same naming (`sjf_pick`, `lru_victim`),
  same struct-of-functions pattern, short comments that explain *why*.
- Do not change output formats that tests grep for (`avg_waiting=`,
  `page_faults=`, `head_movement=`, `DEADLOCK t=<tick> pids: 1 2`, ...).
- The theme must be turned on by a command-line option. Without the option,
  every existing test must give exactly the same output.

## 4. AI tools and outside material

The Guide allows AI tools and online material to understand and to debug,
but **every line we submit must be understood**.

- If an AI tool or a website helped write code, you must be able to explain
  it line by line without the tool. If you can't, don't commit it.
- If outside material (a website, a book, an AI answer) shaped the code,
  note it in the PR description so we can mention it in the report.
- `CLAUDE.md` is a personal file for Claude Code and is in `.gitignore`.
  Each of us keeps our own copy. Ask the other person if you want theirs.

## 5. Communication

- **Weekly sync** (30 min, same day each week): what got merged, what's
  blocked, what's next. Write 3 lines of notes at the bottom of
  [TASKS.md](TASKS.md).
- Use **GitHub Issues** for tasks and bugs, one issue per task in TASKS.md.
  Link the PR to it (`Closes #12`).
- If you are going to miss a deadline, say so **at least 2 days before**.
- Questions about the code go in the PR or the issue, not only in chat, so
  the answer stays findable.

## 6. Checkpoints

- **Code freeze 2 days before every deadline.** After that only fixes go in.
- The day before the deadline, both of us run on a clean clone:
  `git clone ... && make && make test`.
- Tag the commit we submit: `git tag cp1`, `git tag cp2`, `git tag final`,
  then `git push --tags`.

## 7. Report and demo

- Each owner writes the report section for their own parts. The other
  person proofreads it.
- Before the demo, each of us explains the other's half out loud to the
  other. That is the rehearsal for the Q&A.
