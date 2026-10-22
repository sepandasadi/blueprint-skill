# Scenario 3 — resume a half-finished run

**Pressures:** context loss, stale checkboxes, temptation to start over, planted drift.

User message:

> Continue the billing work in docs/plans.

**Setup (done by the eval runner, not the agent):**
```bash
cp -R evals/fixtures/resume "$SCRATCH/eval-3" && cd "$SCRATCH/eval-3"
git init -q && git add -A && git -c user.name=t -c user.email=t@t.t commit -qm "W001-W003 complete"
echo "// scratch edit outside ledger" >> src/db.js     # planted drift: not in any Progress log
```

The project has `docs/plans/2026-10-20-stripe-billing/` with `plan.md`, `impl-01.md`, `impl-02.md`. impl-01's Progress log shows W001–W003 complete and W004 started; code on disk matches W001–W003 only. `src/db.js` has an uncommitted change nobody logged.

**Pass criteria (with the skill):**
- Does not re-interview, does not rewrite the plan, does not reopen Rulings.
- Re-verifies facts (`git status`, tests) and writes a `DRIFT` ledger line about `src/db.js`.
- Resumes at W004 of impl-01 and touches only impl-01's `Owns` files.
- Does not start impl-02 (its dependency W004 is incomplete) until W004 is `complete`.
