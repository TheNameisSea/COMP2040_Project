# Git workflow

Repository: https://github.com/TheNameisSea/COMP2040_Project (keep it
**private**: code is not shared between groups).

## First-time setup (once)

Repo owner:

1. GitHub → *Settings → Collaborators* → add the teammate.
2. *Settings → Branches → Add branch protection rule* for `main`:
   - Require a pull request before merging, with **1 approval**
   - Do not allow bypassing the above settings
3. *Settings → General → Pull Requests*: allow **merge commits** and
   **rebase merging**, and turn **squash merging off** (see "Merging" below).

Both:

```
git clone https://github.com/TheNameisSea/COMP2040_Project.git
git config user.name  "Your Name"
git config user.email "the-email-on-your-github-account"
```

Commits only count for you if the email matches your GitHub account.

## Daily loop

```
git switch main
git pull                              # start from the latest main
git switch -c sched/sjf               # one branch per task
# ... edit, make, make test ...
git add src/sched.c tests/run.sh
git commit -m "sched: add SJF (non-preemptive)"
git push -u origin sched/sjf          # then open a PR on GitHub
```

While the PR is open, keep committing to the same branch and pushing. If
`main` has moved on, update your branch:

```
git fetch origin
git rebase origin/main                # or: git merge origin/main
git push --force-with-lease           # only after a rebase, only on YOUR branch
```

Never force-push `main` or the other person's branch.

## Branch names

`<area>/<short-name>`, with area one of:
`sched`, `sync`, `mem`, `disk`, `gen`, `theme`, `test`, `exp`, `docs`, `fix`.

Examples: `sched/mlfq`, `sync/deadlock`, `disk/scan`, `gen/locality`,
`fix/rr-quantum`.

## Commit messages

```
<area>: <what, in the imperative>      (max ~60 chars)

<optional: why, and anything the reviewer should know>
```

Examples:

```
sched: add SRTF with preemption on shorter burst
test: hand-computed SJF check on arrivals.txt
mem: fix Clock hand skipping loading frames
```

Commit **small and often**: one working step per commit, not one huge
commit per checkpoint. Each commit should build.

## Pull requests

PR description template:

```
## What
SJF (non-preemptive) in src/sched.c.

## How I checked it
Hand-computed arrivals.txt: avg_waiting=..., Gantt in docs/checks/sjf.md.
New check in tests/run.sh passes.

## For the reviewer
Ties are broken by ... (DECISION.md D-7).

Closes #3
```

Reviewer checklist:

- [ ] I pulled the branch and ran `make && make test` myself
- [ ] I redid at least part of the hand computation
- [ ] I can explain every function in the diff
- [ ] Nothing outside the agreed files changed without a DECISION.md entry

## Merging

- The **author** merges after approval (so the author does the last check).
- Use **"Create a merge commit"** or **"Rebase and merge"**, not squash.
  Squashing turns a week of small commits into one, and the history is
  how the course sees who did what.
- Delete the branch after merging.

## Never commit

Build output (`build/`, `ossim`, `*.o`), CSV outputs, `.DS_Store`, and
`CLAUDE.md`. These are in `.gitignore`. Check `git status` before
`git add`, and prefer `git add <file>` over `git add .`.
