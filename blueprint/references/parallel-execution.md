# Splitting, dispatch, commits, convergence and resume

Covers Phase 5 (split), Phase 7 (implement) and the Resume procedure.

## Contents
- Splitting rules
- Pre-flight conflict table
- Dispatch
- Commit policy
- After all plans report
- Resume procedure
- Task tracking without a todo tool

## Splitting rules

- Partition by **file ownership**: every file or glob the feature touches belongs to exactly one `impl-NN.md › Owns`. If two plans need the same file, either merge them or move the shared piece into the plan that runs first and freeze its interface.
- Count: advanced 2–4 plans; simple 1–2. A feature too small to split gets one plan, and you say so at Gate 1.
- Order plans by dependency; `Depends on` lists the exact `impl-NN W###` that must be `complete` first. No cycles.
- Each plan must be independently verifiable: its `Verification` block passes on its own files plus already-complete dependencies.
- Good seams: data layer vs API vs UI vs integration adapter; or one user journey per plan when they share nothing.
- Shared test helpers, types and migrations go to the earliest plan that needs them.
- **Every file any task mentions is in some plan's Owns — including docs.** README, CHANGELOG, API docs and config files that several plans document go to the last plan in dependency order, and earlier plans list their doc changes as tasks for that plan. The Phase 6 ownership check fails on any path a task names that no plan owns.

## Pre-flight conflict table

Before any dispatch, fill `plan.md › Pre-flight conflict table`: one row per interface or file that more than one plan touches or consumes, naming the plans and the frozen contract (signature, schema, route shape). A contract may change later only by a `Ruling:` in `plan.md` and a ledger line in every affected plan. An empty table is fine and must be stated as such.

## Dispatch

Pick one path from the harness detection in `harness-map.md`:

**Concurrent subagents available.** Dispatch one implementer per plan whose dependencies are all complete, all in one message so they start together. The brief is small and complete:

```
You are implementer-NN. Read <path>/impl-NN.md and only the files it lists under Owns, Depends on and Interfaces.
Rules: follow the tasks in order, test first; append a ledger line to Progress log after every task
(format in <path>/impl-NN.md); never edit files outside Owns; never commit; if blocked, write a BLOCKED
line and stop. Finish with a DONE or DONE_WITH_CONCERNS line and the output of the Verification block.
Report back: status, ledger tail, verification output.
```

Model tier: standard for implementers, most capable for reviewers (how to set it is in `harness-map.md`). Wait in bounded stretches; when one reports, dispatch any plan it unblocked.

**Sequential subagents only.** Same brief, one plan at a time in dependency order.

**No subagents.** You are every implementer in turn. Keep the same ledger discipline and the same `Owns` boundaries; announce `Acting as implementer-NN` when you switch plans.

## Commit policy

- Implementers never commit (they say so in their brief). The orchestrator commits.
- After a plan reports: (1) run the multi-touched-file check — `git status --porcelain` paths must all fall inside that plan's `Owns`, otherwise record a `DRIFT` line and resolve before committing; (2) run the plan's Verification block; (3) commit only that plan's files with the user's git identity, message `feat(<slug>): impl-NN <scope title>` plus a body listing the W-tasks. Nothing is pushed.
- Worktree mode (only if the harness offers worktrees and the user chose it at Gate 2): each implementer works on its own branch and may commit there; the orchestrator merges in dependency order and runs the checks on the merged tree.

## After all plans report

1. Full test suite and every plan's Verification block on the integrated tree.
2. Convergence pass (`review-checklists.md › Convergence pass`), appended to `plan.md`. Loop fixes through the owning plan (re-dispatch or do it yourself), at most 3 passes.
3. Final report to the user: per-requirement grade (answered / partial / unresolved), every `Ruling:` verbatim, commits made, test output, anything `DONE_WITH_CONCERNS`.

## Status report

Read-only: no edits, no ledger line, no git or test commands. Folders: the one named, else every folder in `docs/plans/` whose `plan.md` status is not `converged`, newest first. For each, at most 8 lines:

```
docs/plans/2026-10-20-stripe-billing — advanced · implementing
Gates: 1 approved 2026-10-20 · 2 approved 2026-10-21
impl-01 done (W001–W004) · impl-02 in progress, next W012 · impl-03 waiting on impl-02 W013
Open: 1 BLOCKED (W013), 0 DRIFT, 0 DONE_WITH_CONCERNS
Next: say "continue" to resume at impl-02 W012
```

Phase: `plan.md` status `draft` → interview (count the `Q → A` lines per track: `requirements done, design 3 of ~10`) or validation; `validated` → planning and plan review (cycles in the Review log); `reviewed` → waiting at Gate 1; `approved` → split and deep review, then Gate 2; `implementing` → building; `converged` → done. Where the status lags, the files decide: `impl-NN.md` files mean the split happened, a `START` line means building began. Gate dates come from the `Gate N approved` lines in the Review log; plans written before those lines existed have none, so say `date not recorded` rather than guessing. The `Next:` line names what the user types: the answer to a pending gate question, or `continue`. Say that the report reflects the files, not a fresh check; `continue` re-verifies.

## Resume procedure

Triggered when the artifact folder already exists or the user says to continue. Pick the folder first (SKILL.md › Resume step 0).
1. Read `plan.md` status and every `impl-NN.md` Progress log. **Trust the decisions** (Rulings, confirmed entries); do not reopen them. Write a `RESUME` line naming the task you will resume at.
2. **Re-verify facts:** `git status`, `git log` since the last ledger timestamp, run each in-progress plan's Verification block. If the runner cannot run, say why in the `RESUME` line and use `complete (unverified: …)` for tasks you finish.
3. Record a `DRIFT` line for each of:
   - a file changed on disk that no ledger line explains;
   - a ledger claim with no matching change on disk (e.g. "writing failing test" but no test exists) — restart that task step;
   - a test that passed per the ledger and now fails.
   A commit whose content matches existing ledger lines is not drift; mention it in the `RESUME` line.
4. **Who resolves drift:** drift inside your plan's Owns — fix it as part of the task, noted in the ledger. Drift in another plan's Owns or in a file no plan owns — never revert or edit it; leave it, list it in the report, and the orchestrator asks the user before any commit includes that file.
5. **Unowned file needed by your task:** if a task must edit a file no plan owns, add it to your plan's Owns with a `Ruling:` line. If another plan owns it, write `BLOCKED` instead.
6. Continue from the first task not `complete` in the first plan whose dependencies are complete. Never touch another plan's `Owns`.
7. If `plan.md` status is before `approved`, resume the phase it stopped in; the gates still apply.

## Task tracking without a todo tool

Where the harness has no task list, the impl plans are the task list: tick `- [ ]` → `- [x]` in `plan.md › Tasks` when the ledger shows `complete`, and keep a short `## Now` line at the top of `plan.md` naming the current plan and task. Re-read it before each step once the conversation gets long.
